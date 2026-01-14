#!/bin/bash

# Create MS TOC directory
mkdir -p models/intermediate/ms_toc

# Create Model 1: Eligible Customers
cat > models/intermediate/ms_toc/int_cntrct_elgbl_cust_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Eligible Customers for MS TOC
    
    Business Logic:
    - Identifies eligible customers for market share compliance
    - Joins customer eligibility with compliance periods
    - Filters to latest compliance period (TOC)
    
    Source: md_dwh.dim_prc_cmpnt_cust_elig
    Target: md_wrk.sv_cntrct_elgbl_cust_ms_toc
*/

SELECT DISTINCT
    tc.cntrc_id,
    tc.prc_prg_id,
    tc.cmpnt_id,
    dpccev.cmt_cust_id,
    dpccev.elig_st_dt,
    dpccev.elig_end_dt,
    cp.per_strt_dt AS compli_per_strt_dt,
    cp.per_end_dt AS compli_per_end_dt
FROM {{ ref('int_cntrct_tier_components_ms') }} tc
INNER JOIN {{ source('md_dwh', 'dim_prc_cmpnt_cust_elig') }} dpccev
    ON tc.cmpnt_id = dpccev.cmpnt_id
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cp
    ON tc.cntrc_id = cp.cntrc_id
    AND tc.prc_prg_id = cp.prc_prg_id
    AND tc.cmpnt_id = cp.cmpnt_id
    AND dpccev.cmt_cust_id = cp.cmt_cust_id
    AND cp.rank_scope = 'with_cust'
WHERE dpccev.elig_ind = 'Y'
  AND cp.per_strt_dt <= dpccev.elig_end_dt
  AND cp.per_end_dt >= dpccev.elig_st_dt
EOF

# Create Model 2: Qualified Products
cat > models/intermediate/ms_toc/int_cntrct_qual_prod_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Qualified Products for MS TOC
    
    Business Logic:
    - Products that qualify for market share calculations
    - Filtered to active qualification periods
    - Aligned with latest compliance period
    
    Source: md_dwh.dim_prc_cmpnt_qual_prod
    Target: md_wrk.sv_cntrct_qual_prod_ms_toc
*/

SELECT DISTINCT
    tc.cntrc_id,
    tc.prc_prg_id,
    tc.cmpnt_id,
    dpcqpv.prod_id,
    dpcqpv.qual_st_dt,
    dpcqpv.qual_end_dt,
    cp.per_strt_dt AS compli_per_strt_dt,
    cp.per_end_dt AS compli_per_end_dt
FROM {{ ref('int_cntrct_tier_components_ms') }} tc
INNER JOIN {{ source('md_dwh', 'dim_prc_cmpnt_qual_prod') }} dpcqpv
    ON tc.cmpnt_id = dpcqpv.cmpnt_id
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cp
    ON tc.cntrc_id = cp.cntrc_id
    AND tc.prc_prg_id = cp.prc_prg_id
    AND tc.cmpnt_id = cp.cmpnt_id
    AND cp.rank_scope = 'no_cust'
WHERE dpcqpv.qual_ind = 'Y'
  AND cp.per_strt_dt <= dpcqpv.qual_end_dt
  AND cp.per_end_dt >= dpcqpv.qual_st_dt
EOF

# Create Model 3: Contracted Pricing
cat > models/intermediate/ms_toc/int_cntrct_prod_cntrctd_prc_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Contracted Pricing for Qualified Products
    
    Business Logic:
    - Gets contracted price for each qualified product
    - Uses most recent price effective within compliance period
    
    Source: md_dwh.dim_cntrc_prod_line_item
    Target: md_wrk.sv_cntrct_prod_cntrctd_prc_ms_toc
*/

WITH ranked_prices AS (
    SELECT
        qp.cntrc_id,
        qp.prc_prg_id,
        qp.cmpnt_id,
        qp.prod_id,
        dcpliv.unit_prc AS cntrctd_prc,
        dcpliv.eff_st_dt,
        dcpliv.eff_end_dt,
        qp.compli_per_strt_dt,
        qp.compli_per_end_dt,
        ROW_NUMBER() OVER (
            PARTITION BY qp.cntrc_id, qp.prc_prg_id, qp.cmpnt_id, qp.prod_id
            ORDER BY dcpliv.eff_st_dt DESC
        ) AS rnk
    FROM {{ ref('int_cntrct_qual_prod_ms_toc') }} qp
    INNER JOIN {{ source('md_dwh', 'dim_cntrc_prod_line_item') }} dcpliv
        ON qp.cntrc_id = dcpliv.cntrc_id
        AND qp.prod_id = dcpliv.prod_id
    WHERE qp.compli_per_strt_dt <= dcpliv.eff_end_dt
      AND qp.compli_per_end_dt >= dcpliv.eff_st_dt
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    prod_id,
    cntrctd_prc,
    eff_st_dt,
    eff_end_dt,
    compli_per_strt_dt,
    compli_per_end_dt
FROM ranked_prices
WHERE rnk = 1
EOF

# Create Model 4: Sales Data
cat > models/intermediate/ms_toc/int_cntrct_sls_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Sales Data for MS TOC
    
    Business Logic:
    - Transaction-level sales for qualified products
    - Filtered to compliance period date range
    - Foundation for market share calculations
    
    Source: md_dwh.sv_fact_transaction
    Target: md_wrk.sv_cntrct_sls_ms_toc
*/

SELECT
    qp.cntrc_id,
    qp.prc_prg_id,
    qp.cmpnt_id,
    ft.cust_id,
    ft.prod_id,
    ft.trnsc_dt,
    ft.qty AS qty_sold,
    ft.net_amt AS net_sls_amt,
    ft.gross_amt AS gross_sls_amt,
    qp.compli_per_strt_dt,
    qp.compli_per_end_dt
FROM {{ ref('int_cntrct_qual_prod_ms_toc') }} qp
INNER JOIN {{ source('md_dwh', 'sv_fact_transaction') }} ft
    ON qp.cntrc_id = ft.cntrc_id
    AND qp.prod_id = ft.prod_id
WHERE ft.trnsc_dt BETWEEN qp.compli_per_strt_dt AND qp.compli_per_end_dt
EOF

# Create Model 5: IDN Facts
cat > models/intermediate/ms_toc/int_cntrct_fct_tr_idn_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Transaction Facts at IDN Level
    
    Business Logic:
    - Rolls up sales to IDN (Integrated Delivery Network) level
    - Uses customer hierarchy to map customers to IDNs
    
    Source: hier_cust, int_cntrct_sls_ms_toc
    Target: md_wrk.sv_cntrct_fct_tr_idn_ms_toc
*/

WITH idn_mapping AS (
    SELECT DISTINCT
        cust_id,
        idn_id,
        idn_nm
    FROM {{ source('md_dwh', 'hier_cust') }}
    WHERE hier_lvl = 'IDN'
)

SELECT
    s.cntrc_id,
    s.prc_prg_id,
    s.cmpnt_id,
    i.idn_id,
    i.idn_nm,
    s.cust_id,
    s.prod_id,
    s.trnsc_dt,
    s.qty_sold,
    s.net_sls_amt,
    s.gross_sls_amt,
    s.compli_per_strt_dt,
    s.compli_per_end_dt
FROM {{ ref('int_cntrct_sls_ms_toc') }} s
INNER JOIN idn_mapping i
    ON s.cust_id = i.cust_id
EOF

# Create Model 6: Facility Facts
cat > models/intermediate/ms_toc/int_cntrct_fct_tr_fclty_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Transaction Facts at Facility Level
    
    Business Logic:
    - Keeps sales at facility/customer level
    - Joins with account dimension for facility names
    
    Source: dim_acct, int_cntrct_sls_ms_toc
    Target: md_wrk.sv_cntrct_fct_tr_fclty_ms_toc
*/

SELECT
    s.cntrc_id,
    s.prc_prg_id,
    s.cmpnt_id,
    s.cust_id AS fclty_id,
    a.acct_nm AS fclty_nm,
    s.prod_id,
    s.trnsc_dt,
    s.qty_sold,
    s.net_sls_amt,
    s.gross_sls_amt,
    s.compli_per_strt_dt,
    s.compli_per_end_dt
FROM {{ ref('int_cntrct_sls_ms_toc') }} s
LEFT JOIN {{ source('md_dwh', 'dim_acct') }} a
    ON s.cust_id = a.acct_id
EOF

# Create Model 7: IDN Compliance Validation
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_idn_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    IDN Market Share Calculation
    
    Business Logic:
    - Calculates market share % at IDN level
    - Formula: (Qualified Product Sales / Total IDN Sales) * 100
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_idn_ms_toc
*/

WITH idn_total_sales AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        idn_id,
        prod_id,
        SUM(net_sls_amt) AS prod_sls_amt,
        SUM(qty_sold) AS prod_qty_sold
    FROM {{ ref('int_cntrct_fct_tr_idn_ms_toc') }}
    GROUP BY 1, 2, 3, 4, 5
),

idn_qualified_sales AS (
    SELECT
        ts.cntrc_id,
        ts.prc_prg_id,
        ts.cmpnt_id,
        ts.idn_id,
        ts.prod_id,
        ts.prod_sls_amt,
        ts.prod_qty_sold,
        CASE WHEN qp.prod_id IS NOT NULL THEN 1 ELSE 0 END AS is_qualified
    FROM idn_total_sales ts
    LEFT JOIN {{ ref('int_cntrct_qual_prod_ms_toc') }} qp
        ON ts.cntrc_id = qp.cntrc_id
        AND ts.prc_prg_id = qp.prc_prg_id
        AND ts.cmpnt_id = qp.cmpnt_id
        AND ts.prod_id = qp.prod_id
),

idn_aggregates AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        idn_id,
        SUM(prod_sls_amt) AS total_idn_sls,
        SUM(CASE WHEN is_qualified = 1 THEN prod_sls_amt ELSE 0 END) AS qualified_idn_sls,
        SUM(prod_qty_sold) AS total_idn_qty,
        SUM(CASE WHEN is_qualified = 1 THEN prod_qty_sold ELSE 0 END) AS qualified_idn_qty
    FROM idn_qualified_sales
    GROUP BY 1, 2, 3, 4
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    idn_id,
    total_idn_sls,
    qualified_idn_sls,
    total_idn_qty,
    qualified_idn_qty,
    CASE
        WHEN total_idn_sls > 0
        THEN (qualified_idn_sls::DECIMAL(18,4) / total_idn_sls::DECIMAL(18,4)) * 100
        ELSE 0
    END AS idn_ms_pct
FROM idn_aggregates
EOF

# Create Model 8: IDN Ranked Compliance
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    IDN Tier Achievement
    
    Business Logic:
    - Assigns tier based on calculated MS%
    - Uses tier thresholds from component definition
    - Selects highest tier achieved
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
*/

WITH tier_ranges AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        tier_num,
        ms_min_pct,
        COALESCE(ms_max_pct, 999999) AS ms_max_pct,
        rebate_amt,
        rebate_pct
    FROM {{ ref('int_cntrct_tier_components_ms') }}
),

idn_tier_match AS (
    SELECT
        cv.cntrc_id,
        cv.prc_prg_id,
        cv.cmpnt_id,
        cv.idn_id,
        cv.idn_ms_pct,
        cv.total_idn_sls,
        cv.qualified_idn_sls,
        cv.total_idn_qty,
        cv.qualified_idn_qty,
        tr.tier_num,
        tr.ms_min_pct,
        tr.ms_max_pct,
        tr.rebate_amt,
        tr.rebate_pct,
        ROW_NUMBER() OVER (
            PARTITION BY cv.cntrc_id, cv.prc_prg_id, cv.cmpnt_id, cv.idn_id
            ORDER BY tr.tier_num DESC
        ) AS tier_rank
    FROM {{ ref('int_cntrct_cmplnc_vldtn_idn_ms_toc') }} cv
    INNER JOIN tier_ranges tr
        ON cv.cntrc_id = tr.cntrc_id
        AND cv.prc_prg_id = tr.prc_prg_id
        AND cv.cmpnt_id = tr.cmpnt_id
    WHERE cv.idn_ms_pct >= tr.ms_min_pct
      AND cv.idn_ms_pct < tr.ms_max_pct
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    idn_id,
    idn_ms_pct,
    total_idn_sls,
    qualified_idn_sls,
    total_idn_qty,
    qualified_idn_qty,
    tier_num AS achieved_tier_num,
    ms_min_pct AS tier_min_pct,
    ms_max_pct AS tier_max_pct,
    rebate_amt,
    rebate_pct,
    qualified_idn_sls * COALESCE(rebate_pct / 100, 0) AS calculated_rebate_amt
FROM idn_tier_match
WHERE tier_rank = 1
EOF

# Create Model 9: Facility Compliance Validation
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_fclty_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Facility Market Share Calculation
    
    Business Logic:
    - Calculates market share % at facility level
    - Formula: (Qualified Product Sales / Total Facility Sales) * 100
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_fclty_ms_toc
*/

WITH fclty_total_sales AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        fclty_id,
        prod_id,
        SUM(net_sls_amt) AS prod_sls_amt,
        SUM(qty_sold) AS prod_qty_sold
    FROM {{ ref('int_cntrct_fct_tr_fclty_ms_toc') }}
    GROUP BY 1, 2, 3, 4, 5
),

fclty_qualified_sales AS (
    SELECT
        ts.cntrc_id,
        ts.prc_prg_id,
        ts.cmpnt_id,
        ts.fclty_id,
        ts.prod_id,
        ts.prod_sls_amt,
        ts.prod_qty_sold,
        CASE WHEN qp.prod_id IS NOT NULL THEN 1 ELSE 0 END AS is_qualified
    FROM fclty_total_sales ts
    LEFT JOIN {{ ref('int_cntrct_qual_prod_ms_toc') }} qp
        ON ts.cntrc_id = qp.cntrc_id
        AND ts.prc_prg_id = qp.prc_prg_id
        AND ts.cmpnt_id = qp.cmpnt_id
        AND ts.prod_id = qp.prod_id
),

fclty_aggregates AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        fclty_id,
        SUM(prod_sls_amt) AS total_fclty_sls,
        SUM(CASE WHEN is_qualified = 1 THEN prod_sls_amt ELSE 0 END) AS qualified_fclty_sls,
        SUM(prod_qty_sold) AS total_fclty_qty,
        SUM(CASE WHEN is_qualified = 1 THEN prod_qty_sold ELSE 0 END) AS qualified_fclty_qty
    FROM fclty_qualified_sales
    GROUP BY 1, 2, 3, 4
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    fclty_id,
    total_fclty_sls,
    qualified_fclty_sls,
    total_fclty_qty,
    qualified_fclty_qty,
    CASE
        WHEN total_fclty_sls > 0
        THEN (qualified_fclty_sls::DECIMAL(18,4) / total_fclty_sls::DECIMAL(18,4)) * 100
        ELSE 0
    END AS fclty_ms_pct
FROM fclty_aggregates
EOF

# Create Model 10: Facility Ranked Compliance
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Facility Tier Achievement
    
    Business Logic:
    - Assigns tier based on calculated MS%
    - Uses tier thresholds from component definition
    - Selects highest tier achieved
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
*/

WITH tier_ranges AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        tier_num,
        ms_min_pct,
        COALESCE(ms_max_pct, 999999) AS ms_max_pct,
        rebate_amt,
        rebate_pct
    FROM {{ ref('int_cntrct_tier_components_ms') }}
),

fclty_tier_match AS (
    SELECT
        cv.cntrc_id,
        cv.prc_prg_id,
        cv.cmpnt_id,
        cv.fclty_id,
        cv.fclty_ms_pct,
        cv.total_fclty_sls,
        cv.qualified_fclty_sls,
        cv.total_fclty_qty,
        cv.qualified_fclty_qty,
        tr.tier_num,
        tr.ms_min_pct,
        tr.ms_max_pct,
        tr.rebate_amt,
        tr.rebate_pct,
        ROW_NUMBER() OVER (
            PARTITION BY cv.cntrc_id, cv.prc_prg_id, cv.cmpnt_id, cv.fclty_id
            ORDER BY tr.tier_num DESC
        ) AS tier_rank
    FROM {{ ref('int_cntrct_cmplnc_vldtn_fclty_ms_toc') }} cv
    INNER JOIN tier_ranges tr
        ON cv.cntrc_id = tr.cntrc_id
        AND cv.prc_prg_id = tr.prc_prg_id
        AND cv.cmpnt_id = tr.cmpnt_id
    WHERE cv.fclty_ms_pct >= tr.ms_min_pct
      AND cv.fclty_ms_pct < tr.ms_max_pct
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    fclty_id,
    fclty_ms_pct,
    total_fclty_sls,
    qualified_fclty_sls,
    total_fclty_qty,
    qualified_fclty_qty,
    tier_num AS achieved_tier_num,
    ms_min_pct AS tier_min_pct,
    ms_max_pct AS tier_max_pct,
    rebate_amt,
    rebate_pct,
    qualified_fclty_sls * COALESCE(rebate_pct / 100, 0) AS calculated_rebate_amt
FROM fclty_tier_match
WHERE tier_rank = 1
EOF

# Create Model 11: Comprehensive Fact
cat > models/intermediate/ms_toc/int_cntrct_cmprhnsv_fct_tr_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        tags=['ms', 'toc', 'market_share'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Comprehensive MS TOC Fact Table
    
    Business Logic:
    - Combines all MS TOC components into single fact table
    - Transaction-level detail with compliance metrics
    - Foundation for final mart
    
    Target: md_wrk.sv_cntrct_cmprhnsv_fct_tr_ms_toc
*/

SELECT
    s.cntrc_id,
    s.prc_prg_id,
    s.cmpnt_id,
    s.cust_id,
    s.prod_id,
    s.trnsc_dt,
    s.qty_sold,
    s.net_sls_amt,
    s.gross_sls_amt,
    
    -- Eligibility
    ec.cmt_cust_id AS eligible_cust_id,
    CASE WHEN qp.prod_id IS NOT NULL THEN 1 ELSE 0 END AS is_qualified_prod,
    
    -- Pricing
    cp.cntrctd_prc,
    
    -- IDN metrics
    idn_f.idn_id,
    idn_f.idn_nm,
    idn_r.idn_ms_pct,
    idn_r.achieved_tier_num AS idn_tier_achieved,
    idn_r.calculated_rebate_amt AS idn_rebate_amt,
    
    -- Facility metrics
    fclty_r.fclty_ms_pct,
    fclty_r.achieved_tier_num AS fclty_tier_achieved,
    fclty_r.calculated_rebate_amt AS fclty_rebate_amt,
    
    -- Compliance period
    s.compli_per_strt_dt,
    s.compli_per_end_dt,
    
    CURRENT_TIMESTAMP AS load_ts
    
FROM {{ ref('int_cntrct_sls_ms_toc') }} s

LEFT JOIN {{ ref('int_cntrct_elgbl_cust_ms_toc') }} ec
    ON s.cntrc_id = ec.cntrc_id
    AND s.prc_prg_id = ec.prc_prg_id
    AND s.cmpnt_id = ec.cmpnt_id
    AND s.cust_id = ec.cmt_cust_id

LEFT JOIN {{ ref('int_cntrct_qual_prod_ms_toc') }} qp
    ON s.cntrc_id = qp.cntrc_id
    AND s.prc_prg_id = qp.prc_prg_id
    AND s.cmpnt_id = qp.cmpnt_id
    AND s.prod_id = qp.prod_id

LEFT JOIN {{ ref('int_cntrct_prod_cntrctd_prc_ms_toc') }} cp
    ON s.cntrc_id = cp.cntrc_id
    AND s.prc_prg_id = cp.prc_prg_id
    AND s.cmpnt_id = cp.cmpnt_id
    AND s.prod_id = cp.prod_id

LEFT JOIN {{ ref('int_cntrct_fct_tr_idn_ms_toc') }} idn_f
    ON s.cntrc_id = idn_f.cntrc_id
    AND s.prc_prg_id = idn_f.prc_prg_id
    AND s.cmpnt_id = idn_f.cmpnt_id
    AND s.cust_id = idn_f.cust_id
    AND s.prod_id = idn_f.prod_id
    AND s.trnsc_dt = idn_f.trnsc_dt

LEFT JOIN {{ ref('int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc') }} idn_r
    ON idn_f.cntrc_id = idn_r.cntrc_id
    AND idn_f.prc_prg_id = idn_r.prc_prg_id
    AND idn_f.cmpnt_id = idn_r.cmpnt_id
    AND idn_f.idn_id = idn_r.idn_id

LEFT JOIN {{ ref('int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc') }} fclty_r
    ON s.cntrc_id = fclty_r.cntrc_id
    AND s.prc_prg_id = fclty_r.prc_prg_id
    AND s.cmpnt_id = fclty_r.cmpnt_id
    AND s.cust_id = fclty_r.fclty_id
EOF

# Create MS TOC YAML documentation
cat > models/intermediate/ms_toc/_ms_toc.yml << 'EOF'
version: 2

models:
  - name: int_cntrct_elgbl_cust_ms_toc
    description: 'Eligible customers for MS TOC compliance'
    
  - name: int_cntrct_qual_prod_ms_toc
    description: 'Qualified products for MS TOC compliance'
    
  - name: int_cntrct_prod_cntrctd_prc_ms_toc
    description: 'Contracted pricing for qualified products'
    
  - name: int_cntrct_sls_ms_toc
    description: 'Sales transactions for MS TOC'
    
  - name: int_cntrct_fct_tr_idn_ms_toc
    description: 'Transaction facts at IDN level'
    
  - name: int_cntrct_fct_tr_fclty_ms_toc
    description: 'Transaction facts at facility level'
    
  - name: int_cntrct_cmplnc_vldtn_idn_ms_toc
    description: 'IDN market share calculations'
    
  - name: int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
    description: 'IDN tier achievement and rebates'
    
  - name: int_cntrct_cmplnc_vldtn_fclty_ms_toc
    description: 'Facility market share calculations'
    
  - name: int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
    description: 'Facility tier achievement and rebates'
    
  - name: int_cntrct_cmprhnsv_fct_tr_ms_toc
    description: 'Comprehensive MS TOC fact table'
EOF

echo "✅ All MS TOC intermediate models created successfully!"
# Create marts directory if not exists
mkdir -p models/marts/contract_compliance

# Create the MS TOC mart
cat > models/marts/contract_compliance/mart_cntrct_ms_toc.sql << 'EOF'
{{
    config(
        materialized='table',
        schema='ldw',
        tags=['ms', 'toc', 'mart'],
        post_hook=[
            "GRANT SELECT ON {{ this }} TO GROUP bi_users",
            "ANALYZE {{ this }}"
        ]
    )
}}

/*
    Market Share Time of Compliance Mart
    
    Business Logic:
    - Final reporting table for MS TOC compliance
    - Aggregated metrics at contract/program/component level
    - Latest compliance period snapshot
    - Ready for BI/Dashboard consumption
    
    Target: ldw.mart_cntrct_ms_toc
*/

WITH contract_summary AS (
    SELECT
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        compli_per_strt_dt,
        compli_per_end_dt,
        
        -- Counts
        COUNT(DISTINCT cust_id) AS total_customers,
        COUNT(DISTINCT CASE WHEN eligible_cust_id IS NOT NULL THEN cust_id END) AS eligible_customers,
        COUNT(DISTINCT prod_id) AS total_products,
        COUNT(DISTINCT CASE WHEN is_qualified_prod = 1 THEN prod_id END) AS qualified_products,
        COUNT(DISTINCT idn_id) AS total_idns,
        
        -- Sales aggregates
        SUM(net_sls_amt) AS total_sales,
        SUM(CASE WHEN is_qualified_prod = 1 THEN net_sls_amt ELSE 0 END) AS qualified_sales,
        SUM(qty_sold) AS total_quantity,
        SUM(CASE WHEN is_qualified_prod = 1 THEN qty_sold ELSE 0 END) AS qualified_quantity,
        
        -- Rebate calculations
        SUM(COALESCE(idn_rebate_amt, 0)) AS total_idn_rebate,
        SUM(COALESCE(fclty_rebate_amt, 0)) AS total_fclty_rebate,
        
        -- Market share averages
        AVG(CASE WHEN idn_ms_pct > 0 THEN idn_ms_pct END) AS avg_idn_ms_pct,
        AVG(CASE WHEN fclty_ms_pct > 0 THEN fclty_ms_pct END) AS avg_fclty_ms_pct,
        
        -- Tier achievements
        AVG(idn_tier_achieved) AS avg_idn_tier,
        AVG(fclty_tier_achieved) AS avg_fclty_tier,
        
        -- Metadata
        COUNT(*) AS transaction_count,
        MAX(load_ts) AS last_updated_ts
        
    FROM {{ ref('int_cntrct_cmprhnsv_fct_tr_ms_toc') }}
    GROUP BY 1, 2, 3, 4, 5
),

contract_details AS (
    SELECT DISTINCT
        c.cntrc_id,
        c.cntrc_nm,
        c.cntrc_sts,
        tc.prc_prg_id,
        tc.cmpnt_id,
        tc.tier_num,
        tc.ms_min_pct,
        tc.ms_max_pct
    FROM {{ ref('int_cntrct_rcnt_period') }} c
    INNER JOIN {{ ref('int_cntrct_tier_components_ms') }} tc
        ON c.cntrc_id = tc.cntrc_id
)

SELECT
    -- Contract identifiers
    cd.cntrc_id,
    cd.cntrc_nm,
    cd.cntrc_sts,
    cd.prc_prg_id,
    cd.cmpnt_id,
    cd.tier_num,
    cd.ms_min_pct AS tier_ms_min_pct,
    cd.ms_max_pct AS tier_ms_max_pct,
    
    -- Compliance period
    cs.compli_per_strt_dt,
    cs.compli_per_end_dt,
    DATEDIFF(day, cs.compli_per_strt_dt, cs.compli_per_end_dt) AS period_days,
    
    -- Customer metrics
    cs.total_customers,
    cs.eligible_customers,
    CASE 
        WHEN cs.total_customers > 0 
        THEN (cs.eligible_customers::DECIMAL(10,2) / cs.total_customers) * 100 
        ELSE 0 
    END AS eligible_customer_pct,
    
    -- Product metrics
    cs.total_products,
    cs.qualified_products,
    CASE 
        WHEN cs.total_products > 0 
        THEN (cs.qualified_products::DECIMAL(10,2) / cs.total_products) * 100 
        ELSE 0 
    END AS qualified_product_pct,
    
    -- IDN metrics
    cs.total_idns,
    
    -- Sales metrics
    cs.total_sales,
    cs.qualified_sales,
    CASE 
        WHEN cs.total_sales > 0 
        THEN (cs.qualified_sales / cs.total_sales) * 100 
        ELSE 0 
    END AS overall_ms_pct,
    
    cs.total_quantity,
    cs.qualified_quantity,
    
    -- Rebate metrics
    cs.total_idn_rebate,
    cs.total_fclty_rebate,
    cs.total_idn_rebate + cs.total_fclty_rebate AS total_rebate,
    
    -- Market share performance
    cs.avg_idn_ms_pct,
    cs.avg_fclty_ms_pct,
    cs.avg_idn_tier,
    cs.avg_fclty_tier,
    
    -- Compliance flags
    CASE 
        WHEN cs.avg_idn_ms_pct >= cd.ms_min_pct THEN 1 
        ELSE 0 
    END AS is_compliant,
    
    -- Metadata
    cs.transaction_count,
    cs.last_updated_ts,
    CURRENT_TIMESTAMP AS mart_created_ts

FROM contract_summary cs
INNER JOIN contract_details cd
    ON cs.cntrc_id = cd.cntrc_id
    AND cs.prc_prg_id = cd.prc_prg_id
    AND cs.cmpnt_id = cd.cmpnt_id
EOF

# Create marts YAML documentation
cat > models/marts/contract_compliance/_contract_compliance.yml << 'EOF'
version: 2

models:
  - name: mart_cntrct_ms_toc
    description: |
      **Market Share Time of Compliance Mart**
      
      Final reporting table for contract compliance metrics at the latest compliance period.
      
      **Key Metrics:**
      - Market share calculations at IDN and facility levels
      - Tier achievement tracking
      - Rebate calculations
      - Customer and product eligibility metrics
      
      **Business Use Cases:**
      - Contract performance dashboards
      - Compliance reporting
      - Rebate accrual calculations
      - Sales team performance tracking
      - Executive summary reporting
      
    columns:
      - name: cntrc_id
        description: 'Contract ID (Primary Key part 1)'
        tests:
          - not_null
          
      - name: prc_prg_id
        description: 'Pricing program ID (Primary Key part 2)'
        tests:
          - not_null
          
      - name: cmpnt_id
        description: 'Component ID (Primary Key part 3)'
        tests:
          - not_null
          
      - name: cntrc_nm
        description: 'Contract name'
        
      - name: overall_ms_pct
        description: 'Overall market share percentage (qualified sales / total sales)'
        tests:
          - dbt_utils.expression_is_true:
              expression: ">= 0 AND <= 100"
              
      - name: is_compliant
        description: 'Flag indicating if contract meets minimum MS threshold (1=Yes, 0=No)'
        tests:
          - accepted_values:
              values: [0, 1]
              
      - name: total_rebate
        description: 'Total rebate amount (IDN + Facility)'
        
      - name: total_sales
        description: 'Total sales amount for the compliance period'
        
      - name: qualified_sales
        description: 'Sales amount for qualified products only'
        
      - name: avg_idn_ms_pct
        description: 'Average market share % across all IDNs'
        
      - name: avg_fclty_ms_pct
        description: 'Average market share % across all facilities'
        
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - cntrc_id
            - prc_prg_id
            - cmpnt_id
EOF

echo "✅ MS TOC Mart model created successfully!"