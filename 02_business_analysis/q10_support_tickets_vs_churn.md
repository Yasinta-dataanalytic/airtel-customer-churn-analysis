# Q10: Support Tickets vs Churn

**Business Question:** Do customers who file more support tickets cancel at a higher rate?

## SQL Query

```sql
SELECT
  status,
  COUNT(*) AS subscription_count,
  ROUND(AVG(COALESCE(ticket_count, 0)), 2) AS avg_tickets_per_customer,
  ROUND(AVG(COALESCE(unresolved_count, 0)), 2) AS avg_unresolved_tickets,
  ROUND(SAFE_DIVIDE(COUNTIF(COALESCE(ticket_count, 0) >= 3), COUNT(*)) * 100, 1) AS pct_with_3plus_tickets
FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
GROUP BY status
ORDER BY avg_tickets_per_customer DESC;
```

## Results

<img width="1920" height="1080" alt="Screenshot (231)" src="https://github.com/user-attachments/assets/d1fcf320-eaa2-4299-b42f-1b81da9af09b" />


## Insight

Contrary to the initial hypothesis, support ticket volume shows almost no 
relationship with churn: Cancelled customers average 1.19 tickets versus 1.06 
for Active customers — a difference of just 0.13 tickets, and the percentage 
with 3+ tickets is nearly identical across all three statuses (21.9%–22.5%). 
Suspended customers actually have the highest average ticket count (1.2), not 
Cancelled. This suggests support tickets are not a strong standalone predictor 
of churn in this dataset — customers don't appear to leave primarily because 
they filed complaints.

## Business Recommendation
Since ticket volume alone doesn't meaningfully predict churn, Airtel should not 
rely on "high ticket count" as a churn early-warning signal by itself — it should 
be combined with other factors (login inactivity from Q13/Q14, payment drop-offs 
from Q20) into a multi-factor risk score rather than treated as a standalone 
trigger. It may be more valuable to investigate ticket *resolution speed or 
quality* rather than ticket *volume* as the true driver of dissatisfaction — 
that data isn't captured in the current dataset and could be a valuable addition 
going forward.
