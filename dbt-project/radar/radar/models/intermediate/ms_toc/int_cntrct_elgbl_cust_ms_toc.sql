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
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cmt_cust_id,
       CAST(NULL AS DATE) AS elig_st_dt,
       CAST(NULL AS DATE) AS elig_end_dt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
FROM {{ source('md_dwh', 'dim_prc_cmpnt_cust_elig') }} elig
INNER JOIN {{ ref('int_cntrct_tier_components_ms') }} tier
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cper
WHERE FALSE
