# Q1: Data Quality Audit
**Business Question:** How complete and reliable is our data — what percentage 
of records have missing values in key fields, and is each table reliable enough 
to use for analysis?
-- ============================================================
-- Q1: DATA QUALITY AUDIT
-- Business question: How complete and reliable is our data —
-- what percentage of records have missing values in key fields,
-- and is each table reliable enough to use?
-- ============================================================

```sql
WITH audit AS (

  -- CUSTOMERS
  SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    ROUND(COUNTIF(region IS NULL OR TRIM(region) = '' OR LOWER(TRIM(region)) = 'unknown') / COUNT(*) * 100, 1) AS pct_missing_critical_1,
    ROUND(COUNTIF(email IS NULL OR TRIM(email) IN ('', 'N/A')) / COUNT(*) * 100, 1) AS pct_missing_secondary_1,
    'region' AS critical_field_checked
  FROM `airtel-churn-analysis.churn_analysis.customers`

  UNION ALL

  -- SUBSCRIPTIONS
  SELECT
    'subscriptions' AS table_name,
    COUNT(*) AS total_rows,
    ROUND(COUNTIF(status IS NULL OR TRIM(status) = '') / COUNT(*) * 100, 1) AS pct_missing_critical_1,
    ROUND(COUNTIF(monthly_fee IS NULL OR SAFE_CAST(monthly_fee AS FLOAT64) <= 0) / COUNT(*) * 100, 1) AS pct_missing_secondary_1,
    'status' AS critical_field_checked
  FROM `airtel-churn-analysis.churn_analysis.subscriptions`

  UNION ALL

  -- PAYMENTS (amount is FLOAT here, not STRING)
  SELECT
    'payments' AS table_name,
    COUNT(*) AS total_rows,
    ROUND(COUNTIF(amount IS NULL) / COUNT(*) * 100, 1) AS pct_missing_critical_1,
    ROUND(COUNTIF(payment_method IS NULL OR TRIM(payment_method) = '') / COUNT(*) * 100, 1) AS pct_missing_secondary_1,
    'amount' AS critical_field_checked
  FROM `airtel-churn-analysis.churn_analysis.payments`

  UNION ALL

  -- SUPPORT_TICKETS
  SELECT
    'support_tickets' AS table_name,
    COUNT(*) AS total_rows,
    ROUND(COUNTIF(resolved IS NULL) / COUNT(*) * 100, 1) AS pct_missing_critical_1,
    ROUND(COUNTIF(issue_type IS NULL OR TRIM(issue_type) IN ('', 'N/A')) / COUNT(*) * 100, 1) AS pct_missing_secondary_1,
    'resolved' AS critical_field_checked
  FROM `airtel-churn-analysis.churn_analysis.support_tickets`

  UNION ALL

  -- USER_LOGIN_1
  SELECT
    'user_login_1' AS table_name,
    COUNT(*) AS total_rows,
    ROUND(COUNTIF(login_status IS NULL OR TRIM(login_status) IN ('', 'N/A')) / COUNT(*) * 100, 1) AS pct_missing_critical_1,
    ROUND(COUNTIF(device_type IS NULL OR TRIM(device_type) = '') / COUNT(*) * 100, 1) AS pct_missing_secondary_1,
    'login_status' AS critical_field_checked
  FROM `airtel-churn-analysis.churn_analysis.user_login_1`

)

SELECT
  table_name,
  total_rows,
  critical_field_checked,
  pct_missing_critical_1 AS pct_missing_in_critical_field,
  pct_missing_secondary_1 AS pct_missing_in_secondary_field,
  CASE
    WHEN pct_missing_critical_1 <= 5 THEN 'Reliable'
    WHEN pct_missing_critical_1 <= 10 THEN 'Reliable (monitor)'
    WHEN pct_missing_critical_1 <= 20 THEN 'Needs Attention'
    ELSE 'Not Reliable — critical field too incomplete'
  END AS data_quality_verdict
FROM audit
ORDER BY table_name;
```
<img width="1920" height="1080" alt="Screenshot (126)" src="https://github.com/user-attachments/assets/c33fd870-9e6e-4dd7-b717-53eca685f5c9" />


## Insight

subscriptions.status is fully complete (0% missing), making it reliable for 
churn calculations. customers.region (32.6% missing) and user_login_1.login_status 
(21.9% missing) have significant gaps that need to be flagged as "Unknown" rather 
than dropped, to avoid losing sample size downstream.
## Business Recommendation

Make 'region' a mandatory field at customer sign-up to close this gap going 
forward, and investigate the app/system logging pipeline behind user_login_1 — 
a 21.9% missing login_status rate suggests a possible technical logging issue 
rather than genuine user behavior.
