# Column-Level Lineage Flow Diagram
## MS TOC (Market Share Time-of-Compliance) Workflow

```
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

LAYER 0: SOURCES (md_dwh Schema)
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

                    ┌─────────────────────────────────────────────────────────────────────────────┐
                    │ KEY SOURCE TABLES & COLUMN FLOWS                                            │
                    └─────────────────────────────────────────────────────────────────────────────┘

    dim_cntrc              dim_prc_prg_cmpli_per_rslts        dim_prc_prg_cmpnt         dim_prc_cmpnt_cust_elig
    (Contract)            (Compliance Periods)               (Component Tiers)         (Customer Eligibility)
    ┌──────────┐          ┌──────────────────────┐           ┌──────────────────┐      ┌──────────────────┐
    │cntrc_id──┼─────────>│cntrc_id              │           │prc_prg_id────────┼─────>│cmpnt_id          │
    │cntrc_nm  │          │prc_prg_id───────────>│           │cmpnt_id──────────┼─────>│prc_prg_id        │
    │cntrc_sts─┤          │per_strt_dt───────┐   │           │cmpnt_nm──────────┼─────>│cmt_cust_id       │
    │prc_prg_id├─────────>│per_end_dt─────┐  │   │           │tier_basis_type   │      │elig_st_dt        │
    │cntrc_sts │          │rnk_val (=1)───┤  │   │           │tier_num──────────┼───┐  │elig_end_dt       │
    │cntrc_strt│          │rank_scope      │  │   │           │tier_min_pct      │   │  └──────────────────┘
    │cntrc_end │          │cmt_cust_id     │  │   │           │tier_max_pct      │   │
    └──────────┘          │cmpnt_id        │  │   │           │rebate_pct────────┤   │
         │                └──────────────────┘  │   │           └──────────────────┘   │
         │                     │                │   │                 │                │
         └──────────┬──────────┴─────────┬──────┘   │                 └───────────┬────┘
                    │                   │          │                             │
          fct_sls_trn           fct_prc_cmpnt_prod_cntrctd                        │
          (Sales)               (Pricing)                                         │
          ┌──────────────┐      ┌────────────────────┐                          │
          │sls_trn_id    │      │cmpnt_id            │                          │
          │cmt_cust_id───┼─────>│prod_id             │                          │
          │prod_id       │      │cntrctd_prc         │                          │
          │idn_id        │      │lst_prc             │                          │
          │fclty_id      │      │dscnt_pct           │                          │
          │sls_amt       │      └────────────────────┘                          │
          │qty           │                                                       │
          │sls_dt        │                                                       │
          └──────────────┘                                                       │
                │                                                                │
          dim_cmt_cust                    dim_prc_cmpnt_qual_prod    dim_idn  dim_fclty
          (Customer)                      (Qualified Products)       (IDN)    (Facility)
          ┌──────────────┐                ┌──────────────────────┐   ┌─────┐  ┌────────┐
          │cmt_cust_id   │                │cmpnt_id              │   │idn_ │  │fclty_  │
          │cust_nm       │                │prc_prg_id            │   │id   │  │id      │
          │idn_id────────┼───────────────>│prod_id───────┐       │   │idn_ │  │fclty_  │
          │fclty_id      │                │prod_ctgry_id │       │   │nm   │  │nm      │
          └──────────────┘                │qual_st_dt    │       │   └─────┘  └────────┘
                                          │qual_end_dt   │       │
                                          └──────────────┘       │
                                                                  │

═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

LAYER 1: BASE MODELS (Foundation)
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │ TRANSFORMATION: Filter + Window (dim_cntrc)                                               │
    └────────────────────────────────────────────────────────────────────────────────────────────┘
    
    dim_cntrc columns                    int_cntrct_rcnt_period
    ├── cntrc_id                         ├── cntrc_id ───────────────────────┐
    ├── cntrc_nm                         ├── cntrc_nm                        │
    ├── cntrc_sts (filter: Active)       ├── cntrc_sts                       │
    ├── prc_prg_id ─────────────────────>├── prc_prg_id                      │
    ├── cntrc_strt_dt (24-mo window)     ├── cntrc_strt_dt                   │
    └── cntrc_end_dt (24-mo window)      └── cntrc_end_dt                    │
                                                │                             │
                    ┌───────────────────────────┴──────────────────────────┬──┘ FLOWS DOWN TO:
                    │                                                       │  • All intermediate models
                    │                                                       │  • Base tier models
                    │                                                       │
    ┌───────────────────────────────────────────────┬─────────────────────────────────────────────┐
    │ TRANSFORMATION: Rank + Filter (rank=1) + Window (compliance periods)                       │
    └───────────────────────────────────────────────┬─────────────────────────────────────────────┘
    
    dim_prc_prg_cmpli_per_rslts          int_cntrct_compli_period_toc
    ├── cntrc_id ────────────────────────>├── cntrc_id
    ├── prc_prg_id ───────────────────────>├── prc_prg_id
    ├── cmt_cust_id (nullable) ───────────>├── cmt_cust_id
    ├── cmpnt_id ─────────────────────────>├── cmpnt_id
    ├── per_strt_dt (LATEST) ────────────>├── per_strt_dt ─────────┐
    ├── per_end_dt (LATEST) ─────────────>├── per_end_dt ──────────┤ FLOWS DOWN TO:
    ├── rnk_val (filter: =1) ───────────>│                         │ • Input models (eligibility)
    └── rank_scope ──────────────────────>└── rank_scope           │ • Fact tables
                                                 │                  │ • Comprehensive fact
                                                 └──────────────────┘

    ┌────────────────────────────────────────────────────────────────────────────────────────────┐
    │ TRANSFORMATION: Filter (tier_basis_type = 'MARKET SHARE') + Join to recent contracts      │
    └────────────────────────────────────────────────────────────────────────────────────────────┘

    dim_prc_prg_cmpnt (all components)   int_cntrct_rcnt_period (join)    int_cntrct_tier_components_ms
    ├── prc_prg_id ───────────────────────┐                              ├── cntrc_id (from join)
    ├── cmpnt_id ──────────────────────────┤                              ├── prc_prg_id
    ├── cmpnt_nm ──────────────────────────┤   ┌─ Filter MS tiers ─────>├── cmpnt_id
    ├── tier_basis_type (= 'MARKET SHARE') ├──┤                          ├── cmpnt_nm ─────────┐
    ├── tier_num ──────────────────────────┤   └─────────────────────────>├── tier_num ────────┐│
    ├── tier_min_pct ──────────────────────────────────────────────────────>├── tier_min_pct ─┐││
    ├── tier_max_pct ──────────────────────────────────────────────────────>├── tier_max_pct ─┤││
    ├── tier_min_val (ignored for MS) ────────────────────────────────────>│                   │││
    ├── tier_max_val (ignored for MS) ────────────────────────────────────>│                   │││
    └── rebate_pct ────────────────────────────────────────────────────────>└── rebate_pct ───┴┴┘
                                              (MS TOC marker)                   (FLOWS DOWN TO:)
                                                 │                             • Input models
                                                 │                             • Validation models
                                                 │                             • Comprehensive fact
                                                 │
                                                 └─ Similar for NMS models
                                                    int_cntrct_tier_components_nms
                                                    (filters: tier_basis_type != 'MARKET SHARE')

═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

LAYER 1.1.1: INPUT/ELIGIBILITY LAYER
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────┬───────────────────────────────────────────────────────┐
    │ int_cntrct_elgbl_cust_ms_toc        │ int_cntrct_qual_prod_ms_toc                           │
    │ (INNER JOIN: elig + tiers + period) │ (INNER JOIN: products + tiers + period)               │
    ├─────────────────────────────────────┼───────────────────────────────────────────────────────┤
    │ From dim_prc_cmpnt_cust_elig:       │ From dim_prc_cmpnt_qual_prod:                         │
    │   cmpnt_id ─┐                       │   cmpnt_id ─┐                                         │
    │   prc_prg_id├─> OUTPUT:             │   prod_id ──┼─> OUTPUT:                               │
    │   cmt_cust_id─→ (cntrc,customer,    │   prod_ctgry├─→ (cntrc,product,                       │
    │   elig_st_dt│   component)          │   qual_st_dt│   component)                            │
    │   elig_end_dt                       │   qual_end_dt                                         │
    │                                     │                                                       │
    │ From int_cntrct_tier_components_ms: │ From int_cntrct_tier_components_ms:                   │
    │   cntrc_id ──> (join source)        │   cntrc_id ──> (join source)                          │
    │   prc_prg_id                        │   prc_prg_id                                          │
    │   cmpnt_id   (join condition)       │   cmpnt_id   (join condition)                         │
    │                                     │                                                       │
    │ From int_cntrct_compli_period_toc:  │ From int_cntrct_compli_period_toc:                    │
    │   per_strt_dt ──> (passes through)  │   per_strt_dt ──> (passes through)                    │
    │   per_end_dt  ──> (passes through)  │   per_end_dt  ──> (passes through)                    │
    └──────────────────┬──────────────────┴────────────────────────┬──────────────────────────────┘
                       │                                            │
                       └───────────────────┬──────────────────────────┘
                                           │
                    ┌──────────────────────▼────────────────────────┐
                    │ int_cntrct_sls_ms_toc                         │
                    │ (FILTER transactions to eligible items)       │
                    ├────────────────────────────────────────────────┤
                    │ From fct_sls_trn:                              │
                    │   sls_trn_id ──┐                              │
                    │   cmt_cust_id ─┼─> (inner join to elgbl_cust) │
                    │   prod_id ─────┼─> (inner join to qual_prod)  │
                    │   idn_id ───────┼─────┐                       │
                    │   fclty_id ──────┼────┐│  OUTPUT:             │
                    │   sls_amt ───────┼────┼┤  Filtered            │
                    │   qty ────────────┼────┼┤  transactions at     │
                    │   sls_dt ────────┐│    ││  (cntrc,component,  │
                    │                  │└────┘│   customer,product)  │
                    │ From dim_cmt_cust:     │   level               │
                    │   idn_id ──────────────┴────→ (enrichment)     │
                    │   fclty_id ──────────────────→ (enrichment)    │
                    │                                                │
                    │ From eligibility lists:                        │
                    │   cntrc_id ──→ (via join)                      │
                    │   prc_prg_id ─→ (via join)                     │
                    │   cmpnt_id ──→ (via join)                      │
                    └────────────────────────────────────────────────┘
                                       │
                   ┌───────────────────┴────────────────────┐
                   │                                        │
                   ▼                                        ▼

═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

LAYER 1.1.1.1: FACT/AGGREGATION LAYER
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

    ┌─────────────────────────────────────┬──────────────────────────────────────────────────────┐
    │ int_cntrct_fct_tr_idn_ms_toc        │ int_cntrct_fct_tr_fclty_ms_toc                        │
    │ GROUP BY: (cntrc, prg, cmpnt, idn)  │ GROUP BY: (cntrc, prg, cmpnt, fclty)                 │
    ├─────────────────────────────────────┼──────────────────────────────────────────────────────┤
    │ From int_cntrct_sls_ms_toc:         │ From int_cntrct_sls_ms_toc:                          │
    │   cntrc_id ──────────┐              │   cntrc_id ──────────┐                               │
    │   prc_prg_id ────────┼─> GROUP BY   │   prc_prg_id ────────┼─> GROUP BY                    │
    │   cmpnt_id ──────────┤              │   cmpnt_id ──────────┤                               │
    │   idn_id ────────────┤   OUTPUT:    │   fclty_id ──────────┤   OUTPUT:                     │
    │   sls_amt ───> SUM ──┤   IDN fact   │   sls_amt ───> SUM ──┤   Facility fact              │
    │   qty ───────> SUM ──┘   table      │   qty ───────> SUM ──┘   table                       │
    │                                     │                                                      │
    │ Calculated:                         │ Calculated:                                          │
    │   qual_sls_amt = SUM(sales)         │   qual_sls_amt = SUM(sales)                          │
    │   tot_sls_amt = SUM(all sales)      │   tot_sls_amt = SUM(all sales)                       │
    │                                     │                                                      │
    │ From dim_idn:                       │ From dim_fclty:                                      │
    │   idn_nm ──────────> (enrichment)   │   fclty_nm ─────────> (enrichment)                   │
    │                                     │                                                      │
    │ From int_cntrct_compli_period_toc:  │ From int_cntrct_compli_period_toc:                   │
    │   per_strt_dt ──────────────────────│   per_strt_dt ──────────────────────                 │
    │   per_end_dt ───────────────────────│   per_end_dt ────────────────────                    │
    └──────────────────────┬──────────────┴─────────────────────┬─────────────────────────────────┘
                           │                                     │
                           └───────────────┬─────────────────────┘
                                           │
    ┌──────────────────────────────────────▼──────────────────────────────────────────────────────┐
    │                                                                                              │
    │ LAYER 1.1.1.1.1: VALIDATION/COMPLIANCE LAYER                                               │
    │                                                                                              │
    └──────────────────────────────────────┬──────────────────────────────────────────────────────┘
                                           │
    ┌──────────────────────────┬───────────▼─────────┬────────────────────────────────────────────┐
    │                          │                     │                                            │
    ▼                          ▼                     ▼                                            ▼

int_cntrct_cmplnc_vldtn_idn_ms_toc    int_cntrct_cmplnc_vldtn_fclty_ms_toc
(CALCULATE: ms_pct from idn fact)     (CALCULATE: ms_pct from facility fact)
┌──────────────────────────────────┐   ┌──────────────────────────────────┐
│ From int_cntrct_fct_tr_idn_ms_toc: │   │ From int_cntrct_fct_tr_fclty...:  │
│   cntrc_id ──────────────────────┤   │   cntrc_id ──────────────────────┤
│   prc_prg_id ──────────────────  │   │   prc_prg_id ──────────────────  │
│   cmpnt_id ───────────────────── │   │   cmpnt_id ───────────────────── │
│   idn_id ──────────────────────  │   │   fclty_id ────────────────────  │
│   idn_nm ──────────────────────  │   │   fclty_nm ────────────────────  │
│   qual_sls_amt ────────┐         │   │   qual_sls_amt ────────┐         │
│   tot_sls_amt ─────────┼─> CALC: │   │   tot_sls_amt ─────────┼─> CALC: │
│                        │ ms_pct= │   │                        │ ms_pct= │
│                        │ (q/t)*  │   │                        │ (q/t)*  │
│                        │ 100     │   │                        │ 100     │
│                        └─────────┘   │                        └─────────┘
│                                     │                                    │
└──────────────────────────────────────┘   └──────────────────────────────┘
         │                                           │
         └────────────────┬──────────────────────────┘
                          │
    ┌─────────────────────▼──────────────────────────┐
    │                                                │
    │ TIER ASSIGNMENT LAYER                         │
    │ (JOIN: tier definitions on ms_pct ranges)     │
    │                                                │
    └─────────────────────┬──────────────────────────┘
                          │
    ┌─────────────────────┴──────────────────────────┐
    │                                                │
    ▼                                                ▼

int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc    int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
(TIER JOIN + REBATE CALC @ IDN)            (TIER JOIN + REBATE CALC @ FACILITY)
┌────────────────────────────────────────┐  ┌────────────────────────────────────────┐
│ Passes through from validation layer:   │  │ Passes through from validation layer:  │
│   cntrc_id                              │  │   cntrc_id                             │
│   prc_prg_id                            │  │   prc_prg_id                           │
│   cmpnt_id                              │  │   cmpnt_id                             │
│   idn_id ─────────────────┐            │  │   fclty_id ───────────────┐            │
│   idn_nm                  │             │  │   fclty_nm                │             │
│   ms_pct ─────────────────┤             │  │   ms_pct ─────────────────┤             │
│   qual_sls_amt ───────────┤             │  │   qual_sls_amt ───────────┤             │
│   tot_sls_amt             │             │  │   tot_sls_amt             │             │
│                           │             │  │                           │             │
│ From int_cntrct_tier... :  │             │  │ From int_cntrct_tier... : │             │
│   tier_num ─> (TIER JOIN   │─> OUTPUT:  │  │   tier_num ─> (TIER JOIN  │─> OUTPUT:  │
│   WHERE ms_pct BETWEEN     │   Tier +   │  │   WHERE ms_pct BETWEEN    │   Tier +   │
│   tier_min_pct AND    ────>│   Rebate   │  │   tier_min_pct AND    ────>│   Rebate   │
│   tier_max_pct)            │   Amount   │  │   tier_max_pct)           │   Amount   │
│   tier_min_pct ───────────>│            │  │   tier_min_pct ──────────>│            │
│   tier_max_pct ───────────>│            │  │   tier_max_pct ──────────>│            │
│   rebate_pct ──┐            │            │  │   rebate_pct ──┐          │            │
│                │ CALC:      │            │  │                │ CALC:    │            │
│                │ rebate_amt=│            │  │                │ rebate..=│            │
│                │ (q*r/100)  │            │  │                │ (q*r/100)│            │
│                └────────────┘            │  │                └──────────┘            │
└────────────────────────────────────────┘  └────────────────────────────────────────┘
         │                                              │
         └──────────────────┬───────────────────────────┘
                            │

═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

LAYER 1.1.1.1.1.1: COMPREHENSIVE FACT LAYER
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

                            ┌──────────────────────────────────────┐
                            │ int_cntrct_cmprhnsv_fct_tr_ms_toc    │
                            │ UNION of IDN + Facility + Calc       │
                            └──────────────────────────────────────┘
                                            │
                ┌───────────────────────────┴────────────────────────┐
                │                                                    │
                ▼                                                    ▼
    
    From int_cntrct_cmplnc_vldtn_idn_rnkd (IDN path):    From int_cntrct_cmplnc_vldtn_fclty_rnkd (Facility path):
    
    cntrc_id ──────────────────────────────────────────┐  cntrc_id ────────────────┐
    prc_prg_id ────────────────────────────────────────┤  prc_prg_id ──────────────┤
    cmpnt_id ──────────────────────────────────────────┤  cmpnt_id ────────────────┤
    idn_id ───> NULL on facility path ────────────────┤  fclty_id ───> NULL on idn path
    idn_nm ──────────────────────────────────────────┤  fclty_nm ─────────────────┤
    ms_pct ───> idn_ms_pct ────────────────────────────┤  ms_pct ────> fclty_ms_pct ┤
    tier_num ──> idn_tier ──────────────────────────────┤  tier_num ───> fclty_tier ──┤
    qual_sls_amt ──────────────────────────────────────┤  qual_sls_amt ──────────────┤
    tot_sls_amt ───────────────────────────────────────┤  tot_sls_amt ───────────────┤
    rebate_amt ──> idn_rebate ────────────────────────┘  rebate_amt ──> fclty_rebate ─┘
                                │
                                │ UNION ALL
                                ▼
                    
                    ┌─────────────────────────────────┐
                    │ Comprehensive Output Columns:   │
                    ├─────────────────────────────────┤
                    │ cntrc_id                        │
                    │ prc_prg_id                      │
                    │ cmpnt_id                        │
                    │ cmpnt_nm (join to tier def)     │
                    │ cmt_cust_id (always NULL)       │
                    │ idn_id (or NULL)                │
                    │ idn_nm (or NULL)                │
                    │ fclty_id (or NULL)              │
                    │ fclty_nm (or NULL)              │
                    │ qual_sls_amt (UNION)            │
                    │ tot_sls_amt (UNION)             │
                    │ overall_ms_pct ────────┐        │
                    │   = (q/t)*100 ─────────┤ CALC  │
                    │ idn_ms_pct (or NULL)    │       │
                    │ fclty_ms_pct (or NULL)  │       │
                    │ idn_tier (or NULL)      │       │
                    │ fclty_tier (or NULL)    │       │
                    │ idn_rebate (or NULL)    │       │
                    │ fclty_rebate (or NULL)  │       │
                    │ tot_rebate ─────────────┼─ CALC │
                    │   = idn_rbate + fclty.. │       │
                    │ compli_per_strt_dt      │       │
                    │ compli_per_end_dt       │       │
                    └──────────────┬──────────┘
                                   │

═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

LAYER FINAL: MART/REPORTING
═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

                                   ┌──────────────────────────────┐
                                   │ mart_cntrct_ms_toc           │
                                   │ (Pass-through all columns)   │
                                   ├──────────────────────────────┤
                                   │ • Direct pass from compre... │
                                   │ • Ready for BI/Dashboard     │
                                   │ • Single source of truth     │
                                   └──────────────────────────────┘
                                             │
                                             ▼
                                   ┌──────────────────────────────┐
                                   │ BI Tools / Dashboards        │
                                   │ (Reporting & Analysis)       │
                                   └──────────────────────────────┘

═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
```

## Key Column Transformation Rules

### Rule 1: Primary Keys Pass Through All Layers
```
dim_cntrc.cntrc_id 
  → int_cntrct_rcnt_period.cntrc_id 
  → int_cntrct_tier_components_ms.cntrc_id 
  → int_cntrct_elgbl_cust_ms_toc.cntrc_id 
  → int_cntrct_sls_ms_toc.cntrc_id 
  → int_cntrct_fct_tr_idn_ms_toc.cntrc_id 
  → int_cntrct_cmplnc_vldtn_idn_ms_toc.cntrc_id 
  → int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.cntrc_id 
  → int_cntrct_cmprhnsv_fct_tr_ms_toc.cntrc_id 
  → mart_cntrct_ms_toc.cntrc_id
```

### Rule 2: Filtering Reduces Scope at Base Layer
```
dim_prc_prg_cmpnt (ALL components)
  ↓ (filter: tier_basis_type = 'MARKET SHARE')
int_cntrct_tier_components_ms (MS ONLY)
  ↓ (joined by all MS TOC models)
All downstream: MS TOC filtered scope
```

### Rule 3: Aggregation Transforms Structure
```
fct_sls_trn (transaction-level)
  → int_cntrct_sls_ms_toc (filtered transactions)
  → int_cntrct_fct_tr_idn_ms_toc (SUM grouped by IDN)
    • sls_amt → SUM(sls_amt) AS qual_sls_amt
    • sls_amt → SUM(all) AS tot_sls_amt
```

### Rule 4: Calculated Columns Flow Downstream
```
int_cntrct_cmplnc_vldtn_idn_ms_toc:
  ms_pct = (qual_sls_amt / tot_sls_amt) * 100
  ↓ (used for tier matching)
int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc:
  rebate_amt = qual_sls_amt * (rebate_pct / 100)
  ↓ (summed in comprehensive fact)
int_cntrct_cmprhnsv_fct_tr_ms_toc:
  tot_rebate = idn_rebate + fclty_rebate
```

### Rule 5: Multi-Level Hierarchy via UNION
```
IDN path:        │ Facility path:
idn_id: value    │ idn_id: NULL
idn_nm: value    │ idn_nm: NULL
fclty_id: NULL   │ fclty_id: value
fclty_nm: NULL   │ fclty_nm: value
┌────────────────┴─────────────────┐
└─────────────────┬────────────────┘
  UNION creates dual-level view
```

