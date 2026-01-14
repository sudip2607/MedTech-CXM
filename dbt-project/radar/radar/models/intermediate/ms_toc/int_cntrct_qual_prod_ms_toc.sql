{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Qualified Products for MS TOC
    
    Business Logic:
    - Identifies products that qualify for market share calculations
    - Combines products with contracted prices and component qualifications
    - Links to compliance periods for time-bound validity
*/

WITH contracted_products AS (
    SELECT 
        cntrc_id,
        prc_prg_id,
        cmpnt_id,
        prod_id
    FROM {{ ref('int_cntrct_prod_cntrctd_prc_ms_toc') }}
),

qualified_products AS (
    SELECT
        qual.cntrc_id,
        qual.prc_prg_id,
        qual.cmpnt_id,
        qual.prod_id,
        qual.prod_ctgry_id
    FROM {{ source('md_dwh', 'dim_prc_cmpnt_qual_prod') }} qual
    INNER JOIN {{ ref('int_cntrct_tier_components_ms') }} tier
        ON qual.cntrc_id = tier.cntrc_id
        AND qual.prc_prg_id = tier.prc_prg_id
        AND qual.cmpnt_id = tier.cmpnt_id
)

SELECT 
    cp.cntrc_id,
    cp.prc_prg_id,
    cp.cmpnt_id,
    cp.prod_id,
    qp.prod_ctgry_id,
    cper.per_strt_dt AS qual_st_dt,
    cper.per_end_dt AS qual_end_dt
FROM contracted_products cp
INNER JOIN qualified_products qp
    ON cp.cntrc_id = qp.cntrc_id
    AND cp.prc_prg_id = qp.prc_prg_id
    AND cp.cmpnt_id = qp.cmpnt_id
    AND cp.prod_id = qp.prod_id
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cper
    ON cp.cntrc_id = cper.cntrc_id
