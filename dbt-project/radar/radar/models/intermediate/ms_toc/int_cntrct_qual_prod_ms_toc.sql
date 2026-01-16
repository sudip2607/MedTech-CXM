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
    - Filters products based on component qualifications
    - Links to compliance periods for time-bound validity
*/

SELECT
    qual.cntrc_id,
    qual.prc_prg_id,
    qual.cmpnt_id,
    qual.prod_id,
    qual.prod_ctgry_id,
    cper.per_strt_dt AS qual_st_dt,
    cper.per_end_dt AS qual_end_dt
FROM {{ source('md_dwh', 'dim_prc_cmpnt_qual_prod') }} qual
INNER JOIN {{ ref('int_cntrct_tier_components_ms') }} tier
    ON qual.cntrc_id = tier.cntrc_id
    AND qual.prc_prg_id = tier.prc_prg_id
    AND qual.cmpnt_id = tier.cmpnt_id
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} cper
    ON qual.cntrc_id = cper.cntrc_id
