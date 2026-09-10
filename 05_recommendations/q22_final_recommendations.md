# Q22: Final Business Recommendations
## Airtel Home Broadband — Customer Churn Analysis

---

## Executive Summary

Across 21 SQL-based analyses spanning data cleaning, business analysis, cohort behavior, and advanced window-function techniques, this project examined why Airtel router-based home broadband subscribers cancel. The headline finding is that **churn is not driven by any single obvious lever** — plan type, region, and support-ticket volume all show weak or counter-intuitive relationships with cancellation. Instead, the strongest signals are **customer tenure** (newer 2026 cohorts retain worse and are worth far less than older customers) and **engagement decay** (unresolved tickets combined with login inactivity), while revenue itself has been flat for two years rather than growing. A recurring theme across multiple queries is that **the underlying data — particularly payments and logins — has completeness and quality issues** that limit how confidently some patterns can be acted on; this report flags those limitations explicitly rather than overstating certainty.

---

## Key Findings

**1. Retention, not acquisition, is the core problem.**
2026 signup cohorts show materially lower retention than earlier cohorts (Q11), even though new customers generate 5–6x more value per customer in their early months than older customers do on average (Q12). Airtel is acquiring valuable customers and then losing them faster than before.

**2. Plan type and region are not reliable churn predictors.**
Premium and Basic plans show similar churn rates (Q7), and while the "Unknown" region shows the highest churn (50.8%, Q6), this is most likely a data-labeling artifact rather than a true geographic effect — customers with missing region data may simply be under-served in other ways not captured here. Support ticket volume also shows no strong correlation with churn (Q10). **Churn appears to be driven by service/engagement quality, not customer segment.**

**3. Engagement decay is a real, measurable warning sign — but with caveats.**
Early login activity doesn't predict better retention (Q13), but a combination of unresolved support tickets and extended login inactivity flags 28.9% of currently active customers as at-risk (Q16). Login *failure* rates, however, are high across every device and channel alike (56–59%, Q18) — this points to a systemic authentication problem, not device-specific bugs, and means some "inactive" customers may actually be customers who tried and failed to log in, not customers who disengaged voluntarily.

**4. Revenue has been flat, not growing, for two years.**
Monthly revenue and its running total (Q17), and month-over-month change (Q19), both show volatility without any upward trend across the full observed period. The business is not currently compounding customer value over time at the portfolio level.

**5. Repeat support tickets suggest incomplete first-contact resolution.**
Customers who file more than one ticket do so an average of ~220 days apart, but "Slow Speed" issues recur fastest among all issue types (Q21) — suggesting these are often patched rather than permanently fixed on the first visit.

---

## Recommendations

| Priority | Recommendation | Supporting Evidence |
|---|---|---|
| **High** | Build a proactive retention workflow for the 28.9% of active customers flagged as at-risk, prioritizing those with multiple active subscriptions (a single account can represent 2+ at-risk lines) | Q16 |
| **High** | Investigate the login authentication system at the platform level — a ~57% failure rate across all devices is too high and too uniform to be device-specific | Q18 |
| **Medium** | Shift retention strategy focus from "why do customers leave" (weak signals from plan/region/tickets) to "why do 2026 cohorts retain worse than earlier ones" — investigate onboarding, pricing changes, or service quality shifts specific to recent signups | Q11, Q12 |
| **Medium** | Add a technician-verification follow-up specifically for "Slow Speed" tickets a few days after closing, given their high repeat rate | Q21 |
| **Low** | Treat month-over-month revenue swings as noise, not signal — use rolling 3-month averages for trend reporting instead of single-month comparisons | Q19 |

---

## Data Quality Note

Several findings in this project surfaced **data completeness issues that should be resolved before any of these recommendations are acted on with full confidence**:

- The `payments` table shows payment gaps of 45+ days on ~77% of records (Q20), and individual customer payment histories often contain only 2–3 records across 2+ years of subscription — this table likely reflects a **sample of transactions rather than a complete billing ledger**, and should not be used alone to infer individual payment/churn behavior.
- Negative-day and future-dated anomalies appear independently in cancellation timing (Q9), login recency (Q14), and the payments running total (Q17, Q19) — this is a **systemic date-parsing or data-entry issue**, not several unrelated bugs, and is worth a root-cause fix rather than per-query workarounds.
- ~22% of login records have no recorded status, and were excluded from the Q18 failure-rate calculation — the true failure rate could shift if these records are not evenly distributed.

Reporting these limitations transparently, rather than smoothing over them, was a deliberate choice throughout this project.

---

## Technical Approach

This project was built entirely in BigQuery Standard SQL, using:
- **A single cleaned source of truth** (`v_master_clean`) combining five raw tables, with deduplication via `ROW_NUMBER()`, multi-format date parsing via `SAFE.PARSE_DATE`/`SAFE.PARSE_DATETIME`, and pre-aggregation in CTEs to avoid join fan-out
- **Window functions** — `RANK()` for ranked leaderboards and risk scoring, `SUM() OVER()` for running totals, `LAG()`/`LEAD()` for period-over-period and per-customer sequential analysis
- **Cohort analysis** using signup-date grouping to track retention and revenue by customer vintage

Full SQL for all 22 questions is available in this repository, organized by analysis stage.
