-- ============================================================
-- Q18: FAILED LOGIN RATE BY DEVICE
-- Business question: Does one device/channel fail logins more than
-- others, pointing to an app or network problem on that platform?
-- ============================================================
```sql
WITH clean_logins AS (
  SELECT
    login_id,
    customer_id,
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
)

SELECT
  device_type,
  COUNT(*) AS known_status_logins,
  COUNTIF(login_status = 'Failed') AS failed_logins,
  ROUND(COUNTIF(login_status = 'Failed') / COUNT(*) * 100, 1) AS failed_rate_pct
FROM clean_logins
WHERE login_status IN ('Success', 'Failed')  -- excludes ~22% of rows with missing/blank status
GROUP BY device_type
ORDER BY failed_rate_pct DESC;
```

##Result

<img width="736" height="278" alt="Screenshot 2026-09-10 152422" src="https://github.com/user-attachments/assets/551583ce-e5be-45cc-b3e7-0937b12e688e" />


##insight
Failed login rates are nearly identical across every device channel — iOS (59.2%), USSD (59.0%), Web (58.8%), Unknown (57.9%), and Android (56.2%) — a spread of less than 3 percentage points. This flat distribution is itself the finding: if one device or platform had a specific bug, we'd expect a clear outlier, but instead the failure rate is consistently high across the board, including USSD (a basic, low-tech channel) and iOS (a modern app). That points away from a device-specific problem and toward something shared across all channels — most likely the authentication backend itself, a shared OTP/SMS delivery issue, or a password/PIN reset flow that's broken for everyone regardless of how they connect.

It's also worth flagging that ~22% of all login records had no recorded status at all and were excluded from this calculation (known_status_logins only counts Success/Failed). If those excluded records are disproportionately one type of outcome, the true failure rate could shift — this is a data completeness caveat, not just a login-quality one

##bussiness recomendation
Since the problem isn't device-specific, Airtel's engineering team should investigate at the authentication-service layer — checking OTP delivery success rates, session/token expiry settings, and server-side error logs — rather than debugging the Android or iOS apps individually. A near-60% failure rate on login attempts is high enough that it's plausible some of the "engagement" and "at-risk" signals from Q13 and Q16 (customers who "never log in") may actually reflect customers who tried to log in and simply couldn't, rather than genuine disengagement — which would materially change how those churn-risk customers should be approached (a login fix, not a retention call, might be the real intervention needed).
