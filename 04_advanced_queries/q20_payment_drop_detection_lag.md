-- ============================================================
-- Q20: PAYMENT DROP DETECTION (LAG per customer)
-- Business question: Which customers have gone unusually long since
-- their last payment, relative to their own payment history?
-- ============================================================
```sql
WITH clean_payments AS (
  SELECT * EXCEPT(row_num) FROM (
    SELECT
      payment_id,
      customer_id,
      subscription_id,
      COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', payment_date),
        SAFE.PARSE_DATE('%d/%m/%Y', payment_date),
        SAFE.PARSE_DATE('%m/%d/%Y', payment_date),
        SAFE.PARSE_DATE('%d-%b-%Y', payment_date),
        SAFE.PARSE_DATE('%B %d, %Y', payment_date)
      ) AS payment_date,
      amount,
      ROW_NUMBER() OVER (
        PARTITION BY payment_id, customer_id, subscription_id, payment_date, CAST(amount AS STRING)
        ORDER BY payment_id
      ) AS row_num
    FROM `airtel-churn-analysis.churn_analysis.payments`
  )
  WHERE row_num = 1
),

payment_gaps AS (
  SELECT
    customer_id,
    payment_id,
    payment_date,
    LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date) AS prev_payment_date,
    DATE_DIFF(
      payment_date,
      LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date),
      DAY
    ) AS days_since_prev_payment
  FROM clean_payments
  WHERE amount IS NOT NULL AND payment_date IS NOT NULL
)

SELECT *
FROM payment_gaps
WHERE days_since_prev_payment > 45  -- flag gaps well beyond a normal ~30-day billing cycle
ORDER BY days_since_prev_payment DESC;
```

##Result

<img width="851" height="555" alt="Screenshot 2026-09-10 161543" src="https://github.com/user-attachments/assets/c7c35d21-0ab0-42f3-99f9-205078cfef97" />

##insight

Sorted by largest gap first, the top results show payment intervals of 500 to 836 days between a customer's consecutive payments — not weeks or months, but well over a year in many cases (CUST1294: 836 days, CUST1283: 760 days, CUST1020: 737 days). Given that Airtel's subscription model implies a roughly monthly billing cycle, gaps of this size are far too large to represent normal payment behavior.

When I traced individual customers earlier (before this screenshot), I found that many of them only have 2-3 total payment records across 2+ years of an active subscription — not the 20-30 monthly payments you'd expect. This strongly suggests the payments table is a partial/sampled record of transactions, not a complete billing ledger — the underlying subscriptions likely continued monthly, but only some payments were captured in this dataset. Across the full table, roughly 77% of all payments showed a gap over 45 days from the customer's previous payment, which is far too widespread to be individual "missed payment" behavior — it's a dataset characteristic.

##Bussiness recomendation
This finding should be reported as a data completeness limitation, not as "customers frequently stop paying and resume later" — the data doesn't support that stronger claim, and overstating it would be misleading in a portfolio or business context. The honest framing is: "The payments table appears to capture a sample of transactions rather than the full billing history; consecutive-payment gaps in this table should not be used on their own to infer customer payment behavior or churn risk." If this were a real production project, the next step would be to confirm with Airtel's billing system owner whether payments is meant to be a complete ledger or an extract — that answer would determine whether Q20's LAG logic is even a valid churn-risk signal, or whether it should be dropped from the at-risk model in Q16 rather than expanded on.


