# Q9: Average Time to Cancellation

**Business Question:** On average, how long does a customer stay before cancelling?

## SQL Query

```sql
SELECT
  plan_type,
  COUNT(*) AS cancelled_subscriptions,
  ROUND(AVG(DATE_DIFF(end_date, start_date, DAY)), 0) AS avg_days_to_cancel,
  ROUND(AVG(DATE_DIFF(end_date, start_date, DAY)) / 30, 1) AS avg_months_to_cancel,
  MIN(DATE_DIFF(end_date, start_date, DAY)) AS fastest_cancel_days,
  MAX(DATE_DIFF(end_date, start_date, DAY)) AS longest_before_cancel_days
FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
WHERE status = 'Cancelled'
  AND start_date IS NOT NULL
  AND end_date IS NOT NULL
GROUP BY plan_type
ORDER BY avg_days_to_cancel;
```

## Results

<img width="1920" height="1080" alt="Screenshot (230)" src="https://github.com/user-attachments/assets/6bfe0061-5517-42e5-834b-20e82de622ed" />


## Insight
On average, customers stay 169–192 days (roughly 5.6–6.4 months) before cancelling, 
with Premium customers lasting notably longer (192 days) than Basic (169 days) — 
suggesting Premium subscribers are somewhat more committed before churning, even 
though Q7 showed their overall churn *rate* isn't meaningfully lower. However, the 
fastest_cancel_days column reveals a data quality issue: Basic (-92 days) and 
Standard (-12 days) show negative values, meaning some subscriptions have an 
end_date recorded *before* their start_date — a logical impossibility that likely 
stems from a data entry error and should be excluded from analysis until corrected.



## Business Recommendation
Flag and investigate the subscriptions with negative cancellation duration as a 
data integrity issue before this average is used in any official reporting — 
these records should be corrected or excluded, not silently averaged in. On the 
substantive finding: since Premium customers take longer to churn despite similar 
churn rates, consider proactive retention outreach starting around month 4-5 
(before the ~6-month average cancellation point) rather than waiting until a 
customer has already decided to leave.
