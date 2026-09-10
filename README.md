# Airtel Customer Churn Analysis

A SQL/BigQuery portfolio project analyzing why Airtel router-based home broadband subscribers cancel — from raw, messy source data through to formal business recommendations.

**22 business questions, organized across 5 analysis stages, built entirely in BigQuery Standard SQL.**

---

## Project Overview

This project simulates a real-world analyst workflow: starting with five intentionally messy source tables (inconsistent text formatting, mixed date formats, duplicate records, missing values), building a single reliable source of truth, and progressively answering harder business questions — ending in a set of prioritized, evidence-backed recommendations.

**Key finding:** Churn isn't driven by any single obvious factor — plan type, region, and support-ticket volume all show weak relationships with cancellation. The stronger signals are customer tenure (newer cohorts retain worse) and engagement decay (unresolved tickets + login inactivity). Several findings also surfaced genuine data completeness issues, which are reported transparently rather than glossed over. See [`05_recommendations/q22_final_recommendations.md`](./05_recommendations/q22_final_recommendations.md) for the full write-up.

---

## Repository Structure

| Folder | Questions | Focus |
|---|---|---|
| [`01_data_cleaning/`](./01_data_cleaning) | Q1–Q5 | Data quality audit, deduplication, text standardization, multi-format date parsing, and building `v_master_clean` — a single cleaned view combining all five source tables |
| [`02_business_analysis/`](./02_business_analysis) | Q6–Q10 | Churn by region and plan, revenue trends, time-to-cancellation, support tickets vs. churn |
| [`03_cohort_analysis/`](./03_cohort_analysis) | Q11–Q14 | Signup-cohort retention and revenue, login engagement and its relationship to retention |
| [`04_advanced_queries/`](./04_advanced_queries) | Q15–Q21 | Window functions: `RANK()` for leaderboards and risk scoring, running totals, `LAG()`/`LEAD()` for period-over-period and sequential analysis |
| [`05_recommendations/`](./05_recommendations) | Q22 | Final one-page business recommendation summary tying every finding together |

Each question follows the same structure: **Business Question → SQL → Screenshot → Insight → Recommendation**.

---

## Tools & Techniques

- **BigQuery Standard SQL** — the entire project runs on Google Cloud's BigQuery Sandbox
- **Data cleaning:** `ROW_NUMBER()` for deduplication, `SAFE.PARSE_DATE`/`SAFE.PARSE_DATETIME` with `COALESCE()` to handle 5 different date formats, `REGEXP_REPLACE` and `INITCAP` for text standardization
- **Join strategy:** pre-aggregating in CTEs before joining to avoid row fan-out, keeping `v_master_clean` at a clean one-row-per-subscription grain
- **Window functions:** `RANK()`, `SUM() OVER()` for running totals, `LAG()` and `LEAD()` for gap detection and sequential comparisons
- **Cohort analysis:** grouping by signup month to compare retention and revenue across customer vintages

---

## A Note on Data Honesty

Several results in this project contradicted initial assumptions — for example, Premium and Basic plans show similar churn rates (Q7), support ticket volume doesn't strongly predict churn (Q10), and early login activity doesn't predict better retention (Q13). Rather than reframing these to fit a cleaner narrative, they're reported as found. The project also surfaces genuine data quality issues along the way — including a payments table that appears to capture only a sample of transactions rather than a complete billing history (Q20) — and treats those as findings in their own right, not just obstacles to work around.

---

## Author

Yasinta — transitioning from Sales & Marketing (Airtel Tanzania) into Data Analytics.
