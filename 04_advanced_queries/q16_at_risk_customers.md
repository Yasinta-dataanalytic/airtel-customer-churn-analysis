-- ============================================================
-- Q16: AT-RISK CUSTOMERS
-- Business question: Which currently-active customers show early
-- warning signs of churn (unresolved complaints + login drop-off)
-- before they actually cancel?
-- ============================================================

WITH ref AS (
  -- Use the latest login timestamp in the dataset as the "as of" snapshot date
  SELECT MAX(DATE(last_login)) AS as_of_date
  FROM `airtel-churn-analysis.churn_analysis.v_master_clean`
),

active_customers AS (
  SELECT
    v.subscription_id,
    v.customer_id,
    v.full_name,
    v.monthly_fee,
    COALESCE(v.unresolved_count, 0) AS unresolved_count,
    DATE_DIFF(r.as_of_date, DATE(v.last_login), DAY) AS days_since_last_login
  FROM `airtel-churn-analysis.churn_analysis.v_master_clean` v
  CROSS JOIN ref r
  WHERE v.status = 'Active'
),

scored AS (
  SELECT
    RANK() OVER (ORDER BY unresolved_count DESC, days_since_last_login DESC) AS risk_rank,
    customer_id,
    full_name,
    unresolved_count,
    days_since_last_login,
    monthly_fee
  FROM active_customers
  WHERE unresolved_count >= 2 OR days_since_last_login >= 45
)

SELECT *
FROM scored
ORDER BY risk_rank;

##Result
<img width="1090" height="532" alt="Screenshot 2026-09-10 103914" src="https://github.com/user-attachments/assets/cfe84533-e829-45af-9c49-ddc8e9bd0e78" />
##insight
The query flags 37 currently-active customers (out of 128) — 28.9% — showing early churn-warning signs: 2+ unresolved support tickets, or 45+ days since their last login. Ranking by risk severity, the top cases combine both signals at once: Grace Mwakalinga (CUST1246) has 4 unresolved tickets, while David Chombo, James Mrema, Peter Kimaro, and Ali Kimaro each have 3 unresolved tickets and haven't logged in for 4–16 days.

A few things stand out in the results. First, CUST1102 (Hassan Sanga) appears twice at rank 6 — this customer holds two separate active subscriptions, both flagged as at-risk, meaning a single unhappy customer could account for two cancellations, not one. Second, several flagged customers show a null value for days_since_last_login (e.g., CUST1130, CUST1206, CUST1255) — these customers have never logged in at all, so they only qualify through the unresolved-ticket condition. That's worth calling out explicitly rather than letting null pass silently, since a customer with zero login history is arguably a different — and potentially more urgent — kind of risk than one who used to log in and stopped.
## bussiness recomendation
Airtel's support and retention teams should treat this list as a weekly (or scheduled) action queue rather than a one-off report: customers combining multiple unresolved tickets with login inactivity are the clearest near-term cancellation risk and should be proactively contacted before they churn, not after. Given that CUST1102 holds two at-risk subscriptions, account-level (not just subscription-level) outreach would be more effective — resolving one underlying issue could save two lines at once. Separately, the customers who show unresolved tickets but have never logged in deserve a distinct workflow — they may not even be aware the self-service app exists, so the right intervention is onboarding/awareness, not a "come back" nudge.
