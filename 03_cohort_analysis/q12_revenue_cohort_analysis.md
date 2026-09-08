# Q12: Cohort Revenue Analysis

**Business Question:** Which signup cohort generates the most revenue over time — are newer customers more or less valuable than older ones?

## SQL Query

```sql
WITH clean_payments AS (
  SELECT * EXCEPT(row_num) FROM (
    SELECT
      customer_id,
      amount,
      COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', payment_date),
        SAFE.PARSE_DATE('%d/%m/%Y', payment_date),
        SAFE.PARSE_DATE('%m/%d/%Y', payment_date),
        SAFE.PARSE_DATE('%d-%b-%Y', payment_date),
        SAFE.PARSE_DATE('%B %d, %Y', payment_date)
      ) AS payment_date,
      ROW_NUMBER() OVER (
        PARTITION BY payment_id, customer_id, subscription_id, payment_date, CAST(amount AS STRING), payment_method
        ORDER BY payment_id
      ) AS row_num
    FROM `airtel-churn-analysis.churn_analysis.payments`
  )
  WHERE row_num = 1
),
customer_cohort AS (
  SELECT
    customer_id,
    signup_date,
    DATE_TRUNC(signup_date, MONTH) AS cohort_month
  FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
  WHERE signup_date IS NOT NULL
  GROUP BY customer_id, signup_date
),
customer_revenue AS (
  SELECT
    cc.customer_id,
    cc.cohort_month,
    SUM(CASE WHEN cp.payment_date <= DATE_ADD(cc.signup_date, INTERVAL 1 MONTH) THEN cp.amount ELSE 0 END) AS revenue_1m,
    SUM(CASE WHEN cp.payment_date <= DATE_ADD(cc.signup_date, INTERVAL 3 MONTH) THEN cp.amount ELSE 0 END) AS revenue_3m,
    SUM(CASE WHEN cp.payment_date <= DATE_ADD(cc.signup_date, INTERVAL 6 MONTH) THEN cp.amount ELSE 0 END) AS revenue_6m
  FROM customer_cohort cc
  LEFT JOIN clean_payments cp
    ON cp.customer_id = cc.customer_id
    AND cp.amount IS NOT NULL
    AND cp.payment_date IS NOT NULL
  GROUP BY cc.customer_id, cc.cohort_month
)
SELECT
  cohort_month,
  COUNT(*) AS cohort_size,
  ROUND(AVG(revenue_1m), 0) AS avg_revenue_per_customer_1m,
  ROUND(AVG(revenue_3m), 0) AS avg_revenue_per_customer_3m,
  ROUND(AVG(revenue_6m), 0) AS avg_revenue_per_customer_6m
FROM customer_revenue
GROUP BY cohort_month
ORDER BY cohort_month
LIMIT 15;
```

## Results

<img width="1920" height="1080" alt="Screenshot (241)" src="https://github.com/user-attachments/assets/c8202f88-6116-414a-a13a-1c57583a2a83" />


## Insight
Newer cohorts are dramatically more valuable than older ones. Customers who 
signed up in early 2024 generated roughly TZS 20,000–31,000 in their first month, 
while cohorts from mid-2025 onward generated TZS 75,000–177,500 in the same 
window — up to 5-6x higher. This upward trend holds consistently at the 1, 3, 
and 6-month marks, not just as a one-time spike, meaning newer customers aren't 
just paying more once — they're sustaining higher spend over time. This likely 
reflects a shift in plan mix (more customers choosing Premium/Standard over 
Basic) or a pricing change, rather than random variation, given how consistent 
and large the increase is.


## Business Recommendation
Investigate what changed in customer acquisition or pricing starting around 
early-to-mid 2025 — whether it's a shift in marketing channel, a change in the 
default plan offered at signup, or a price increase — and treat it as a success 
worth replicating, not just an interesting trend. Since newer cohorts are both 
higher-value AND (per Q11) showing somewhat lower retention, the priority should 
be retaining these high-value newer customers specifically, since losing them 
costs more in lost revenue than losing an early, lower-spending customer.
