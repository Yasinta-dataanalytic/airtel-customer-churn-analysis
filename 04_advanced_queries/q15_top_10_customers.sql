-- ============================================================
-- Q15: TOP 10 CUSTOMERS BY REVENUE (RANK)
-- Business question: Who are our highest-value customers, and
-- are any of them showing signs of being at risk?
-- ============================================================
```sql
WITH customer_revenue AS (
  SELECT
    customer_id,
    ANY_VALUE(full_name) AS full_name,
    SUM(total_paid) AS total_revenue
  FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
  WHERE total_paid IS NOT NULL
  GROUP BY customer_id
),

ranked AS (
  SELECT
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    customer_id,
    full_name,
    total_revenue
  FROM customer_revenue
)

SELECT *
FROM ranked
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
```
## Result
<img width="1920" height="1080" alt="Screenshot (250)" src="https://github.com/user-attachments/assets/cd242f3b-8dfc-4d8c-9475-49cf53c26f25" />
## Insight

The top 10 customers by revenue range from TZS 660,000 to TZS 1,020,000. Aisha Mushi (CUST1259) stands alone at the top with TZS 1,020,000 — roughly 20% ahead of the next group. Three clear ties appear in the ranking: rank 2 (three customers at TZS 850,000), rank 5 (two customers at TZS 765,000), and rank 7 (three customers at TZS 680,000). RANK() correctly skips numbers after each tie (2→2→2→5, not 2→3→4→5), which reflects each customer's true competitive standing rather than just counting distinct revenue tiers — this is why RANK() was the right window function to use instead of DENSE_RANK() or ROW_NUMBER().

Also notable: two different customers share the name "Michael Lyimo" (rank 4: CUST1247, and rank 10: CUST1044) — they are distinct individuals, not a duplicate. This is a reminder that reporting should always key off customer_id, never name alone.

##Business Recommendation:

Airtel should formally designate these top 10 customers as a "high-value tier" with dedicated account management — proactive service alerts, priority support routing, and possibly loyalty incentives — since losing even one of them has a much larger revenue impact than losing an average customer. Because this query can be scheduled to run monthly, it's worth setting it up as a recurring BigQuery scheduled query that flags any top-10 customer who also shows churn-risk signals (from Q16: unresolved tickets or extended login inactivity), so account managers can intervene before a high-value customer cancels rather than after.
