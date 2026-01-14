#!/bin/bash

set -e

echo "🚀 Starting MS TOC Documentation Model Update..."
echo ""

# Create MS TOC models directory
mkdir -p models/intermediate/ms_toc

# ============================================================================
# Model 1: Eligible Customers
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_elgbl_cust_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Eligible Customers for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Identifies eligible customers for market share compliance
    - Joins customer eligibility with compliance periods
    - Filters to latest compliance period (TOC)
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - cmt_cust_id: Compliant customer ID
    - elig_st_dt: Eligibility start date
    - elig_end_dt: Eligibility end date
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.dim_prc_cmpnt_cust_elig
    - dim_prc_prg_cmpli_per_rslts
    
    Target: md_wrk.sv_cntrct_elgbl_cust_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cmt_cust_id,
       CAST(NULL AS DATE) AS elig_st_dt,
       CAST(NULL AS DATE) AS elig_end_dt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_elgbl_cust_ms_toc.sql"

# ============================================================================
# Model 2: Qualified Products
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_qual_prod_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Qualified Products for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Products that qualify for market share calculations
    - Filtered to active qualification periods
    - Aligned with latest compliance period
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - prod_id: Product ID
    - qual_st_dt: Qualification start date
    - qual_end_dt: Qualification end date
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.dim_prc_cmpnt_qual_prod
    - dim_prc_prg_cmpli_per_rslts
    
    Target: md_wrk.sv_cntrct_qual_prod_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS qual_st_dt,
       CAST(NULL AS DATE) AS qual_end_dt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_qual_prod_ms_toc.sql"

# ============================================================================
# Model 3: Contracted Pricing
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_prod_cntrctd_prc_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Contracted Pricing for Qualified Products
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Gets contracted price for each qualified product
    - Uses most recent price effective within compliance period
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - prod_id: Product ID
    - cntrctd_prc: Contracted unit price
    - eff_st_dt: Effective start date
    - eff_end_dt: Effective end date
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.dim_cntrc_prod_line_item
    - int_cntrct_qual_prod_ms_toc
    
    Target: md_wrk.sv_cntrct_prod_cntrctd_prc_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DECIMAL(18,4)) AS cntrctd_prc,
       CAST(NULL AS DATE) AS eff_st_dt,
       CAST(NULL AS DATE) AS eff_end_dt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_prod_cntrctd_prc_ms_toc.sql"

# ============================================================================
# Model 4: Sales Transactions
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_sls_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Sales Data for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Transaction-level sales for qualified products
    - Filtered to compliance period date range
    - Foundation for market share calculations
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - cust_id: Customer ID
    - prod_id: Product ID
    - trnsc_dt: Transaction date
    - qty_sold: Quantity sold
    - net_sls_amt: Net sales amount
    - gross_sls_amt: Gross sales amount
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.sv_fact_transaction
    - int_cntrct_qual_prod_ms_toc
    
    Target: md_wrk.sv_cntrct_sls_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cust_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS trnsc_dt,
       CAST(NULL AS DECIMAL(18,4)) AS qty_sold,
       CAST(NULL AS DECIMAL(18,2)) AS net_sls_amt,
       CAST(NULL AS DECIMAL(18,2)) AS gross_sls_amt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_sls_ms_toc.sql"

# ============================================================================
# Model 5: IDN Facts
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_fct_tr_idn_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Transaction Facts at IDN Level
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Rolls up sales to IDN (Integrated Delivery Network) level
    - Uses customer hierarchy to map customers to IDNs
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - idn_id: IDN ID
    - idn_nm: IDN name
    - cust_id: Customer ID
    - prod_id: Product ID
    - trnsc_dt: Transaction date
    - qty_sold: Quantity sold
    - net_sls_amt: Net sales amount
    - gross_sls_amt: Gross sales amount
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - int_cntrct_sls_ms_toc
    - md_dwh.hier_cust
    
    Target: md_wrk.sv_cntrct_fct_tr_idn_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS VARCHAR) AS idn_nm,
       CAST(NULL AS VARCHAR) AS cust_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS trnsc_dt,
       CAST(NULL AS DECIMAL(18,4)) AS qty_sold,
       CAST(NULL AS DECIMAL(18,2)) AS net_sls_amt,
       CAST(NULL AS DECIMAL(18,2)) AS gross_sls_amt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_fct_tr_idn_ms_toc.sql"

# ============================================================================
# Model 6: Facility Facts
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_fct_tr_fclty_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Transaction Facts at Facility Level
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Keeps sales at facility/customer level
    - Joins with account dimension for facility names
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - fclty_id: Facility ID
    - fclty_nm: Facility name
    - prod_id: Product ID
    - trnsc_dt: Transaction date
    - qty_sold: Quantity sold
    - net_sls_amt: Net sales amount
    - gross_sls_amt: Gross sales amount
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - int_cntrct_sls_ms_toc
    - md_dwh.dim_acct
    
    Target: md_wrk.sv_cntrct_fct_tr_fclty_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS fclty_id,
       CAST(NULL AS VARCHAR) AS fclty_nm,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS trnsc_dt,
       CAST(NULL AS DECIMAL(18,4)) AS qty_sold,
       CAST(NULL AS DECIMAL(18,2)) AS net_sls_amt,
       CAST(NULL AS DECIMAL(18,2)) AS gross_sls_amt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_fct_tr_fclty_ms_toc.sql"

# ============================================================================
# Model 7: IDN Compliance Validation
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_idn_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    IDN Market Share Calculation
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Calculates market share % at IDN level
    - Formula: (Qualified Product Sales / Total IDN Sales) * 100
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - idn_id: IDN ID
    - idn_ms_pct: Market share percentage (0-100)
    - total_idn_sls: Total IDN sales amount
    - qualified_idn_sls: Qualified product sales at IDN level
    - total_idn_qty: Total IDN quantity
    - qualified_idn_qty: Qualified IDN quantity
    
    Source Tables:
    - int_cntrct_fct_tr_idn_ms_toc
    - int_cntrct_qual_prod_ms_toc
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_idn_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS DECIMAL(10,4)) AS idn_ms_pct,
       CAST(NULL AS DECIMAL(18,2)) AS total_idn_sls,
       CAST(NULL AS DECIMAL(18,2)) AS qualified_idn_sls,
       CAST(NULL AS DECIMAL(18,4)) AS total_idn_qty,
       CAST(NULL AS DECIMAL(18,4)) AS qualified_idn_qty
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_idn_ms_toc.sql"

# ============================================================================
# Model 8: IDN Ranked Compliance
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    IDN Tier Achievement
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Assigns tier based on calculated MS%
    - Uses tier thresholds from component definition
    - Selects highest tier achieved
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - idn_id: IDN ID
    - idn_ms_pct: Market share percentage
    - total_idn_sls: Total sales amount
    - qualified_idn_sls: Qualified sales amount
    - achieved_tier_num: Tier number achieved
    - tier_min_pct: Tier minimum percentage
    - tier_max_pct: Tier maximum percentage
    - rebate_amt: Rebate amount
    - rebate_pct: Rebate percentage
    - calculated_rebate_amt: Calculated rebate amount
    
    Source Tables:
    - int_cntrct_cmplnc_vldtn_idn_ms_toc
    - int_cntrct_tier_components_ms
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS DECIMAL(10,4)) AS idn_ms_pct,
       CAST(NULL AS DECIMAL(18,2)) AS total_idn_sls,
       CAST(NULL AS DECIMAL(18,2)) AS qualified_idn_sls,
       CAST(NULL AS DECIMAL(18,4)) AS total_idn_qty,
       CAST(NULL AS DECIMAL(18,4)) AS qualified_idn_qty,
       CAST(NULL AS INTEGER) AS achieved_tier_num,
       CAST(NULL AS DECIMAL(10,4)) AS tier_min_pct,
       CAST(NULL AS DECIMAL(10,4)) AS tier_max_pct,
       CAST(NULL AS DECIMAL(18,2)) AS rebate_amt,
       CAST(NULL AS DECIMAL(10,4)) AS rebate_pct,
       CAST(NULL AS DECIMAL(18,2)) AS calculated_rebate_amt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.sql"

# ============================================================================
# Model 9: Facility Compliance Validation
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_fclty_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Facility Market Share Calculation
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Calculates market share % at facility level
    - Formula: (Qualified Product Sales / Total Facility Sales) * 100
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - fclty_id: Facility ID
    - fclty_ms_pct: Market share percentage (0-100)
    - total_fclty_sls: Total facility sales amount
    - qualified_fclty_sls: Qualified product sales at facility level
    - total_fclty_qty: Total facility quantity
    - qualified_fclty_qty: Qualified facility quantity
    
    Source Tables:
    - int_cntrct_fct_tr_fclty_ms_toc
    - int_cntrct_qual_prod_ms_toc
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_fclty_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS fclty_id,
       CAST(NULL AS DECIMAL(10,4)) AS fclty_ms_pct,
       CAST(NULL AS DECIMAL(18,2)) AS total_fclty_sls,
       CAST(NULL AS DECIMAL(18,2)) AS qualified_fclty_sls,
       CAST(NULL AS DECIMAL(18,4)) AS total_fclty_qty,
       CAST(NULL AS DECIMAL(18,4)) AS qualified_fclty_qty
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_fclty_ms_toc.sql"

# ============================================================================
# Model 10: Facility Ranked Compliance
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Facility Tier Achievement
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Assigns tier based on calculated MS%
    - Uses tier thresholds from component definition
    - Selects highest tier achieved
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - fclty_id: Facility ID
    - fclty_ms_pct: Market share percentage
    - total_fclty_sls: Total sales amount
    - qualified_fclty_sls: Qualified sales amount
    - achieved_tier_num: Tier number achieved
    - tier_min_pct: Tier minimum percentage
    - tier_max_pct: Tier maximum percentage
    - rebate_amt: Rebate amount
    - rebate_pct: Rebate percentage
    - calculated_rebate_amt: Calculated rebate amount
    
    Source Tables:
    - int_cntrct_cmplnc_vldtn_fclty_ms_toc
    - int_cntrct_tier_components_ms
    
    Target: md_wrk.sv_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS fclty_id,
       CAST(NULL AS DECIMAL(10,4)) AS fclty_ms_pct,
       CAST(NULL AS DECIMAL(18,2)) AS total_fclty_sls,
       CAST(NULL AS DECIMAL(18,2)) AS qualified_fclty_sls,
       CAST(NULL AS DECIMAL(18,4)) AS total_fclty_qty,
       CAST(NULL AS DECIMAL(18,4)) AS qualified_fclty_qty,
       CAST(NULL AS INTEGER) AS achieved_tier_num,
       CAST(NULL AS DECIMAL(10,4)) AS tier_min_pct,
       CAST(NULL AS DECIMAL(10,4)) AS tier_max_pct,
       CAST(NULL AS DECIMAL(18,2)) AS rebate_amt,
       CAST(NULL AS DECIMAL(10,4)) AS rebate_pct,
       CAST(NULL AS DECIMAL(18,2)) AS calculated_rebate_amt
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc.sql"

# ============================================================================
# Model 11: Comprehensive Fact Table
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmprhnsv_fct_tr_ms_toc.sql << 'EOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation'],
        post_hook="ANALYZE {{ this }}" if execute else none
    )
}}

/*
    Comprehensive MS TOC Fact Table
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Combines all MS TOC components into single fact table
    - Transaction-level detail with compliance metrics
    - Foundation for final mart
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - cust_id: Customer ID
    - prod_id: Product ID
    - trnsc_dt: Transaction date
    - qty_sold: Quantity sold
    - net_sls_amt: Net sales amount
    - gross_sls_amt: Gross sales amount
    - eligible_cust_id: Eligible customer ID
    - is_qualified_prod: Flag if product is qualified
    - cntrctd_prc: Contracted price
    - idn_id: IDN ID
    - idn_nm: IDN name
    - idn_ms_pct: IDN market share percentage
    - idn_tier_achieved: IDN tier achieved
    - idn_rebate_amt: IDN rebate amount
    - fclty_ms_pct: Facility market share percentage
    - fclty_tier_achieved: Facility tier achieved
    - fclty_rebate_amt: Facility rebate amount
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    - load_ts: Load timestamp
    
    Source Tables:
    - int_cntrct_sls_ms_toc
    - int_cntrct_elgbl_cust_ms_toc
    - int_cntrct_qual_prod_ms_toc
    - int_cntrct_prod_cntrctd_prc_ms_toc
    - int_cntrct_fct_tr_idn_ms_toc
    - int_cntrct_fct_tr_fclty_ms_toc
    - int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
    - int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
    
    Target: md_wrk.sv_cntrct_cmprhnsv_fct_tr_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cust_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS trnsc_dt,
       CAST(NULL AS DECIMAL(18,4)) AS qty_sold,
       CAST(NULL AS DECIMAL(18,2)) AS net_sls_amt,
       CAST(NULL AS DECIMAL(18,2)) AS gross_sls_amt,
       CAST(NULL AS VARCHAR) AS eligible_cust_id,
       CAST(NULL AS INTEGER) AS is_qualified_prod,
       CAST(NULL AS DECIMAL(18,4)) AS cntrctd_prc,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS VARCHAR) AS idn_nm,
       CAST(NULL AS DECIMAL(10,4)) AS idn_ms_pct,
       CAST(NULL AS INTEGER) AS idn_tier_achieved,
       CAST(NULL AS DECIMAL(18,2)) AS idn_rebate_amt,
       CAST(NULL AS DECIMAL(10,4)) AS fclty_ms_pct,
       CAST(NULL AS INTEGER) AS fclty_tier_achieved,
       CAST(NULL AS DECIMAL(18,2)) AS fclty_rebate_amt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt,
       CAST(NULL AS TIMESTAMP) AS load_ts
WHERE FALSE
EOF
echo "✅ Created: int_cntrct_cmprhnsv_fct_tr_ms_toc.sql"

# ============================================================================
# YAML Documentation
# ============================================================================
cat > models/intermediate/ms_toc/_ms_toc.yml << 'EOF'
version: 2

models:
  - name: int_cntrct_elgbl_cust_ms_toc
    description: 'Eligible customers for Market Share TOC compliance periods'
    columns:
      - name: cntrc_id
        description: 'Contract ID'
      - name: prc_prg_id
        description: 'Pricing program ID'
      - name: cmpnt_id
        description: 'Component ID'
      - name: cmt_cust_id
        description: 'Compliant customer ID'
      - name: elig_st_dt
        description: 'Customer eligibility start date'
      - name: elig_end_dt
        description: 'Customer eligibility end date'
      - name: compli_per_strt_dt
        description: 'Compliance period start date'
      - name: compli_per_end_dt
        description: 'Compliance period end date'

  - name: int_cntrct_qual_prod_ms_toc
    description: 'Qualified products for Market Share TOC compliance'
    columns:
      - name: cntrc_id
        description: 'Contract ID'
      - name: prc_prg_id
        description: 'Pricing program ID'
      - name: cmpnt_id
        description: 'Component ID'
      - name: prod_id
        description: 'Product ID'
      - name: qual_st_dt
        description: 'Product qualification start date'
      - name: qual_end_dt
        description: 'Product qualification end date'
      - name: compli_per_strt_dt
        description: 'Compliance period start date'
      - name: compli_per_end_dt
        description: 'Compliance period end date'

  - name: int_cntrct_prod_cntrctd_prc_ms_toc
    description: 'Contracted pricing for qualified products in TOC'
    columns:
      - name: cntrc_id
        description: 'Contract ID'
      - name: cntrctd_prc
        description: 'Contracted unit price'

  - name: int_cntrct_sls_ms_toc
    description: 'Sales transactions filtered for MS TOC compliance periods'
    columns:
      - name: net_sls_amt
        description: 'Net sales amount'
      - name: qty_sold
        description: 'Quantity sold'

  - name: int_cntrct_fct_tr_idn_ms_toc
    description: 'Transaction facts rolled up to IDN (Integrated Delivery Network) level'
    columns:
      - name: idn_id
        description: 'IDN ID'
      - name: idn_nm
        description: 'IDN name'

  - name: int_cntrct_fct_tr_fclty_ms_toc
    description: 'Transaction facts at facility/customer level'
    columns:
      - name: fclty_id
        description: 'Facility/Customer ID'
      - name: fclty_nm
        description: 'Facility/Customer name'

  - name: int_cntrct_cmplnc_vldtn_idn_ms_toc
    description: 'IDN-level market share percentage calculations'
    columns:
      - name: idn_id
        description: 'IDN ID'
      - name: idn_ms_pct
        description: 'Calculated IDN market share percentage (0-100)'
      - name: total_idn_sls
        description: 'Total IDN sales amount'
      - name: qualified_idn_sls
        description: 'Qualified product sales at IDN level'

  - name: int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
    description: 'IDN compliance with tier achievement and rebate calculations'
    columns:
      - name: idn_id
        description: 'IDN ID'
      - name: achieved_tier_num
        description: 'Tier number achieved based on MS%'
      - name: idn_ms_pct
        description: 'Market share percentage at IDN level'
      - name: calculated_rebate_amt
        description: 'Calculated rebate amount for IDN'

  - name: int_cntrct_cmplnc_vldtn_fclty_ms_toc
    description: 'Facility-level market share percentage calculations'
    columns:
      - name: fclty_id
        description: 'Facility ID'
      - name: fclty_ms_pct
        description: 'Calculated facility market share percentage (0-100)'
      - name: total_fclty_sls
        description: 'Total facility sales amount'
      - name: qualified_fclty_sls
        description: 'Qualified product sales at facility level'

  - name: int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
    description: 'Facility compliance with tier achievement and rebate calculations'
    columns:
      - name: fclty_id
        description: 'Facility ID'
      - name: achieved_tier_num
        description: 'Tier number achieved based on MS%'
      - name: fclty_ms_pct
        description: 'Market share percentage at facility level'
      - name: calculated_rebate_amt
        description: 'Calculated rebate amount for facility'

  - name: int_cntrct_cmprhnsv_fct_tr_ms_toc
    description: 'Comprehensive MS TOC fact table combining all components'
    columns:
      - name: cntrc_id
        description: 'Contract ID'
      - name: prc_prg_id
        description: 'Pricing program ID'
      - name: cmpnt_id
        description: 'Component ID'
      - name: cust_id
        description: 'Customer ID'
      - name: prod_id
        description: 'Product ID'
      - name: trnsc_dt
        description: 'Transaction date'
      - name: is_qualified_prod
        description: 'Flag: 1 if product is qualified, 0 otherwise'
      - name: idn_ms_pct
        description: 'IDN market share percentage'
      - name: fclty_ms_pct
        description: 'Facility market share percentage'
EOF
echo "✅ Created: _ms_toc.yml"

echo ""
echo "✅ =============================================="
echo "✅ All 11 MS TOC documentation models created!"
echo "✅ =============================================="
echo ""
echo "Files created:"
echo "  - 11 SQL models (empty views with column documentation)"
echo "  - 1 YAML documentation file"
echo ""
echo "Next steps:"
echo "  1. cd radar"
echo "  2. dbt parse --models tag:ms tag:toc"
echo "  3. dbt docs generate"
echo ""