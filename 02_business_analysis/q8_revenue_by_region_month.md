
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
)
SELECT
  FORMAT_DATE('%Y-%m', payment_date) AS revenue_month,
  SUM(amount) AS total_revenue
FROM clean_payments
WHERE amount IS NOT NULL AND payment_date IS NOT NULL
GROUP BY revenue_month
ORDER BY revenue_month
LIMIT 15;
```

## Results
**Revenue by region and month (sample):**
<img width="1920" height="1080" alt="Screenshot (229)" src="https://github.com/user-attachments/assets/32d7d016-3417-4656-b6ae-1e61c6d51fb8" />
**Overall monthly revenue trend (all regions combined):*
<img width="1920" height="1080" alt="Screenshot (227)" src="https://github.com/user-attachments/assets/2e928268-b5be-40f7-8158-7f5e76d93217" />
## Insight
Overall monthly revenue fluctuates between roughly TZS 1.5M–2.5M, with no clear 
sustained upward or downward trend over the ~34-month period — revenue is 
essentially flat with normal month-to-month variation, peaking around TZS 3M in 
one month. The sharp drop to near-zero in the final month is most likely a data 
completeness artifact, not a real business decline: since payment records are 
still being collected for the current/most recent month, that month naturally 
has fewer transactions logged so far and should not be read as a crash.
## Business Recommendation

When reporting this trend to stakeholders, exclude or clearly flag the final 
(in-progress) month to avoid the false impression of a revenue collapse. More 
importantly, since revenue is flat rather than growing, Airtel should treat this 
as a signal to actively pursue growth initiatives (upsell campaigns, new customer 
acquisition, or addressing the churn drivers found in Q6/Q7) rather than assuming 
steady-state revenue will continue to hold.
