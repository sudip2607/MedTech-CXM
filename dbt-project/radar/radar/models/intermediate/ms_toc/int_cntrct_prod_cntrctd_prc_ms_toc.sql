{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Product Contracted Pricing for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Maps contract pricing for qualified products
    - Provides pricing tiers and discount levels
    - Links pricing to product and contract components
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DECIMAL(10,2)) AS cntrctd_prc,
       CAST(NULL AS DECIMAL(10,2)) AS lst_prc,
       CAST(NULL AS DECIMAL(5,2)) AS dscnt_pct
FROM {{ source('md_dwh', 'fct_prc_cmpnt_prod_cntrctd') }} prc
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cper
INNER JOIN {{ ref('int_cntrct_tier_components_ms') }} tier
WHERE FALSE
