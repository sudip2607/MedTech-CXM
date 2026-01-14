# Column-Level Lineage - Quick Reference Guide

## 🎯 What is Column-Level Lineage?

Column-level lineage tracks **how individual columns flow** from source tables through transformations to final reporting tables. Unlike table-level lineage (which only shows model dependencies), column-level lineage shows:

- ✅ Which source columns feed into each output column
- ✅ How columns are transformed (filtered, aggregated, calculated)
- ✅ Which models use each column
- ✅ Data types and transformations applied

---

## 📊 MS TOC Workflow - Column Flow Summary

### Overview
```
SOURCES (13 tables)
    ↓
BASE MODELS (5 models - foundation)
    ├── int_cntrct_rcnt_period (contract scope)
    ├── int_cntrct_compli_period_toc (latest period)
    ├── int_cntrct_compli_period_anltcs (all periods)
    ├── int_cntrct_tier_components_ms (MS tiers)
    └── int_cntrct_tier_components_nms (NMS tiers)
    ↓
INPUT MODELS (4 models - eligibility filtering)
    ├── int_cntrct_elgbl_cust_ms_toc (eligible customers)
    ├── int_cntrct_qual_prod_ms_toc (qualified products)
    ├── int_cntrct_prod_cntrctd_prc_ms_toc (pricing)
    └── int_cntrct_sls_ms_toc (filtered sales)
    ↓
FACT MODELS (2 models - aggregation)
    ├── int_cntrct_fct_tr_idn_ms_toc (IDN-level sales)
    └── int_cntrct_fct_tr_fclty_ms_toc (facility-level sales)
    ↓
VALIDATION MODELS (4 models - compliance metrics)
    ├── int_cntrct_cmplnc_vldtn_idn_ms_toc (IDN %)
    ├── int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc (IDN tier + rebate)
    ├── int_cntrct_cmplnc_vldtn_fclty_ms_toc (facility %)
    └── int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc (facility tier + rebate)
    ↓
COMPREHENSIVE FACT (1 model - unified view)
    └── int_cntrct_cmprhnsv_fct_tr_ms_toc (all metrics combined)
    ↓
MART (1 model - reporting)
    └── mart_cntrct_ms_toc (final BI table)
```

---

## 🔍 Column Tracking Examples

### Example 1: Contract ID (`cntrc_id`)
**Flow:** Source → All 17 models → Mart

```
dim_cntrc.cntrc_id (source)
  ↓ (primary key filter)
int_cntrct_rcnt_period.cntrc_id
  ↓ (join to tier definition)
int_cntrct_tier_components_ms.cntrc_id
  ↓ (join to eligibility)
int_cntrct_elgbl_cust_ms_toc.cntrc_id
  ↓ (filter to sales)
int_cntrct_sls_ms_toc.cntrc_id
  ↓ (group by in aggregation)
int_cntrct_fct_tr_idn_ms_toc.cntrc_id
  ↓ (pass through validation)
int_cntrct_cmplnc_vldtn_idn_ms_toc.cntrc_id
  ↓ (pass through tier assignment)
int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.cntrc_id
  ↓ (union in comprehensive)
int_cntrct_cmprhnsv_fct_tr_ms_toc.cntrc_id
  ↓ (pass to mart)
mart_cntrct_ms_toc.cntrc_id
```

**Impact:** This column determines the contract scope at all levels. Any filtering here affects entire pipeline.

### Example 2: Sales Amount (`sls_amt`)
**Transformation Pattern:** Source → Filter → Aggregate → Calculate

```
fct_sls_trn.sls_amt (transaction-level source)
  ↓ (filter to eligible customers & products)
int_cntrct_sls_ms_toc.sls_amt
  ↓ (aggregate to IDN level)
int_cntrct_fct_tr_idn_ms_toc:
  qual_sls_amt = SUM(sls_amt WHERE product qualified)
  tot_sls_amt = SUM(sls_amt ALL)
  ↓ (use in calculation)
int_cntrct_cmplnc_vldtn_idn_ms_toc:
  ms_pct = (qual_sls_amt / tot_sls_amt) * 100
  ↓ (use for tier assignment)
int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc:
  rebate_amt = qual_sls_amt * (rebate_pct / 100)
  ↓ (sum in comprehensive)
int_cntrct_cmprhnsv_fct_tr_ms_toc:
  qual_sls_amt, tot_sls_amt, idn_rebate
  ↓ (report)
mart_cntrct_ms_toc
```

**Impact:** Single source column drives aggregations and calculations. Data quality at source affects all downstream metrics.

### Example 3: Tier Boundaries (`tier_min_pct`, `tier_max_pct`)
**Transformation Pattern:** Source → Lookup → Assignment → Report

```
dim_prc_prg_cmpnt.tier_min_pct (tier definition)
dim_prc_prg_cmpnt.tier_max_pct (tier definition)
  ↓ (filter to MS tiers only)
int_cntrct_tier_components_ms:
  tier_min_pct (tier range)
  tier_max_pct (tier range)
  ↓ (used in join condition)
int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc:
  (WHERE ms_pct BETWEEN tier_min_pct AND tier_max_pct)
  ↓ (determines rebate rate)
rebate_pct (from tier match)
  ↓ (used in calculation)
rebate_amt = qual_sls_amt * (rebate_pct / 100)
  ↓ (sum to comprehensive)
int_cntrct_cmprhnsv_fct_tr_ms_toc:
  idn_rebate, fclty_rebate, tot_rebate
  ↓ (report)
mart_cntrct_ms_toc
```

**Impact:** Tier definitions are business rules. Changes here cascade to all rebate calculations.

---

## 📋 Column Categories in MS TOC Workflow

### Category 1: Dimensional Columns (Identifiers)
- `cntrc_id`, `prc_prg_id`, `cmpnt_id`, `cmt_cust_id`, `idn_id`, `fclty_id`, `prod_id`
- **Flow:** Pass through all layers unchanged
- **Purpose:** Grouping, filtering, joins
- **Impact:** High - affect aggregation granularity

### Category 2: Filtering Columns
- `cntrc_sts`, `tier_basis_type`, `elig_st_dt`, `elig_end_dt`, `qual_st_dt`, `qual_end_dt`
- **Flow:** Used for WHERE clauses, then pass through
- **Purpose:** Scope reduction
- **Impact:** Very High - reduce candidate set at each layer

### Category 3: Factual Columns (Measures)
- `sls_amt`, `qty`, `cntrctd_prc`, `lst_prc`
- **Flow:** Aggregated via SUM
- **Purpose:** Basis for calculations
- **Impact:** Very High - drive all metrics

### Category 4: Business Rule Columns
- `tier_num`, `tier_min_pct`, `tier_max_pct`, `rebate_pct`
- **Flow:** Used in joins and calculations
- **Purpose:** Define tiers and rebate rates
- **Impact:** Very High - business logic enforcement

### Category 5: Calculated Columns
- `ms_pct`, `qual_sls_amt`, `tot_sls_amt`, `rebate_amt`, `tot_rebate`, `overall_ms_pct`
- **Flow:** Derived from other columns, pass through downstream
- **Purpose:** Key metrics for reporting
- **Impact:** Medium-High - only in downstream models

### Category 6: Descriptive Columns
- `cntrc_nm`, `cmpnt_nm`, `idn_nm`, `fclty_nm`, `cust_nm`, `prc_prg_nm`
- **Flow:** Passed through for reporting
- **Purpose:** Human-readable labels
- **Impact:** Low - reporting only

---

## 🔗 Critical Column Dependencies

### Dependency 1: Compliance Period
```
Depends On:     int_cntrct_compli_period_toc
Used By:        • int_cntrct_elgbl_cust_ms_toc (per_strt_dt, per_end_dt)
                • int_cntrct_qual_prod_ms_toc (per_strt_dt, per_end_dt)
                • All fact tables (per_strt_dt, per_end_dt)
                • Comprehensive fact (compli_per_strt_dt, compli_per_end_dt)
Impact:         Changes to period definition affect all time-based filtering
```

### Dependency 2: Tier Definitions
```
Depends On:     int_cntrct_tier_components_ms
Used By:        • Input models (inner join for scope)
                • Validation models (tier_min_pct, tier_max_pct for joins)
                • Ranked models (rebate_pct for calculation)
                • Comprehensive fact (cmpnt_nm lookup)
Impact:         Tier changes flow to all rebate calculations
```

### Dependency 3: Sales Transactions
```
Depends On:     fct_sls_trn
Used By:        • int_cntrct_sls_ms_toc (filter to eligible items)
                • Fact tables (aggregation source)
                • Validation models (ms_pct calculation)
Impact:         Sales data quality determines all downstream metrics
```

### Dependency 4: Eligibility Lists
```
Depends On:     • dim_prc_cmpnt_cust_elig
                • dim_prc_cmpnt_qual_prod
Used By:        • int_cntrct_sls_ms_toc (inner joins)
Impact:         Eligibility rules directly filter which sales are counted
```

---

## 📊 Column Lineage by Model

### Base Models Column Sources
| Model | Key Columns | Source Tables | Transform |
|-------|---|---|---|
| `int_cntrct_rcnt_period` | cntrc_id, cntrc_sts, cntrc_strt_dt, cntrc_end_dt | dim_cntrc | Filter: recent 24-mo |
| `int_cntrct_compli_period_toc` | per_strt_dt, per_end_dt, rnk_val | dim_prc_prg_cmpli_per_rslts | Filter: rank=1 |
| `int_cntrct_tier_components_ms` | tier_num, tier_min_pct, tier_max_pct, rebate_pct | dim_prc_prg_cmpnt | Filter: = 'MARKET SHARE' |

### Input Models Column Sources
| Model | Key Columns | Source Tables | Transform |
|-------|---|---|---|
| `int_cntrct_elgbl_cust_ms_toc` | cmt_cust_id, elig_st_dt, elig_end_dt | dim_prc_cmpnt_cust_elig | Inner join: tiers + period |
| `int_cntrct_qual_prod_ms_toc` | prod_id, qual_st_dt, qual_end_dt | dim_prc_cmpnt_qual_prod | Inner join: tiers + period |
| `int_cntrct_sls_ms_toc` | sls_amt, qty, sls_dt | fct_sls_trn | Filter to: eligible + qualified |

### Fact Models Column Sources
| Model | Calculations | Grouping |
|-------|---|---|
| `int_cntrct_fct_tr_idn_ms_toc` | qual_sls_amt = SUM(sls_amt) | cntrc, cmpnt, idn |
| `int_cntrct_fct_tr_fclty_ms_toc` | qual_sls_amt = SUM(sls_amt) | cntrc, cmpnt, fclty |

### Validation Models Column Calculations
| Model | Formula | Output |
|-------|---|---|
| `int_cntrct_cmplnc_vldtn_idn_ms_toc` | ms_pct = (qual/tot) * 100 | Market share % |
| `int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc` | rebate_amt = qual * (rate/100) | Rebate amount |

---

## 🚀 How to Use This Documentation

### For Data Engineers
1. **Validate Changes:** Use the flow diagrams to understand impact of schema changes
2. **Optimize Queries:** Understand which columns need indexes (frequently joined/filtered)
3. **Debug Issues:** Trace column values through the flow to find transformation errors

### For BI Analysts
1. **Understand Metrics:** Know which source columns feed each reporting column
2. **Data Quality:** Identify upstream tables responsible for data quality issues
3. **Historical Analysis:** Understand when metrics changed (schema vs. data)

### For Business Users
1. **Metric Definitions:** Understand how metrics are calculated
2. **Impact Analysis:** See how business rule changes affect metrics
3. **Audit Trail:** Know where each number in the report comes from

---

## 📄 Documentation Files Generated

1. **[COLUMN_LINEAGE.md](./COLUMN_LINEAGE.md)**
   - Detailed column-by-column lineage
   - Transformations at each layer
   - SQL column references

2. **[COLUMN_LINEAGE_FLOW_DIAGRAM.md](./COLUMN_LINEAGE_FLOW_DIAGRAM.md)**
   - Visual ASCII diagrams
   - Data flow visualization
   - Transformation patterns

3. **[COLUMN_LINEAGE_QUICK_REFERENCE.md](./COLUMN_LINEAGE_QUICK_REFERENCE.md)** ← You are here
   - Quick lookup guide
   - Category summaries
   - Critical dependencies

---

## 🔄 Accessing Column Lineage in dbt

### In dbt Docs (http://localhost:8000)
1. Open dbt documentation site
2. Click on any model
3. Scroll to **Columns** section
4. Each column shows:
   - Column name and type
   - Description with lineage annotation
   - Source columns it derives from

### In dbt YAML Files
All column lineage is documented in:
- `models/staging/_sources.yml` (source columns)
- `models/intermediate/base/_base.yml` (base model lineage)
- `models/intermediate/ms_toc/_ms_toc.yml` (intermediate lineage)
- `models/marts/contract_compliance/_contract_compliance.yml` (mart lineage)

Each column has description in format:
```yaml
- name: column_name
  description: 'Column description - SOURCE LINEAGE: source_table.source_column → transformation → output'
```

---

## 📈 Next Steps

### Immediate
- ✅ Review column lineage in dbt docs at http://localhost:8000
- ✅ Test a model query to validate column flows
- ✅ Share documentation with data consumers

### Short Term
- ⏳ Create column-level lineage for MS ANLTCS workflow
- ⏳ Document NMS TOC and NMS ANLTCS workflows
- ⏳ Add data quality checks for critical columns

### Medium Term
- ⏳ Implement dbt tests for column transformations
- ⏳ Create automated data lineage reports
- ⏳ Build impact analysis tools

---

## 📞 Questions?

Refer to the comprehensive documentation:
1. **Detailed Lineage:** See [COLUMN_LINEAGE.md](./COLUMN_LINEAGE.md)
2. **Visual Flows:** See [COLUMN_LINEAGE_FLOW_DIAGRAM.md](./COLUMN_LINEAGE_FLOW_DIAGRAM.md)
3. **dbt Docs:** http://localhost:8000 (interactive lineage viewer)

