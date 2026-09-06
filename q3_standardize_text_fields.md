# Q3: Standardize Text Fields

**Business Question:** Can we standardize inconsistent status, plan, region, 
device, and payment method labels so reporting is accurate?

## SQL Query

```sql
-- 1. CUSTOMERS: standardize region and plan_type
SELECT DISTINCT
  region AS raw_region,
  CASE
    WHEN region IS NULL OR TRIM(region) = '' OR LOWER(TRIM(region)) = 'unknown' THEN 'Unknown'
    ELSE INITCAP(TRIM(region))
  END AS clean_region,
  plan_type AS raw_plan_type,
  CASE
    WHEN LOWER(TRIM(plan_type)) LIKE '%premium%' THEN 'Premium'
    WHEN LOWER(TRIM(plan_type)) LIKE '%standard%' THEN 'Standard'
    ELSE 'Basic'
  END AS clean_plan_type
FROM `airtel-churn-analysis.churn_analysis.customers`
ORDER BY raw_region;

-- 2. SUBSCRIPTIONS: standardize status
SELECT DISTINCT
  status AS raw_status,
  CASE
    WHEN LOWER(TRIM(status)) LIKE 'cancel%' THEN 'Cancelled'
    WHEN LOWER(TRIM(status)) = 'suspended' THEN 'Suspended'
    WHEN LOWER(TRIM(status)) = 'active' THEN 'Active'
    ELSE 'Unknown'
  END AS clean_status
FROM `airtel-churn-analysis.churn_analysis.subscriptions`
ORDER BY raw_status;

-- 3. PAYMENTS: standardize payment_method
-- (fixed: strip hyphens before matching, so "M-PESA" / "M-Pesa" both map correctly)
SELECT DISTINCT
  payment_method AS raw_payment_method,
  CASE
    WHEN payment_method IS NULL THEN 'Unknown'
    WHEN REPLACE(LOWER(TRIM(payment_method)), '-', '') LIKE '%mpesa%' THEN 'M-Pesa'
    WHEN LOWER(TRIM(payment_method)) LIKE '%airtel%' THEN 'Airtel Money'
    WHEN LOWER(TRIM(payment_method)) LIKE '%bank%' THEN 'Bank Transfer'
    ELSE 'Unknown'
  END AS clean_payment_method
FROM `airtel-churn-analysis.churn_analysis.payments`
ORDER BY raw_payment_method;

-- 4. SUPPORT_TICKETS: standardize issue_type
SELECT DISTINCT
  issue_type AS raw_issue_type,
  CASE
    WHEN issue_type IS NULL OR TRIM(issue_type) IN ('', 'N/A') THEN 'Unknown'
    WHEN LOWER(TRIM(issue_type)) LIKE '%signal%' THEN 'No Signal'
    WHEN LOWER(TRIM(issue_type)) LIKE '%slow%' THEN 'Slow Speed'
    WHEN LOWER(TRIM(issue_type)) LIKE '%bill%' THEN 'Billing Issue'
    WHEN LOWER(TRIM(issue_type)) LIKE '%device%' THEN 'Device Fault'
    ELSE 'Other/Unknown'
  END AS clean_issue_type
FROM `airtel-churn-analysis.churn_analysis.support_tickets`
ORDER BY raw_issue_type;

-- 5. USER_LOGIN_1: standardize device_type and login_status
SELECT DISTINCT
  device_type AS raw_device_type,
  CASE
    WHEN device_type IS NULL OR TRIM(device_type) = '' THEN 'Unknown'
    WHEN LOWER(TRIM(device_type)) LIKE '%android%' THEN 'Android'
    WHEN LOWER(TRIM(device_type)) LIKE '%ios%' THEN 'iOS'
    WHEN LOWER(TRIM(device_type)) LIKE '%web%' THEN 'Web'
    WHEN LOWER(TRIM(device_type)) LIKE '%ussd%' THEN 'USSD'
    ELSE 'Unknown'
  END AS clean_device_type,
  login_status AS raw_login_status,
  CASE
    WHEN login_status IS NULL OR TRIM(login_status) IN ('', 'N/A') THEN 'Unknown'
    WHEN LOWER(TRIM(login_status)) LIKE 'success%' THEN 'Success'
    WHEN LOWER(TRIM(login_status)) LIKE 'fail%' THEN 'Failed'
    ELSE 'Unknown'
  END AS clean_login_status
FROM `airtel-churn-analysis.churn_analysis.user_login_1`
ORDER BY raw_device_type;
```

## Results

**Region and plan type standardization (customers) — showing sample:**

<img width="1920" height="1080" alt="Screenshot (162)" src="https://github.com/user-attachments/assets/843cb0f5-bb4e-4d48-be93-17647b5c1a60" />



**Subscription status standardization:**

<img width="1920" height="1080" alt="Screenshot (163)" src="https://github.com/user-attachments/assets/78c8af4c-fa1c-444b-8917-0f1a7df9aa08" />


**Payment method standardization (after fix):**

<img width="1920" height="1080" alt="Screenshot (165)" src="https://github.com/user-attachments/assets/d3dc50cb-e96d-4443-834a-078bcbb2dc25" />


**Support ticket issue type standardization:**

<img width="1920" height="1080" alt="Screenshot (166)" src="https://github.com/user-attachments/assets/ab5d2d9e-ff5f-4122-9dfa-563a5d7947c3" />


**Device type and login status standardization — showing sample:**

<img width="1920" height="1080" alt="Screenshot (167)" src="https://github.com/user-attachments/assets/9a710e95-2129-49ec-a89f-a3daf7a8cb53" />


## Insight

Every text field examined had multiple inconsistent raw variants collapsing into 
a single clean category — for example, subscription status alone had 9 raw variants 
(ACTIVE, Active, active, CANCELLED, Cancelled, Canceled, cancelled, Suspended, 
suspended) mapping to just 3 clean values. Payment method standardization initially 
misclassified "M-PESA" as "Unknown" because a naive substring match failed against 
the hyphenated raw value — a reminder that string cleaning logic itself needs 
validation against edge cases before being trusted. This was caught and fixed by 
stripping hyphens before matching.

## Business Recommendation

Enforce dropdown/select fields (rather than free-text entry) for status, plan type, 
payment method, and issue type at the point of data entry — this eliminates 
inconsistent casing and spelling at the source rather than requiring cleanup after 
the fact. Until that's implemented, all downstream reporting should query through 
the standardized (clean_*) versions of these fields, not the raw columns, to avoid 
undercounting categories like M-Pesa payments.
