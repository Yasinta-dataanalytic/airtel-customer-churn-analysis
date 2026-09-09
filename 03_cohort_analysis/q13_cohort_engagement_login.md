Q13: Cohort Engagement (Login Activity)
Business Question: Do customers who log in during their first 30 days stay longer than those who don't?
SQL Query
```sql
WITH clean_logins AS (
  SELECT
    customer_id,
    COALESCE(
      SAFE.PARSE_DATETIME('%Y-%m-%d %H:%M:%S', login_timestamp),
      SAFE.PARSE_DATETIME('%d/%m/%Y %H:%M', login_timestamp),
      SAFE.PARSE_DATETIME('%m/%d/%Y %I:%M %p', login_timestamp),
      SAFE.PARSE_DATETIME('%d-%b-%Y %H:%M:%S', login_timestamp),
      SAFE.PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', login_timestamp)
    ) AS login_timestamp
  FROM `airtel-churn-analysis.churn_analysis.user_login_1`
),
customer_cohort AS (
  SELECT
    customer_id,
    signup_date,
    MAX(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS is_currently_active
  FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
  WHERE signup_date IS NOT NULL
  GROUP BY customer_id, signup_date
),
early_engagement AS (
  SELECT
    cc.customer_id,
    MAX(
      CASE WHEN DATE(cl.login_timestamp) <= DATE_ADD(cc.signup_date, INTERVAL 30 DAY)
        THEN 1 ELSE 0 END
    ) AS logged_in_first_30_days
  FROM customer_cohort cc
  LEFT JOIN clean_logins cl ON cl.customer_id = cc.customer_id
  GROUP BY cc.customer_id
)
SELECT
  CASE
    WHEN ee.logged_in_first_30_days = 1 THEN 'Logged in within first 30 days'
    ELSE 'No login in first 30 days'
  END AS engagement_group,
  COUNT(*) AS customer_count,
  COUNTIF(cc.is_currently_active = 1) AS still_active_count,
  ROUND(COUNTIF(cc.is_currently_active = 1) / COUNT(*) * 100, 1) AS pct_still_active
FROM customer_cohort cc
JOIN early_engagement ee USING (customer_id)
GROUP BY engagement_group
ORDER BY engagement_group;
```
Results
**Retention by early login engagement:**
<img width="1920" height="1080" alt="Screenshot (245)" src="https://github.com/user-attachments/assets/43524737-42b0-4ef4-897d-4c287c1f335c" />
<img width="1920" height="1080" alt="Screenshot (247)" src="https://github.com/user-attachments/assets/eafd1740-6b5c-49c7-bb35-31959f01088d" />

##Insight
Contrary to the hypothesis, customers who logged in during their first 30 days 
actually show *lower* retention (34.4% still active) than those who never logged 
in during that window (39.4% still active) — a 5-point gap in the opposite 
direction expected. This suggests early app/USSD login activity is not a reliable 
predictor of long-term retention in this dataset. One plausible explanation: many 
customers may primarily use USSD or offline channels for day-to-day service 
(check balance, top-up) without this being captured as a "login" event, meaning 
the login metric itself may not represent true engagement for a meaningful share 
of the customer base.

##Business Recommendation
Do not use early app login alone as a retention/engagement signal — it does not 
hold up against the data. Before building any engagement-based intervention (e.g., 
"nudge customers who haven't logged in"), Airtel should first validate what 
"engagement" actually predicts churn by testing other candidate signals (e.g., 
USSD usage, airtime top-up frequency, customer support interactions) rather than 
assuming app login is the right proxy. This finding itself is valuable: it prevents 
Airtel from investing in an app-engagement campaign that the data doesn't support.
