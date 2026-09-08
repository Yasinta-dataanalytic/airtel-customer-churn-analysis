# Q6: Churn Rate by Region

**Business Question:** Which regions have the highest customer cancellation rate?

## SQL Query

```sql
SELECT
  region,
  COUNT(*) AS total_subscriptions,
  COUNTIF(status = 'Cancelled') AS cancelled_subscriptions,
  COUNTIF(status = 'Active') AS active_subscriptions,
  COUNTIF(status = 'Suspended') AS suspended_subscriptions,
  ROUND(
    COUNTIF(status = 'Cancelled') / COUNT(*) * 100, 1
  ) AS churn_rate_pct
FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
GROUP BY region
ORDER BY churn_rate_pct DESC;
```

## Results
<img width="1920" height="1080" alt="Screenshot (218)" src="https://github.com/user-attachments/assets/f28ad156-1e80-460b-aed3-490be8a2da3c" />


## Insight

Mwanza has the lowest churn rate (34.1%) while the "Unknown" region — customers 
whose region was never recorded — has the highest churn rate at 50.8%, notably 
above every named region (next highest: Arusha at 48.8%). This connects directly 
back to the Q1 data quality finding (32.6% missing region data): customers with 
incomplete profile data appear to churn at a meaningfully higher rate than those 
with complete records, though it's unclear whether missing region causes churn 
or both stem from the same underlying disengagement.

Quick Takeaways
- Mwanza has the best retention (34.1% churn) — worth studying as a possible best-practice benchmark for other regions.
- Arusha and Mbeya have the highest churn among named regions (48.8% and 48.3%) — these need urgent retention attention.
- The "Unknown" region (missing data) has the single highest churn rate overall at 50.8%, reinforcing that incomplete customer records correlate with higher churn risk.

## Business Recommendation
Prioritize closing the region data gap identified in Q1 — not just for reporting 
accuracy, but because the "Unknown" segment itself represents Airtel's highest-risk 
customer group. Sales/onboarding teams should investigate why these customers' 
region was never captured (e.g., incomplete registration flow) and treat this as 
an early-warning signal worth flagging for retention outreach, not just a data 
cleanup task.
