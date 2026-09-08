# Q7: Churn Rate by Plan Type

**Business Question:** Which subscription plan has the highest cancellation rate — is Premium retaining better than Basic?

## SQL Query

```sql
SELECT
  plan_type,
  COUNT(*) AS total_subscriptions,
  COUNTIF(status = 'Cancelled') AS cancelled_subscriptions,
  COUNTIF(status = 'Active') AS active_subscriptions,
  COUNTIF(status = 'Suspended') AS suspended_subscriptions,
  ROUND(
    COUNTIF(status = 'Cancelled') / COUNT(*) * 100, 1
  ) AS churn_rate_pct,
  ROUND(AVG(monthly_fee), 0) AS avg_monthly_fee
FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
GROUP BY plan_type
ORDER BY churn_rate_pct DESC;
```

## Results

<img width="1920" height="1080" alt="Screenshot (222)" src="https://github.com/user-attachments/assets/e640be8b-8c26-4eec-acab-5cfebea8bd7d" />


## Insight

Churn rate is surprisingly uniform across all three plans — Standard (50.0%), 
Premium (45.0%), and Basic (44.9%) — with only a 5-point spread between highest 
and lowest. Contrary to the common assumption that higher-priced plans retain 
better, Premium customers (avg. TZS 85,000/month) churn at nearly the same rate 
as Basic customers (avg. TZS 35,000/month). Standard plan actually has the worst 
retention despite sitting in the middle price tier — this is the one segment that stands out as underperforming.


## Business Recommendation
Since price tier alone does not explain churn, Airtel should not assume upgrading 
customers to Premium will improve retention — the data suggests churn drivers lie 
elsewhere (likely service quality, support experience, or engagement — see Q10 and 
Q13). Investigate the Standard plan specifically: since it neither offers Basic's 
low price nor Premium's full feature set, it may be perceived as poor value — 
consider whether Standard should be repositioned, discounted, or phased out in 
favor of a clearer two-tier (Basic/Premium) structure.
