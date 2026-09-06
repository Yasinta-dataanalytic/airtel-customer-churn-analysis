-- ============================================================
-- Q2: DUPLICATE DETECTION
-- Business question: Are there duplicate customer or transaction
-- records inflating our numbers?
-- ============================================================

-- 1. Find exact duplicate customer rows (same person recorded twice, identically)
```sql
SELECT
  customer_id,
  full_name,
  email,
  COUNT(*) AS duplicate_count
FROM `airtel-churn-analysis.churn_analysis.customers`
GROUP BY customer_id, full_name, email, phone, region, signup_date, plan_type
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2. Find exact duplicate payment rows (same payment recorded twice — double-charge glitch)
SELECT
  payment_id,
  customer_id,
  subscription_id,
  payment_date,
  amount,
  COUNT(*) AS duplicate_count
FROM `airtel-churn-analysis.churn_analysis.payments`
GROUP BY payment_id, customer_id, subscription_id, payment_date, amount, payment_method
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 3. Find exact duplicate login events (same login logged twice — pipeline glitch)
SELECT
  login_id,
  customer_id,
  login_timestamp,
  COUNT(*) AS duplicate_count
FROM `airtel-churn-analysis.churn_analysis.user_login_1`
GROUP BY login_id, customer_id, login_timestamp, device_type, login_status, ip_address, app_version
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 4. Summary: total duplicate rows found per table (for the business question / insight)
WITH dup_customers AS (
  SELECT COUNT(*) AS dup_rows FROM (
    SELECT customer_id FROM `airtel-churn-analysis.churn_analysis.customers`
    GROUP BY customer_id, full_name, email, phone, region, signup_date, plan_type
    HAVING COUNT(*) > 1
  )
),
dup_payments AS (
  SELECT COUNT(*) AS dup_rows FROM (
    SELECT payment_id FROM `airtel-churn-analysis.churn_analysis.payments`
    GROUP BY payment_id, customer_id, subscription_id, payment_date, amount, payment_method
    HAVING COUNT(*) > 1
  )
),
dup_logins AS (
  SELECT COUNT(*) AS dup_rows FROM (
    SELECT login_id FROM `airtel-churn-analysis.churn_analysis.user_login_1`
    GROUP BY login_id, customer_id, login_timestamp, device_type, login_status, ip_address, app_version
    HAVING COUNT(*) > 1
  )
)
SELECT 'customers' AS table_name, dup_rows AS duplicate_groups_found FROM dup_customers
UNION ALL
SELECT 'payments', dup_rows FROM dup_payments
UNION ALL
SELECT 'user_login_1', dup_rows FROM dup_logins;
```
#### Resulths
**Duplicate customers found (14 groups):**
<img width="1920" height="1080" alt="Screenshot (147)" src="https://github.com/user-attachments/assets/a4772a3e-8593-45d2-85c9-086dda0024de" />
**Duplicate payments found (20 groups):**
<img width="1920" height="1080" alt="Screenshot (148)" src="https://github.com/user-attachments/assets/ce569155-b78e-4182-b31c-dfe1e1f4b636" />
**Duplicate login events found (30 groups):** showing first 17 group
<img width="1920" height="1080" alt="Screenshot (152)" src="https://github.com/user-attachments/assets/f22dfe3e-f411-4315-a132-15dc282534c5" />
**Summary — total duplicate groups per table:**
<img width="1920" height="1080" alt="Screenshot (151)" src="https://github.com/user-attachments/assets/e162a0f2-df63-47b6-8094-01eab4b5afd1" />
## Insight
We identified 14 duplicate groups in customers (13 with 2 copies, one with 3 copies), 
20 duplicate groups in payments, and 30 duplicate groups in user_login_1. While the 
duplicate rate is relatively small as a share of each table, the payments duplicates 
are the most business-critical: since each duplicate pair records an identical amount 
twice, any revenue total calculated without de-duplication would overstate actual 
revenue.
## Business Recommendation

Before any revenue or customer-count calculation runs in production, de-duplicate the 
payments and customers tables using a ROW_NUMBER() OVER (PARTITION BY ...) approach to 
keep only one copy per unique record. Additionally, investigate the root cause — 
duplicate payment_id and login_id values suggest a retry or double-write issue in the 
source system, which should be fixed upstream rather than only cleaned downstream.






