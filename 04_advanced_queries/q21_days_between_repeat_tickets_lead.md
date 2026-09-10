-- ============================================================
-- Q21: DAYS BETWEEN REPEAT TICKETS (LEAD)
-- Business question: When a customer files more than one support
-- ticket, how much time passes before the next one?
-- ============================================================
```sql
WITH clean_tickets AS (
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
    ) AS created_date
  FROM `airtel-churn-analysis.churn_analysis.support_tickets`
),

ticket_sequence AS (
  SELECT
    customer_id,
    ticket_id,
    issue_type,
    created_date,
    LEAD(created_date) OVER (PARTITION BY customer_id ORDER BY created_date) AS next_ticket_date,
    DATE_DIFF(
      LEAD(created_date) OVER (PARTITION BY customer_id ORDER BY created_date),
      created_date,
      DAY
    ) AS days_to_next_ticket
  FROM clean_tickets
  WHERE created_date IS NOT NULL
)

SELECT *
FROM ticket_sequence
WHERE next_ticket_date IS NOT NULL
ORDER BY days_to_next_ticket;
```

##Result

<img width="1131" height="551" alt="Screenshot 2026-09-10 162638" src="https://github.com/user-attachments/assets/cfdf9f67-acf6-43d4-a4d9-0376fa3ec517" />

##
Excluding the negative-day anomalies seen elsewhere in the project, this data is clean — the fastest repeat tickets come back within just 5 days, and the range shown here (5 to 64 days) fits a believable pattern of customers re-reporting issues within days to a couple of months.

Looking at the quickest repeats (5-21 days, rows 1-17), "Slow Speed" appears most often among issue types that recur fast — it shows up 5 times in the top 17 fastest repeats, more than any other category. That's a meaningful signal: a slow-speed complaint that gets "resolved" but recurs within a week or two suggests the underlying network/router issue often isn't actually fixed on the first visit — it's likely a temporary workaround rather than a real fix. "Device Fault" and "Billing Issue" also reappear in the fast-repeat group, but less consistently.

##Bussiness recomendation
Airtel's support team should treat fast repeat tickets (especially under ~2 weeks) as a signal of first-contact-resolution failure rather than a new, unrelated issue — and "Slow Speed" tickets in particular may need a follow-up call or field verification a few days after closing, rather than being closed and forgotten. This 5-64 day range could also be used to set a practical SLA benchmark: if a customer historically re-opens issues within 2-3 weeks, dispatching a technician for on-site diagnosis (instead of remote troubleshooting) on the first visit could reduce the repeat-ticket rate and cut down the support workload this project already flagged in earlier stages.




