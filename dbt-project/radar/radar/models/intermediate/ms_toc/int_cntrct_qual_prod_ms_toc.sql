{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Qualified Products for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Identifies products that qualify for market share calculations
    - Filters products based on contract component specifications
    - Links to compliance periods
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS VARCHAR) AS prod_ctgry_id,
       CAST(NULL AS DATE) AS qual_st_dt,
       CAST(NULL AS DATE) AS qual_end_dt
FROM {{ source('md_dwh', 'dim_prc_cmpnt_qual_prod') }} qual
INNER JOIN {{ ref('int_cntrct_tier_components_ms') }} tier
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cper
WHERE FALSE
