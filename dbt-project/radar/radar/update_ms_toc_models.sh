#!/bin/bash

set -e

echo "🚀 Updating MS TOC Models..."
echo ""

# Remove old manifest
rm -rf target/manifest.json

# ============================================================================
# Model 1: Eligible Customers
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_elgbl_cust_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Eligible Customers for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Identifies eligible customers for market share compliance
    - Joins customer eligibility with compliance periods
    - Filters to latest compliance period (TOC)
    
    Sources:
    - {{ source('md_dwh', 'dim_prc_cmpnt_cust_elig') }}
    - {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }}
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
SQLEOF
echo "✅ Created: int_cntrct_elgbl_cust_ms_toc.sql"

# ============================================================================
# Model 2: Qualified Products
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_qual_prod_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Qualified Products for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Sources:
    - {{ source('md_dwh', 'dim_prc_cmpnt_qual_prod') }}
    - {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }}
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
SQLEOF
echo "✅ Created: int_cntrct_qual_prod_ms_toc.sql"

# ============================================================================
# Model 3: Contracted Pricing
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_prod_cntrctd_prc_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Contracted Pricing for Qualified Products
    
    **STATUS:** Documentation Model (No actual data)
    
    Sources:
    - {{ source('md_dwh', 'dim_cntrc_prod_line_item') }}
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
SQLEOF
echo "✅ Created: int_cntrct_prod_cntrctd_prc_ms_toc.sql"

# ============================================================================
# Model 4: Sales Transactions
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_sls_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Sales Data for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Sources:
    - {{ source('md_dwh', 'sv_fact_transaction') }}
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
SQLEOF
echo "✅ Created: int_cntrct_sls_ms_toc.sql"

# ============================================================================
# Model 5: IDN Facts
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_fct_tr_idn_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Transaction Facts at IDN Level
    
    **STATUS:** Documentation Model (No actual data)
    
    Sources:
    - {{ source('md_dwh', 'sv_fact_transaction') }}
    - {{ source('md_dwh', 'hier_cust') }}
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
SQLEOF
echo "✅ Created: int_cntrct_fct_tr_idn_ms_toc.sql"

# ============================================================================
# Model 6: Facility Facts
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_fct_tr_fclty_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Transaction Facts at Facility Level
    
    **STATUS:** Documentation Model (No actual data)
    
    Sources:
    - {{ source('md_dwh', 'sv_fact_transaction') }}
    - {{ source('md_dwh', 'dim_acct') }}
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
SQLEOF
echo "✅ Created: int_cntrct_fct_tr_fclty_ms_toc.sql"

# ============================================================================
# Model 7: IDN Compliance Validation
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_idn_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    IDN Market Share Calculation
    
    **STATUS:** Documentation Model (No actual data)
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
SQLEOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_idn_ms_toc.sql"

# ============================================================================
# Model 8: IDN Ranked Compliance
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    IDN Tier Achievement
    
    **STATUS:** Documentation Model (No actual data)
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
SQLEOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc.sql"

# ============================================================================
# Model 9: Facility Compliance Validation
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_fclty_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Facility Market Share Calculation
    
    **STATUS:** Documentation Model (No actual data)
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
SQLEOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_fclty_ms_toc.sql"

# ============================================================================
# Model 10: Facility Ranked Compliance
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Facility Tier Achievement
    
    **STATUS:** Documentation Model (No actual data)
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
SQLEOF
echo "✅ Created: int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc.sql"

# ============================================================================
# Model 11: Comprehensive Fact Table
# ============================================================================
cat > models/intermediate/ms_toc/int_cntrct_cmprhnsv_fct_tr_ms_toc.sql << 'SQLEOF'
{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Comprehensive MS TOC Fact Table
    
    **STATUS:** Documentation Model (No actual data)
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
SQLEOF
echo "✅ Created: int_cntrct_cmprhnsv_fct_tr_ms_toc.sql"

# ============================================================================
# YAML Documentation
# ============================================================================
cat > models/intermediate/ms_toc/_ms_toc.yml << 'YMLEOF'
version: 2

sources:
  - name: md_dwh
    description: 'Master Data Warehouse'
    tables:
      - name: dim_prc_cmpnt_cust_elig
        description: 'Customer eligibility dimension'
      - name: dim_prc_cmpnt_qual_prod
        description: 'Product qualification dimension'
      - name: dim_cntrc_prod_line_item
        description: 'Contract product line items'
      - name: sv_fact_transaction
        description: 'Transaction fact table'
      - name: hier_cust
        description: 'Customer hierarchy'
      - name: dim_acct
        description: 'Account/Facility dimension'
      - name: dim_prc_prg_cmpli_per_rslts
        description: 'Compliance period results'

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

  - name: int_cntrct_qual_prod_ms_toc
    description: 'Qualified products for Market Share TOC compliance'

  - name: int_cntrct_prod_cntrctd_prc_ms_toc
    description: 'Contracted pricing for qualified products in TOC'

  - name: int_cntrct_sls_ms_toc
    description: 'Sales transactions filtered for MS TOC compliance periods'

  - name: int_cntrct_fct_tr_idn_ms_toc
    description: 'Transaction facts rolled up to IDN level'

  - name: int_cntrct_fct_tr_fclty_ms_toc
    description: 'Transaction facts at facility/customer level'

  - name: int_cntrct_cmplnc_vldtn_idn_ms_toc
    description: 'IDN-level market share percentage calculations'

  - name: int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc
    description: 'IDN compliance with tier achievement and rebate calculations'

  - name: int_cntrct_cmplnc_vldtn_fclty_ms_toc
    description: 'Facility-level market share percentage calculations'

  - name: int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc
    description: 'Facility compliance with tier achievement and rebate calculations'

  - name: int_cntrct_cmprhnsv_fct_tr_ms_toc
    description: 'Comprehensive MS TOC fact table combining all components'
YMLEOF
echo "✅ Created: _ms_toc.yml"

echo ""
echo "✅ =============================================="
echo "✅ All MS TOC models updated successfully!"
echo "✅ =============================================="
echo ""
echo "Next steps:"
echo "  dbt parse"
echo "  dbt docs generate"
echo "  open target/index.html"
