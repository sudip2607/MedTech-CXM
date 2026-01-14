{{
    config(
        materialized='view',
        tags=['base', 'foundation', 'ms', 'market_share']
    )
}}

/*
    Tier Components - Market Share (MS)
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Contract tier definitions with Market Share basis
    - Defines tier boundaries and rebate rates for MS compliance
    - Links pricing program to components
    - Foundation for MS workflows (TOC + ANLTCS)
    
    Filtering:
    - tier_basis_type = 'MARKET SHARE'
    - Rank 1 = latest tier configuration
    - Scopes for contract and customer levels
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cmpnt_nm,
       CAST(NULL AS INTEGER) AS tier_num,
       CAST(NULL AS DECIMAL(10,4)) AS tier_min_pct,
       CAST(NULL AS DECIMAL(10,4)) AS tier_max_pct,
       CAST(NULL AS DECIMAL(5,2)) AS rebate_pct,
       CAST(NULL AS VARCHAR) AS tier_basis_type
FROM {{ source('md_dwh', 'dim_prc_prg_cmpnt') }} cmpnt
INNER JOIN {{ source('md_dwh', 'dim_prc_prg') }} prg
INNER JOIN {{ ref('int_cntrct_rcnt_period') }} rcnt
WHERE FALSE
