# Q14: Days Since Last Login Before Cancellation

**Business Question:** Does a drop in login activity predict cancellation — how many days before cancelling do customers stop logging in?

## SQL Query

```sql
SELECT
  status,
  COUNT(*) AS customer_count,
  ROUND(AVG(
    CASE
      WHEN status = 'Cancelled' THEN DATE_DIFF(end_date, DATE(last_login), DAY)
      ELSE DATE_DIFF(CURRENT_DATE(), DATE(last_login), DAY)
    END
  ), 1) AS avg_days_since_last_login,
  MIN(
    CASE
      WHEN status = 'Cancelled' THEN DATE_DIFF(end_date, DATE(last_login), DAY)
      ELSE DATE_DIFF(CURRENT_DATE(), DATE(last_login), DAY)
    END
  ) AS min_days,
  MAX(
    CASE
      WHEN status = 'Cancelled' THEN DATE_DIFF(end_date, DATE(last_login), DAY)
      ELSE DATE_DIFF(CURRENT_DATE(), DATE(last_login), DAY)
    END
  ) AS max_days
FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
WHERE last_login IS NOT NULL
  AND status IN ('Active', 'Cancelled')
GROUP BY status
ORDER BY status;
```

**Note:** For Cancelled customers, this measures days between their last login and 
their cancellation date. For Active customers, it measures days between their last 
login and today — this acts as a comparison baseline for "normal" login recency 
among customers who haven't left.

## Results

<img width="1920" height="1080" alt="Screenshot (248)" src="https://github.com/user-attachments/assets/f2e7f66f-5dcc-4b33-85cd-69a183ba82f3" />


## Insight
The data reveals an unexpected anomaly rather than confirming the hypothesis: 
Cancelled customers show a *negative* average days-since-last-login (-292.3 days), 
meaning many of them have login activity recorded *after* their subscription's 
end_date — in some cases up to 964 days later. This could mean one of two things: 
(1) customers genuinely continue accessing the Airtel app/USSD after cancelling 
their router subscription (e.g., to check other services, review final billing, 
or because they have other active lines), or (2) there's a data linkage issue 
where login records aren't scoped to a specific subscription, making 
"last login before cancellation" an unreliable metric as currently defined. 
Active customers, by contrast, show a sensible average of 32.2 days since their 
last login (range 9-193 days) — consistent with normal recent app usage.

## Business Recommendation

Before using login recency as a churn-prediction signal, clarify with the 
engineering/product team whether user_login_1 events are tied to a specific 
subscription/service or represent account-wide activity across all of a 
customer's services — this determines whether "days since last login" is even 
a meaningful churn predictor for router-specific cancellations. Until that's 
resolved, don't build retention alerts on this metric; instead, prioritize the 
cleaner signals already validated in this analysis (region data completeness 
from Q1/Q6, and the revenue/retention tension from Q11/Q12).
