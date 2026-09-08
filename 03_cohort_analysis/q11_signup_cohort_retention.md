# Q11: Signup Cohort Retention Table

**Business Question:** Of customers who signed up in a given month, what percentage are still active after 1, 3, and 6 months?

## SQL Query

**Note:** A customer can have more than one subscription (e.g. two routers). This 
query rolls up to customer level: a customer is counted "retained" at month N if 
they have at least one still-Active subscription, or their most recent cancellation 
happened on/after N months from their signup date.

```sql
WITH customer_cohort AS (
  SELECT
    customer_id,
    signup_date,
    DATE_TRUNC(signup_date, MONTH) AS cohort_month,
    MAX(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS is_currently_active,
    MAX(end_date) AS last_cancel_date
  FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
  WHERE signup_date IS NOT NULL
  GROUP BY customer_id, signup_date
),
retention AS (
  SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    COUNTIF(
      is_currently_active = 1 OR last_cancel_date >= DATE_ADD(signup_date, INTERVAL 1 MONTH)
    ) AS retained_1m,
    COUNTIF(
      is_currently_active = 1 OR last_cancel_date >= DATE_ADD(signup_date, INTERVAL 3 MONTH)
    ) AS retained_3m,
    COUNTIF(
      is_currently_active = 1 OR last_cancel_date >= DATE_ADD(signup_date, INTERVAL 6 MONTH)
    ) AS retained_6m
  FROM customer_cohort
  GROUP BY cohort_month
)
SELECT
  cohort_month,
  cohort_size,
  ROUND(retained_1m / cohort_size * 100, 1) AS retention_1m_pct,
  ROUND(retained_3m / cohort_size * 100, 1) AS retention_3m_pct,
  ROUND(retained_6m / cohort_size * 100, 1) AS retention_6m_pct
FROM retention
ORDER BY cohort_month;
```

## Results 13 samples

<img width="1920" height="1080" alt="Screenshot (235)" src="https://github.com/user-attachments/assets/2e5e2236-be13-4943-9bd9-babdf2273bb4" />


## Insight

Retention fluctuates significantly month to month (ranging from 30% to 100% at 
the 1-month mark) largely due to small cohort sizes (6–18 customers per month), 
so individual month swings shouldn't be over-interpreted. Two patterns stand out: 
(1) cohorts from 2026 onward show a general downward trend in early retention 
compared to 2024 cohorts, suggesting newer customers may be churning faster than 
earlier ones; (2) the most recent cohorts (2026-04 through 2026-06) show low 
retention_6m_pct, but this is at least partly a measurement artifact — these 
cohorts haven't yet reached the 6-month mark as of today, so their 6-month 
retention figure is understated and not directly comparable to older, fully-matured 
cohorts.


## Business Recommendation
Treat the apparent 2026 retention decline as a signal worth investigating further 
(cross-check against Q6/Q7 findings — did churn concentrate in certain regions or 
plans during this period?), but exclude cohorts younger than 6 months 
(2026-04 onward) from any headline "6-month retention rate" reported to 
stakeholders until they've had time to mature, to avoid an artificially alarming 
figure. Given the small monthly cohort sizes, consider reporting retention in 
quarterly cohorts instead of monthly for more statistically stable trend reporting.
