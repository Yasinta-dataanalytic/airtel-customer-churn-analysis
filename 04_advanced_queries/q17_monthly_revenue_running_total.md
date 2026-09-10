-- ============================================================
-- Q17: MONTHLY REVENUE RUNNING TOTAL
-- Business question: How is cumulative revenue building month over month?
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

monthly_agg AS (
  SELECT
    DATE_TRUNC(payment_date, MONTH) AS revenue_month,
    SUM(amount) AS monthly_revenue
  FROM clean_payments
  WHERE amount IS NOT NULL AND payment_date IS NOT NULL
  GROUP BY revenue_month
)

SELECT
  revenue_month,
  monthly_revenue,
  SUM(monthly_revenue) OVER (ORDER BY revenue_month ROWS UNBOUNDED PRECEDING) AS running_total_revenue
FROM monthly_agg
ORDER BY revenue_month;
```

## results
<img width="766" height="601" alt="Screenshot 2026-09-10 105238" src="https://github.com/user-attachments/assets/94e40e32-24d4-474f-aebb-a58835358394" />

## insight
Cumulative revenue reached approximately TZS 63.86M by the end of the observed period. Month-to-month amounts fluctuate between roughly TZS 1.4M and 2.95M with no clear upward trend — consistent with the flat revenue pattern already identified in Q8 and Q19.

More importantly, the running total reveals a data quality issue at the tail end: September 2026 is missing entirely, while October and December 2026 each show only TZS 35,000 — a single payment record, far below every other month's total (which average ~TZS 2M). Since August 2026 was the latest month with a full, consistent volume of payments, these two trailing months likely reflect incomplete or mis-dated data rather than an actual revenue collapse. This lines up with the same "future-dated" or malformed date anomalies already flagged in Q9 and Q14 (negative days), suggesting the date-parsing issue in the raw payments table is systemic rather than isolated to one question.
## Bussiness recomendation
Treat August 2026 as the last reliable month of complete data, and exclude or clearly footnote September–December 2026 in any revenue trend chart or dashboard — reporting them at face value would visually (and incorrectly) suggest a sudden 98%+ revenue crash. Before this project is finalized, it's worth tracing these specific payment records (the ones landing in Oct/Dec 2026) back to the raw payments table to confirm whether they're genuine late entries, testing artifacts, or a date-parsing failure — the same root-cause investigation that would also help explain the negative-day anomalies from Q9 and Q14.

