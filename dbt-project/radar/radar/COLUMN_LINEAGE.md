# Column-Level Lineage Documentation
## Market Share Time-of-Compliance (MS TOC) Workflow

**Generated:** January 14, 2026  
**Workflow:** MS TOC (Market Share Time-of-Compliance)  
**Tracking:** Source → Base → Intermediate → Fact → Validation → Comprehensive → Mart

---

## 1. Source Layer (md_dwh Schema)

### Critical Source Tables & Column Mappings

#### `dim_cntrc` (Contract Master)
**Purpose:** Base contract information and program links
```
Columns flowing downstream:
├── cntrc_id          → All models (primary identifier)
├── cntrc_nm          → Comprehensive fact & mart
├── cntrc_sts         → Base model filtering (recent periods)
├── prc_prg_id        → All models (program link)
├── cntrc_strt_dt     → Base model window calculation
└── cntrc_end_dt      → Base model window calculation
```

#### `dim_prc_prg_cmpli_per_rslts` (Compliance Periods)
**Purpose:** Historical and latest compliance period definitions
```
Columns flowing downstream:
├── cntrc_id          → All compliance-based models
├── prc_prg_id        → All models
├── cmt_cust_id       → Customer-level calculations (nullable)
├── cmpnt_id          → Component-level metrics
├── per_strt_dt       → Fact tables & mart
├── per_end_dt        → Fact tables & mart
├── per_num           → Analytics workflow (historical periods)
└── rnk_val           → TOC filtering (rank=1 for most recent)
```

#### `dim_prc_prg_cmpnt` (Component Tiers)
**Purpose:** Tier definitions and rebate structures
```
Columns flowing downstream:
├── prc_prg_id        → Tier base models
├── cmpnt_id          → All component-based filtering
├── cmpnt_nm          → Intermediate & comprehensive fact
├── tier_basis_type   → MS vs NMS tier separation (MARKET SHARE | OTHER)
├── tier_num          → Validation models → Ranked models
├── tier_min_pct      → Ranked models (MS tiers)
├── tier_max_pct      → Ranked models (MS tiers)
├── tier_min_val      → Ranked models (NMS tiers)
├── tier_max_val      → Ranked models (NMS tiers)
└── rebate_pct        → Rebate calculation in ranked models
```

#### `dim_prc_cmpnt_cust_elig` (Customer Eligibility)
**Purpose:** Which customers qualify for each component
```
Columns flowing downstream:
├── cmpnt_id          → Eligible customers intermediate
├── prc_prg_id        → Intermediate filtering
├── cmt_cust_id       → Sales filtering & transaction level
├── elig_st_dt        → Comprehensive fact
└── elig_end_dt       → Comprehensive fact
```

#### `dim_prc_cmpnt_qual_prod` (Qualified Products)
**Purpose:** Which products qualify for each component
```
Columns flowing downstream:
├── cmpnt_id          → Qualified products intermediate
├── prc_prg_id        → Intermediate filtering
├── prod_id           → Sales filtering & transaction level
├── prod_ctgry_id     → Optional categorization
├── qual_st_dt        → Comprehensive fact
└── qual_end_dt       → Comprehensive fact
```

#### `fct_prc_cmpnt_prod_cntrctd` (Contracted Pricing)
**Purpose:** Price points for qualified products
```
Columns flowing downstream:
├── cmpnt_id          → Pricing intermediate
├── prod_id           → Transaction matching
├── cntrctd_prc       → Optional pricing validation
├── lst_prc           → Optional discount calculation
└── dscnt_pct         → Optional discount tracking
```

#### `fct_sls_trn` (Sales Transactions)
**Purpose:** Individual transaction-level sales data
```
Columns flowing downstream:
├── sls_trn_id        → Sales intermediate (transaction key)
├── cmt_cust_id       → Eligibility filtering
├── prod_id           → Product qualification filtering
├── idn_id            → IDN-level aggregation
├── fclty_id          → Facility-level aggregation
├── sls_amt           → Amount aggregations in fact tables
├── qty               → Quantity tracking
└── sls_dt            → Period filtering & analysis
```

#### `dim_cmt_cust` (Customer Master)
**Purpose:** Customer hierarchy and attributes
```
Columns flowing downstream:
├── cmt_cust_id       → Customer-to-IDN/facility mapping
├── cust_nm           → Optional reporting
├── idn_id            → IDN fact table joins
└── fclty_id          → Facility fact table joins
```

#### `dim_idn` (IDN Dimension)
**Purpose:** IDN grouping and attributes
```
Columns flowing downstream:
├── idn_id            → IDN fact table grouping & comprehensive fact
└── idn_nm            → Reporting & mart
```

#### `dim_fclty` (Facility Dimension)
**Purpose:** Facility-level attributes
```
Columns flowing downstream:
├── fclty_id          → Facility fact table grouping & comprehensive fact
└── fclty_nm          → Reporting & mart
```

---

## 2. Base Model Layer (Foundation Models)

### `int_cntrct_rcnt_period`
**Purpose:** 24-month rolling window of recent contracts  
**Transformation:** Filter + Window calculation

```
Source → Base
dim_cntrc columns:
  ├── cntrc_id
  ├── cntrc_nm
  ├── cntrc_sts (filter: cntrc_sts = 'Active')
  ├── prc_prg_id
  ├── cntrc_strt_dt
  └── cntrc_end_dt

↓ All downstream models depend on this for contract scope
```

### `int_cntrct_compli_period_toc`
**Purpose:** Latest compliance period per contract/component  
**Transformation:** Rank + Filter (rank=1) + Window function

```
dim_prc_prg_cmpli_per_rslts columns:
  ├── cntrc_id (join to int_cntrct_rcnt_period)
  ├── prc_prg_id
  ├── cmt_cust_id (nullable for contract-level)
  ├── cmpnt_id
  ├── per_strt_dt (flows to all downstream)
  ├── per_end_dt (flows to all downstream)
  ├── rnk_val (filter: rnk_val = 1)
  └── rank_scope

↓ Used by: elgbl_cust, qual_prod, prod_cntrctd_prc, fct_* tables, validation models
```

### `int_cntrct_compli_period_anltcs`
**Purpose:** All historical compliance periods (no filtering)  
**Transformation:** Direct pass-through for time-series analysis

```
dim_prc_prg_cmpli_per_rslts columns:
  ├── cntrc_id
  ├── prc_prg_id
  ├── cmt_cust_id
  ├── cmpnt_id
  ├── per_strt_dt
  ├── per_end_dt
  └── per_num

↓ Used by: MS ANLTCS workflow (future)
```

### `int_cntrct_tier_components_ms`
**Purpose:** Market Share tier definitions only  
**Transformation:** Filter + Join to recent contracts

```
dim_prc_prg_cmpnt columns:
  ├── prc_prg_id
  ├── cmpnt_id
  ├── cmpnt_nm (flows to comprehensive fact & mart)
  ├── tier_basis_type (filter: = 'MARKET SHARE')
  ├── tier_num (flows to validation/ranked models)
  ├── tier_min_pct (flows to ranked models for tier assignment)
  ├── tier_max_pct (flows to ranked models for tier assignment)
  └── rebate_pct (flows to ranked models for rebate calc)

WITH int_cntrct_rcnt_period:
  └── cntrc_id (join condition)

↓ Used by: All MS TOC input, fact, and validation models
```

### `int_cntrct_tier_components_nms`
**Purpose:** Non-Market Share tier definitions  
**Transformation:** Filter + Join to recent contracts

```
dim_prc_prg_cmpnt columns:
  ├── prc_prg_id
  ├── cmpnt_id
  ├── cmpnt_nm
  ├── tier_basis_type (filter: != 'MARKET SHARE')
  ├── tier_num
  ├── tier_min_val (flows to NMS validation models)
  ├── tier_max_val (flows to NMS validation models)
  └── rebate_pct

WITH int_cntrct_rcnt_period:
  └── cntrc_id

↓ Used by: NMS TOC & NMS ANLTCS workflows (future)
```

---

## 3. Input/Eligibility Layer (Level 1.1.1)

### `int_cntrct_elgbl_cust_ms_toc`
**Purpose:** Filter customers eligible for component  
**Transformation:** Inner joins: eligibility + tiers + compliance period

```
Source columns:
  dim_prc_cmpnt_cust_elig:
    ├── cmpnt_id
    ├── prc_prg_id
    ├── cmt_cust_id (flows to sales filtering)
    ├── elig_st_dt (flows to comprehensive fact)
    └── elig_end_dt (flows to comprehensive fact)

Base model references:
  int_cntrct_tier_components_ms:
    ├── cntrc_id (inner join → output)
    └── prc_prg_id
  
  int_cntrct_compli_period_toc:
    ├── per_strt_dt (inner join → comprehensive fact)
    └── per_end_dt (inner join → comprehensive fact)

↓ Output: List of (cntrc_id, cmt_cust_id, cmpnt_id) triplets
↓ Used by: int_cntrct_sls_ms_toc (filtering)
```

### `int_cntrct_qual_prod_ms_toc`
**Purpose:** Filter products qualified for component  
**Transformation:** Inner joins: qualified products + tiers + compliance period

```
Source columns:
  dim_prc_cmpnt_qual_prod:
    ├── cmpnt_id
    ├── prc_prg_id
    ├── prod_id (flows to sales filtering)
    ├── prod_ctgry_id (optional output)
    ├── qual_st_dt
    └── qual_end_dt

Base model references:
  int_cntrct_tier_components_ms:
    ├── cntrc_id (inner join → output)
    └── cmpnt_id
  
  int_cntrct_compli_period_toc:
    ├── per_strt_dt
    └── per_end_dt

↓ Output: List of (cntrc_id, prod_id, cmpnt_id) triplets
↓ Used by: int_cntrct_sls_ms_toc (filtering)
```

### `int_cntrct_prod_cntrctd_prc_ms_toc`
**Purpose:** Get pricing for qualified products  
**Transformation:** Join pricing facts + tiers + compliance period

```
Source columns:
  fct_prc_cmpnt_prod_cntrctd:
    ├── cmpnt_id
    ├── prod_id
    ├── cntrctd_prc (optional validation)
    ├── lst_prc (optional discount calc)
    └── dscnt_pct (optional tracking)

Base model references:
  int_cntrct_compli_period_toc:
    ├── cntrc_id → output
    ├── prc_prg_id → output
    └── cmpnt_id

  int_cntrct_tier_components_ms:
    └── cmpnt_id (join condition)

↓ Output: Price lookup for qualified products
↓ Used by: Optional price validation in fact tables
```

### `int_cntrct_sls_ms_toc`
**Purpose:** Filter sales to eligible customers and qualified products  
**Transformation:** Transaction-level joins to eligibility lists

```
Source columns:
  fct_sls_trn:
    ├── sls_trn_id (flows as transaction identifier)
    ├── cmt_cust_id (inner join → int_cntrct_elgbl_cust)
    ├── prod_id (inner join → int_cntrct_qual_prod)
    ├── idn_id (flows to IDN fact table)
    ├── fclty_id (flows to facility fact table)
    ├── sls_amt (flows to aggregations)
    ├── qty (flows to aggregations)
    └── sls_dt (flows to fact tables)

  dim_cmt_cust:
    ├── cmt_cust_id (join condition)
    ├── idn_id (flows to aggregation)
    └── fclty_id (flows to aggregation)

Input model references:
  int_cntrct_elgbl_cust_ms_toc:
    └── (cntrc_id, cmt_cust_id, cmpnt_id) → inner join
  
  int_cntrct_qual_prod_ms_toc:
    └── (cntrc_id, prod_id, cmpnt_id) → inner join

↓ Output: Filtered transaction stream
↓ Used by: int_cntrct_fct_tr_idn_ms_toc, int_cntrct_fct_tr_fclty_ms_toc
```

---

## 4. Fact/Aggregation Layer (Level 1.1.1.1)

### `int_cntrct_fct_tr_idn_ms_toc`
**Purpose:** Aggregate sales to IDN level  
**Transformation:** Group by (cntrc_id, prc_prg_id, cmpnt_id, idn_id)

```
Input from int_cntrct_sls_ms_toc:
  ├── cntrc_id (group by)
  ├── prc_prg_id (group by)
  ├── cmpnt_id (group by)
  ├── idn_id (group by)
  ├── sls_amt (SUM → qual_sls_amt & tot_sls_amt)
  └── qty (SUM → optional qty tracking)

Source from dim_idn:
  └── idn_nm (descriptive join)

Base model from int_cntrct_compli_period_toc:
  ├── per_strt_dt (flows through)
  └── per_end_dt (flows through)

Calculations:
  qual_sls_amt = SUM(sls_amt WHERE product qualified)
  tot_sls_amt = SUM(sls_amt) [all sales]

↓ Output: IDN-level aggregated fact table
↓ Used by: int_cntrct_cmplnc_vldtn_idn_ms_toc
```

### `int_cntrct_fct_tr_fclty_ms_toc`
**Purpose:** Aggregate sales to facility level  
**Transformation:** Group by (cntrc_id, prc_prg_id, cmpnt_id, fclty_id)

```
Input from int_cntrct_sls_ms_toc:
  ├── cntrc_id (group by)
  ├── prc_prg_id (group by)
  ├── cmpnt_id (group by)
  ├── fclty_id (group by)
  ├── sls_amt (SUM → qual_sls_amt & tot_sls_amt)
  └── qty (SUM → optional qty tracking)

Source from dim_fclty:
  └── fclty_nm (descriptive join)

Base model from int_cntrct_compli_period_toc:
  ├── per_strt_dt
  └── per_end_dt

Calculations:
  qual_sls_amt = SUM(sls_amt WHERE product qualified)
  tot_sls_amt = SUM(sls_amt)

↓ Output: Facility-level aggregated fact table
↓ Used by: int_cntrct_cmplnc_vldtn_fclty_ms_toc
```

---

## 5. Validation/Compliance Layer (Level 1.1.1.1.1)

### `int_cntrct_cmplnc_vldtn_idn_ms_toc`
**Purpose:** Calculate market share % at IDN level  
**Transformation:** Market share calculation from aggregated facts

```
Input from int_cntrct_fct_tr_idn_ms_toc:
  ├── cntrc_id (pass through)
  ├── prc_prg_id (pass through)
  ├── cmpnt_id (pass through)
  ├── idn_id (pass through)
  ├── idn_nm (pass through)
  ├── qual_sls_amt (used in calculation)
  └── tot_sls_amt (used in calculation)

Calculation:
  ms_pct = (qual_sls_amt / tot_sls_amt) * 100

↓ Output: IDN market share percentage
↓ Used by: int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
```

### `int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc`
**Purpose:** Assign tier and calculate rebate at IDN level  
**Transformation:** Tier join + rebate calculation

```
Input from int_cntrct_cmplnc_vldtn_idn_ms_toc:
  ├── cntrc_id (pass through → comprehensive)
  ├── prc_prg_id (pass through → comprehensive)
  ├── cmpnt_id (pass through → comprehensive)
  ├── idn_id (pass through → comprehensive)
  ├── idn_nm (pass through → comprehensive)
  ├── ms_pct (used for tier join)
  ├── qual_sls_amt (used in rebate calc)
  └── tot_sls_amt (pass through)

Base model int_cntrct_tier_components_ms:
  ├── tier_num (join: WHERE ms_pct BETWEEN tier_min_pct AND tier_max_pct)
  ├── tier_min_pct (join condition & output)
  ├── tier_max_pct (join condition & output)
  └── rebate_pct (used in calculation)

Calculations:
  tier_num = Match ms_pct to tier ranges
  rebate_amt = qual_sls_amt * (rebate_pct / 100)

↓ Output: IDN with tier assignment and rebate amount
↓ Used by: int_cntrct_cmprhnsv_fct_tr_ms_toc (UNION)
```

### `int_cntrct_cmplnc_vldtn_fclty_ms_toc`
**Purpose:** Calculate market share % at facility level  
**Transformation:** Market share calculation from aggregated facts

```
Input from int_cntrct_fct_tr_fclty_ms_toc:
  ├── cntrc_id (pass through)
  ├── prc_prg_id (pass through)
  ├── cmpnt_id (pass through)
  ├── fclty_id (pass through)
  ├── fclty_nm (pass through)
  ├── qual_sls_amt (used in calculation)
  └── tot_sls_amt (used in calculation)

Calculation:
  ms_pct = (qual_sls_amt / tot_sls_amt) * 100

↓ Output: Facility market share percentage
↓ Used by: int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
```

### `int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc`
**Purpose:** Assign tier and calculate rebate at facility level  
**Transformation:** Tier join + rebate calculation

```
Input from int_cntrct_cmplnc_vldtn_fclty_ms_toc:
  ├── cntrc_id (pass through → comprehensive)
  ├── prc_prg_id (pass through → comprehensive)
  ├── cmpnt_id (pass through → comprehensive)
  ├── fclty_id (pass through → comprehensive)
  ├── fclty_nm (pass through → comprehensive)
  ├── ms_pct (used for tier join)
  ├── qual_sls_amt (used in rebate calc)
  └── tot_sls_amt (pass through)

Base model int_cntrct_tier_components_ms:
  ├── tier_num (join: WHERE ms_pct BETWEEN tier_min_pct AND tier_max_pct)
  ├── tier_min_pct (join condition & output)
  ├── tier_max_pct (join condition & output)
  └── rebate_pct (used in calculation)

Calculations:
  tier_num = Match ms_pct to tier ranges
  rebate_amt = qual_sls_amt * (rebate_pct / 100)

↓ Output: Facility with tier assignment and rebate amount
↓ Used by: int_cntrct_cmprhnsv_fct_tr_ms_toc (UNION)
```

---

## 6. Comprehensive Fact Layer (Level 1.1.1.1.1.1)

### `int_cntrct_cmprhnsv_fct_tr_ms_toc`
**Purpose:** Combine IDN and facility-level metrics  
**Transformation:** UNION of IDN and facility ranked validations + component join

```
Input from int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc:
  ├── cntrc_id (UNION → mart)
  ├── prc_prg_id (UNION → mart)
  ├── cmpnt_id (UNION → mart)
  ├── idn_id (UNION → mart / fclty_id = NULL)
  ├── idn_nm (UNION → mart / fclty_nm = NULL)
  ├── ms_pct (idn_ms_pct → mart)
  ├── qual_sls_amt (UNION → mart)
  ├── tot_sls_amt (UNION → mart)
  ├── tier_num (idn_tier → mart)
  └── rebate_amt (idn_rebate → mart)

Input from int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc:
  ├── cntrc_id (UNION → mart)
  ├── prc_prg_id (UNION → mart)
  ├── cmpnt_id (UNION → mart)
  ├── fclty_id (UNION → mart / idn_id = NULL)
  ├── fclty_nm (UNION → mart / idn_nm = NULL)
  ├── ms_pct (fclty_ms_pct → mart)
  ├── qual_sls_amt (UNION → mart)
  ├── tot_sls_amt (UNION → mart)
  ├── tier_num (fclty_tier → mart)
  └── rebate_amt (fclty_rebate → mart)

Base model join int_cntrct_tier_components_ms:
  └── cmpnt_nm (lookup → mart)

Derived calculations:
  overall_ms_pct = (UNION qual_sls_amt / UNION tot_sls_amt) * 100
  tot_rebate = idn_rebate + fclty_rebate

↓ Output: Unified fact table with all metrics
↓ Used by: mart_cntrct_ms_toc
```

---

## 7. Mart/Reporting Layer (Final)

### `mart_cntrct_ms_toc`
**Purpose:** Single source of truth for MS TOC reporting  
**Transformation:** Direct pass-through with all columns

```
Input from int_cntrct_cmprhnsv_fct_tr_ms_toc:
  All columns pass through directly:
  ├── cntrc_id
  ├── prc_prg_id
  ├── cmpnt_id
  ├── cmpnt_nm
  ├── cmt_cust_id (NULL in aggregated view)
  ├── idn_id
  ├── idn_nm
  ├── fclty_id
  ├── fclty_nm
  ├── qual_sls_amt
  ├── tot_sls_amt
  ├── overall_ms_pct
  ├── idn_ms_pct
  ├── fclty_ms_pct
  ├── idn_tier
  ├── fclty_tier
  ├── idn_rebate
  ├── fclty_rebate
  ├── tot_rebate
  ├── compli_per_strt_dt
  └── compli_per_end_dt

↓ Output: Ready for BI/Dashboard consumption
```

---

## Column Lineage Summary Table

| Column Name | Source Table | Base Model | Intermediate | Fact | Validation | Comprehensive | Mart |
|-------------|--------------|-----------|---|---|---|---|---|
| `cntrc_id` | dim_cntrc | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `prc_prg_id` | dim_prc_prg_cmpli_per_rslts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `cmpnt_id` | dim_prc_prg_cmpnt | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `cmpnt_nm` | dim_prc_prg_cmpnt | - | - | - | - | ✓ | ✓ |
| `cmt_cust_id` | dim_prc_cmpnt_cust_elig | - | ✓ | - | - | NULL | NULL |
| `idn_id` | dim_idn | - | - | ✓ | ✓ | ✓ | ✓ |
| `idn_nm` | dim_idn | - | - | ✓ | ✓ | ✓ | ✓ |
| `fclty_id` | dim_fclty | - | - | ✓ | ✓ | ✓ | ✓ |
| `fclty_nm` | dim_fclty | - | - | ✓ | ✓ | ✓ | ✓ |
| `qual_sls_amt` | fct_sls_trn | - | - | SUM | ✓ | ✓ | ✓ |
| `tot_sls_amt` | fct_sls_trn | - | - | SUM | ✓ | ✓ | ✓ |
| `ms_pct` | CALC | - | - | - | CALC | ✓ | ✓ |
| `tier_num` | dim_prc_prg_cmpnt | - | - | - | JOIN | ✓ | ✓ |
| `rebate_amt` | CALC | - | - | - | CALC | ✓ | ✓ |
| `compli_per_strt_dt` | dim_prc_prg_cmpli_per_rslts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| `compli_per_end_dt` | dim_prc_prg_cmpli_per_rslts | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## Key Transformation Patterns

### Pattern 1: Filtering & Scope Reduction
- **Source:** `dim_prc_prg_cmpnt` (all components)
- **Base:** `int_cntrct_tier_components_ms` (MS only via filter)
- **Impact:** Separates MS from NMS workflows early

### Pattern 2: Eligibility Filtering
- **Source:** `dim_prc_cmpnt_cust_elig` (all eligible combinations)
- **Intermediate:** `int_cntrct_elgbl_cust_ms_toc` (inner join contracts)
- **Used by:** `int_cntrct_sls_ms_toc` (filters transactions)
- **Impact:** Applies compliance scope to sales data

### Pattern 3: Aggregation & Calculation
- **Input:** Transaction-level `int_cntrct_sls_ms_toc`
- **Fact:** Grouped to `int_cntrct_fct_tr_idn_ms_toc` (SUM aggregations)
- **Validation:** Converted to `int_cntrct_cmplnc_vldtn_idn_ms_toc` (ms_pct = qual/tot)
- **Impact:** Reduces data volume progressively while enriching metrics

### Pattern 4: Tier Assignment
- **Input:** Market share % from validation layer
- **Tier Join:** Match % to tier ranges via BETWEEN clause
- **Output:** Tier number + rebate percentage
- **Impact:** Business rule enforcement (tier boundaries)

### Pattern 5: UNION for Multi-Level Metrics
- **Input:** Two ranked tables (IDN + facility with different group keys)
- **Comprehensive:** `int_cntrct_cmprhnsv_fct_tr_ms_toc` (UNION both)
- **Output:** Dual-level metrics in single fact table
- **Impact:** Supports hierarchical analysis (IDN & facility simultaneously)

---

## dbt Manifest References

All column-level lineage is captured in:
- **Source Definitions:** `models/staging/_sources.yml`
- **Base Model YAML:** `models/intermediate/base/_base.yml`
- **Intermediate YAML:** `models/intermediate/ms_toc/_ms_toc.yml`
- **Mart YAML:** `models/marts/contract_compliance/_contract_compliance.yml`

To view in dbt docs: http://localhost:8000

---

## Future Workflows (Column Mappings Ready)

The column-level structure supports future workflows:

### MS ANLTCS (uses `int_cntrct_compli_period_anltcs`)
- All column definitions same as MS TOC
- Adds time-series dimension (per_num, all periods vs rank=1)
- Base model: `int_cntrct_compli_period_anltcs`

### NMS TOC (uses `int_cntrct_tier_components_nms`)
- Tier joins on value ranges instead of percentages
- Columns: `tier_min_val`, `tier_max_val` instead of `tier_min_pct`, `tier_max_pct`
- Base model: `int_cntrct_tier_components_nms`

### NMS ANLTCS (combines both)
- Time-series + value-based tiers
- Base models: both `int_cntrct_compli_period_anltcs` and `int_cntrct_tier_components_nms`

