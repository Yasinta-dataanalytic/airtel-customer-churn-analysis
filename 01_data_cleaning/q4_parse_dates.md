# Q4: Parse Mixed Date Formats

**Business Question:** Can we reconcile the multiple date formats in our records 
into a single usable format?

## SQL Query

```sql
-- 1. CUSTOMERS: parse signup_date (5 mixed formats)
SELECT
  signup_date AS raw_signup_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', signup_date),
    SAFE.PARSE_DATE('%d/%m/%Y', signup_date),
    SAFE.PARSE_DATE('%m/%d/%Y', signup_date),
    SAFE.PARSE_DATE('%d-%b-%Y', signup_date),
    SAFE.PARSE_DATE('%B %d, %Y', signup_date)
  ) AS clean_signup_date
FROM `airtel-churn-analysis.churn_analysis.customers`
LIMIT 20;

-- 2. SUBSCRIPTIONS: parse start_date and end_date
SELECT
  start_date AS raw_start_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', start_date),
    SAFE.PARSE_DATE('%d/%m/%Y', start_date),
    SAFE.PARSE_DATE('%m/%d/%Y', start_date),
    SAFE.PARSE_DATE('%d-%b-%Y', start_date),
    SAFE.PARSE_DATE('%B %d, %Y', start_date)
  ) AS clean_start_date,
  end_date AS raw_end_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', end_date),
    SAFE.PARSE_DATE('%d/%m/%Y', end_date),
    SAFE.PARSE_DATE('%m/%d/%Y', end_date),
    SAFE.PARSE_DATE('%d-%b-%Y', end_date),
    SAFE.PARSE_DATE('%B %d, %Y', end_date)
  ) AS clean_end_date
FROM `airtel-churn-analysis.churn_analysis.subscriptions`
LIMIT 20;

-- 3. PAYMENTS: parse payment_date
SELECT
  payment_date AS raw_payment_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', payment_date),
    SAFE.PARSE_DATE('%d/%m/%Y', payment_date),
    SAFE.PARSE_DATE('%m/%d/%Y', payment_date),
    SAFE.PARSE_DATE('%d-%b-%Y', payment_date),
    SAFE.PARSE_DATE('%B %d, %Y', payment_date)
  ) AS clean_payment_date
FROM `airtel-churn-analysis.churn_analysis.payments`
LIMIT 20;

-- 4. SUPPORT_TICKETS: parse created_date
SELECT
  created_date AS raw_created_date,
  COALESCE(
    SAFE.PARSE_DATE('%Y-%m-%d', created_date),
    SAFE.PARSE_DATE('%d/%m/%Y', created_date),
    SAFE.PARSE_DATE('%m/%d/%Y', created_date),
    SAFE.PARSE_DATE('%d-%b-%Y', created_date),
    SAFE.PARSE_DATE('%B %d, %Y', created_date)
  ) AS clean_created_date
FROM `airtel-churn-analysis.churn_analysis.support_tickets`
LIMIT 20;

-- 5. USER_LOGIN_1: parse login_timestamp (datetime, includes an ISO "T" format)
SELECT
  login_timestamp AS raw_login_timestamp,
  COALESCE(
    SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', login_timestamp),
    SAFE.PARSE_DATETIME('%d/%m/%Y %H:%M', login_timestamp),
    SAFE.PARSE_DATETIME('%m/%d/%Y %I:%M %p', login_timestamp),
    SAFE.PARSE_DATETIME('%d-%b-%Y %H:%M:%S', login_timestamp),
    SAFE.PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', login_timestamp)
  ) AS clean_login_timestamp
FROM `airtel-churn-analysis.churn_analysis.user_login_1`
LIMIT 20;

-- 6. VALIDATION: how many rows FAILED to parse in each table (should be close to 0)
WITH date_check AS (
  SELECT
    'customers.signup_date' AS column_checked,
    COUNT(*) AS total_rows,
    COUNTIF(
      COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', signup_date),
        SAFE.PARSE_DATE('%d/%m/%Y', signup_date),
        SAFE.PARSE_DATE('%m/%d/%Y', signup_date),
        SAFE.PARSE_DATE('%d-%b-%Y', signup_date),
        SAFE.PARSE_DATE('%B %d, %Y', signup_date)
      ) IS NULL
      AND signup_date IS NOT NULL AND TRIM(signup_date) NOT IN ('', 'N/A', 'unknown')
    ) AS unparsed_non_null_rows
  FROM `airtel-churn-analysis.churn_analysis.customers`

  UNION ALL

  SELECT
    'payments.payment_date',
    COUNT(*),
    COUNTIF(
      COALESCE(
        SAFE.PARSE_DATE('%Y-%m-%d', payment_date),
        SAFE.PARSE_DATE('%d/%m/%Y', payment_date),
        SAFE.PARSE_DATE('%m/%d/%Y', payment_date),
        SAFE.PARSE_DATE('%d-%b-%Y', payment_date),
        SAFE.PARSE_DATE('%B %d, %Y', payment_date)
      ) IS NULL
      AND payment_date IS NOT NULL AND TRIM(payment_date) NOT IN ('', 'N/A', 'unknown')
    )
  FROM `airtel-churn-analysis.churn_analysis.payments`

  UNION ALL

  SELECT
    'user_login_1.login_timestamp',
    COUNT(*),
    COUNTIF(
      COALESCE(
        SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', login_timestamp),
        SAFE.PARSE_DATETIME('%d/%m/%Y %H:%M', login_timestamp),
        SAFE.PARSE_DATETIME('%m/%d/%Y %I:%M %p', login_timestamp),
        SAFE.PARSE_DATETIME('%d-%b-%Y %H:%M:%S', login_timestamp),
        SAFE.PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', login_timestamp)
      ) IS NULL
      AND login_timestamp IS NOT NULL AND TRIM(login_timestamp) NOT IN ('', 'N/A', 'unknown')
    )
  FROM `airtel-churn-analysis.churn_analysis.user_login_1`
)
SELECT
  column_checked,
  total_rows,
  unparsed_non_null_rows,
  ROUND(unparsed_non_null_rows / total_rows * 100, 2) AS pct_failed_to_parse
FROM date_check
ORDER BY column_checked;
```

## Results

**Customers signup_date parsing (sample):**

<img width="1920" height="1080" alt="Screenshot (197)" src="https://github.com/user-attachments/assets/668a01ab-a14c-4d71-9276-e51887491187" />



**Subscriptions start_date and end_date parsing (sample — nulls in end_date are expected for active subscriptions):**

<img width="1920" height="1080" alt="Screenshot (198)" src="https://github.com/user-attachments/assets/5a968244-9fdf-440b-be01-c7f79a48378c" />



**Payments payment_date parsing (sample):**

<img width="1920" height="1080" alt="Screenshot (199)" src="https://github.com/user-attachments/assets/2bff90d1-737e-4855-925e-1bf1dab35570" />



**Support tickets created_date parsing (sample):**

<img width="1920" height="1080" alt="Screenshot (200)" src="https://github.com/user-attachments/assets/6b188503-454c-42c9-beca-dc6a2b1b7e22" />



**User login timestamp parsing (sample):**

<img width="1920" height="1080" alt="Screenshot (202)" src="https://github.com/user-attachments/assets/2602f47d-ca82-496d-91ab-869fe43f45ea" />



**Validation — parse failure rate per table (0% across the board):**
<img width="1920" height="1080" alt="Screenshot (203)" src="https://github.com/user-attachments/assets/85aa057e-ea44-40b5-a70e-b07da0e448de" />





## Insight

All five date formats identified during the initial audit (YYYY-MM-DD, DD/MM/YYYY, 
MM/DD/YYYY, DD-Mon-YYYY, "Month DD, YYYY", plus an ISO datetime format for logins) 
were successfully parsed with a 0% failure rate across customers (325 rows), 
payments (1,287 rows), and user_login_1 (3,762 rows) — confirming no additional, 
unaccounted-for date format exists in the dataset. Null end_date values in 
subscriptions are expected and correct: they represent still-active subscriptions 
that have not yet been cancelled, not a parsing failure.

## Business Recommendation

Since date parsing is now 100% reliable, all downstream date-based analysis 
(cancellation timing, cohort retention, revenue trends) can safely use the 
clean_* date columns. Going forward, Airtel's data entry systems should standardize 
on a single date format (ISO 8601: YYYY-MM-DD) at the point of capture, eliminating 
the need for this multi-format parsing step entirely for future data.
