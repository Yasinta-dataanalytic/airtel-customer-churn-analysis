-- ============================================================
-- Q5: BUILD THE MASTER CLEANED VIEW
-- Business question: Can we build one reliable, single source
-- of truth combining all five data sources?
-- ============================================================
```sql
CREATE OR REPLACE VIEW `airtel-churn-analysis.churn_analysis.v_master_clean` AS

WITH

-- 1. Clean customers (dedup + standardize region/plan_type + parse signup_date)
clean_customers AS (
  SELECT * EXCEPT(row_num) FROM (
    SELECT
      customer_id,
      INITCAP(TRIM(REGEXP_REPLACE(full_name, r'\s+', ' '))) AS full_name,
      CASE WHEN email IS NULL OR TRIM(email) IN ('', 'N/A') THEN NULL ELSE TRIM(email) END AS email,
      CASE
        WHEN region IS NULL OR TRIM(region) = '' OR LOWER(TRIM(region)) = 'unknown' THEN 'Unknown'
        ELSE INITCAP(TRIM(region))
      END AS region,
      COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', signup_date),
        SAFE.PARSE_DATE('%d/%m/%Y', signup_date),
        SAFE.PARSE_DATE('%m/%d/%Y', signup_date),
        SAFE.PARSE_DATE('%d-%b-%Y', signup_date),
        SAFE.PARSE_DATE('%B %d, %Y', signup_date)
      ) AS signup_date,
      CASE
        WHEN LOWER(TRIM(plan_type)) LIKE '%premium%' THEN 'Premium'
        WHEN LOWER(TRIM(plan_type)) LIKE '%standard%' THEN 'Standard'
        ELSE 'Basic'
      END AS plan_type,
      ROW_NUMBER() OVER (
        PARTITION BY customer_id, full_name, email, phone, region, signup_date, plan_type
        ORDER BY customer_id
      ) AS row_num
    FROM `airtel-churn-analysis.churn_analysis.customers`
  )
  WHERE row_num = 1
),

-- 2. Clean subscriptions (standardize status/plan_type + parse dates)
clean_subscriptions AS (
  SELECT
    subscription_id,
    customer_id,
    CASE
      WHEN LOWER(TRIM(plan_type)) LIKE '%premium%' THEN 'Premium'
      WHEN LOWER(TRIM(plan_type)) LIKE '%standard%' THEN 'Standard'
      ELSE 'Basic'
    END AS plan_type,
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', start_date),
      SAFE.PARSE_DATE('%d/%m/%Y', start_date),
      SAFE.PARSE_DATE('%m/%d/%Y', start_date),
      SAFE.PARSE_DATE('%d-%b-%Y', start_date),
      SAFE.PARSE_DATE('%B %d, %Y', start_date)
    ) AS start_date,
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', end_date),
      SAFE.PARSE_DATE('%d/%m/%Y', end_date),
      SAFE.PARSE_DATE('%m/%d/%Y', end_date),
      SAFE.PARSE_DATE('%d-%b-%Y', end_date),
      SAFE.PARSE_DATE('%B %d, %Y', end_date)
    ) AS end_date,
    CASE WHEN monthly_fee > 0 THEN monthly_fee ELSE NULL END AS monthly_fee,
    CASE
      WHEN LOWER(TRIM(status)) LIKE 'cancel%' THEN 'Cancelled'
      WHEN LOWER(TRIM(status)) = 'suspended' THEN 'Suspended'
      ELSE 'Active'
    END AS status
  FROM `airtel-churn-analysis.churn_analysis.subscriptions`
),

-- 3. Clean payments (dedup + standardize payment_method + parse payment_date)
clean_payments AS (
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
      CASE
        WHEN payment_method IS NULL THEN 'Unknown'
        WHEN REPLACE(LOWER(TRIM(payment_method)), '-', '') LIKE '%mpesa%' THEN 'M-Pesa'
        WHEN LOWER(TRIM(payment_method)) LIKE '%airtel%' THEN 'Airtel Money'
        WHEN LOWER(TRIM(payment_method)) LIKE '%bank%' THEN 'Bank Transfer'
        ELSE 'Unknown'
      END AS payment_method,
      ROW_NUMBER() OVER (
        PARTITION BY payment_id, customer_id, subscription_id, payment_date, CAST(amount AS STRING), payment_method
        ORDER BY payment_id
      ) AS row_num
    FROM `airtel-churn-analysis.churn_analysis.payments`
  )
  WHERE row_num = 1
),

-- 4. Clean support tickets (standardize issue_type + parse created_date)
clean_tickets AS (
  SELECT
    ticket_id,
    customer_id,
    CASE
      WHEN issue_type IS NULL OR TRIM(issue_type) IN ('', 'N/A') THEN 'Unknown'
      WHEN LOWER(TRIM(issue_type)) LIKE '%signal%' THEN 'No Signal'
      WHEN LOWER(TRIM(issue_type)) LIKE '%slow%' THEN 'Slow Speed'
      WHEN LOWER(TRIM(issue_type)) LIKE '%bill%' THEN 'Billing Issue'
      WHEN LOWER(TRIM(issue_type)) LIKE '%device%' THEN 'Device Fault'
      ELSE 'Other/Unknown'
    END AS issue_type,
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', created_date),
      SAFE.PARSE_DATE('%d/%m/%Y', created_date),
      SAFE.PARSE_DATE('%m/%d/%Y', created_date),
      SAFE.PARSE_DATE('%d-%b-%Y', created_date),
      SAFE.PARSE_DATE('%B %d, %Y', created_date)
    ) AS created_date,
    CASE
      WHEN LOWER(CAST(resolved AS STRING)) IN ('y','yes','1') THEN TRUE
      WHEN LOWER(CAST(resolved AS STRING)) IN ('n','no','0') THEN FALSE
      ELSE NULL
    END AS is_resolved
  FROM `airtel-churn-analysis.churn_analysis.support_tickets`
),

-- 5. Clean logins (standardize device_type/login_status + parse login_timestamp)
clean_logins AS (
  SELECT
    login_id,
    customer_id,
    COALESCE(
      SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', login_timestamp),
      SAFE.PARSE_DATETIME('%d/%m/%Y %H:%M', login_timestamp),
      SAFE.PARSE_DATETIME('%m/%d/%Y %I:%M %p', login_timestamp),
      SAFE.PARSE_DATETIME('%d-%b-%Y %H:%M:%S', login_timestamp),
      SAFE.PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', login_timestamp)
    ) AS login_timestamp,
    CASE
      WHEN device_type IS NULL OR TRIM(device_type) = '' THEN 'Unknown'
      WHEN LOWER(TRIM(device_type)) LIKE '%android%' THEN 'Android'
      WHEN LOWER(TRIM(device_type)) LIKE '%ios%' THEN 'iOS'
      WHEN LOWER(TRIM(device_type)) LIKE '%web%' THEN 'Web'
      WHEN LOWER(TRIM(device_type)) LIKE '%ussd%' THEN 'USSD'
      ELSE 'Unknown'
    END AS device_type,
    CASE
      WHEN login_status IS NULL OR TRIM(login_status) IN ('', 'N/A') THEN 'Unknown'
      WHEN LOWER(TRIM(login_status)) LIKE 'success%' THEN 'Success'
      WHEN LOWER(TRIM(login_status)) LIKE 'fail%' THEN 'Failed'
      ELSE 'Unknown'
    END AS login_status
  FROM `airtel-churn-analysis.churn_analysis.user_login_1`
),

-- 6. Payment summary per subscription (avoids fan-out on final join)
payment_summary AS (
  SELECT
    subscription_id,
    SUM(amount) AS total_paid,
    COUNT(*) AS payment_count,
    MAX(payment_date) AS last_payment_date
  FROM clean_payments
  WHERE amount IS NOT NULL
  GROUP BY subscription_id
),

-- 7. Ticket summary per customer (avoids fan-out on final join)
ticket_summary AS (
  SELECT
    customer_id,
    COUNT(*) AS ticket_count,
    COUNTIF(is_resolved = TRUE) AS resolved_count,
    COUNTIF(is_resolved = FALSE) AS unresolved_count
  FROM clean_tickets
  GROUP BY customer_id
),

-- 8. Login summary per customer (avoids fan-out on final join)
login_summary AS (
  SELECT
    customer_id,
    COUNT(*) AS login_count,
    MAX(login_timestamp) AS last_login,
    COUNTIF(login_status = 'Failed') AS failed_login_count
  FROM clean_logins
  GROUP BY customer_id
)

-- 9. FINAL JOIN — grain = one row per subscription
SELECT
  s.subscription_id,
  s.customer_id,
  c.full_name,
  c.email,
  c.region,
  c.signup_date,
  s.plan_type,
  s.start_date,
  s.end_date,
  s.status,
  s.monthly_fee,
  p.total_paid,
  p.payment_count,
  p.last_payment_date,
  t.ticket_count,
  t.resolved_count,
  t.unresolved_count,
  l.login_count,
  l.last_login,
  l.failed_login_count
FROM clean_subscriptions s
LEFT JOIN clean_customers c USING (customer_id)
LEFT JOIN payment_summary p USING (subscription_id)
LEFT JOIN ticket_summary t USING (customer_id)
LEFT JOIN login_summary l USING (customer_id);

-- Preview the view
SELECT * FROM `airtel-churn-analysis.churn_analysis.v_master_clean` LIMIT 10;

-- Row count check (should equal the number of subscriptions, ~384)
SELECT COUNT(*) AS total_rows FROM `airtel-churn-analysis.churn_analysis.v_master_clean`;
```
## Result
**Preview of v_master_clean (sample of 20 rows):**
<img width="1920" height="1080" alt="Screenshot (214)" src="https://github.com/user-attachments/assets/40efbbe9-97c0-4591-940c-f375c4f80795" />

**Row count check (384 subscriptions — confirms no fan-out):**
<img width="1920" height="1080" alt="Screenshot (210)" src="https://github.com/user-attachments/assets/17a0d733-2324-4ee1-8139-36f25c579824" />

## Insight

The master view successfully combines all 5 cleaned tables at subscription-level 
grain with zero row inflation: the final row count (384) exactly matches the 
number of subscriptions, confirming that pre-aggregating payments, tickets, and 
logins before joining avoided the fan-out problem common in multi-table joins. 
Customers with multiple subscriptions (e.g., James Shayo, who has two separate 
router subscriptions) correctly appear once per subscription, not duplicated — 
this is expected business behavior, not a data quality issue.

## Business Recommendation

This view (v_master_clean) should become the single source of truth for all 
downstream reporting — analysts should query v_master_clean directly rather than 
the raw tables, since it already resolves duplicates, standardizes text fields, 
and parses dates. This also means any future dashboard or BI tool (e.g., Power BI) 
can connect to one clean view instead of stitching together five messy tables.
