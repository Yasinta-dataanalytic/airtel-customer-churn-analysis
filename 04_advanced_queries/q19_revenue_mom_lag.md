-- ============================================================
-- Q19: MONTH-OVER-MONTH REVENUE CHANGE (LAG)
-- Business question: Is revenue growing, flat, or shrinking month to month?
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
  LAG(monthly_revenue) OVER (ORDER BY revenue_month) AS prev_month_revenue,
  monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY revenue_month) AS mom_change,
  ROUND(SAFE_DIVIDE(
    monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY revenue_month),
    LAG(monthly_revenue) OVER (ORDER BY revenue_month)
  ) * 100, 1) AS mom_pct_change
FROM monthly_agg
ORDER BY revenue_month;
```

##Result

<img width="1059" height="589" alt="Screenshot 2026-09-10 154428" src="https://github.com/user-attachments/assets/a036da56-cc8a-4b49-8de4-c1ea109b953d" />

##Insight
Month-over-month revenue swings wildly with no consistent direction — the range spans from +82.6% (March 2024) to -39.7% (February 2024), and this volatility continues right through the whole dataset (+50.9% in December 2025, immediately followed by -29.3% in January 2026). There's no seasonal pattern or steady growth trend visible; revenue simply moves up and down from month to month, which confirms the "flat, not growing" finding already surfaced in Q8 and Q17.

The tail end of the table (rows 33-34) shows the same anomaly flagged in Q17: October and December 2026 both collapse to just TZS 35,000, producing a misleading -97.6% and then a flat 0.0% MoM change. These two rows shouldn't be read as a real 98% revenue crash — they're the same incomplete/mis-dated trailing records identified earlier, and including them in a MoM trend chart would visually exaggerate a decline that isn't actually there.

##Bussiness recomendation
Airtel should treat month-over-month revenue as noisy rather than trending, and avoid over-reacting to any single month's swing (either up or down) without looking at a rolling 3-month average for a clearer signal. As with Q17, exclude or clearly footnote September–December 2026 in any dashboard using this table, since those trailing months reflect data completeness issues, not real business performance — presenting them as-is would give decision-makers a false impression of a sudden collapse.
