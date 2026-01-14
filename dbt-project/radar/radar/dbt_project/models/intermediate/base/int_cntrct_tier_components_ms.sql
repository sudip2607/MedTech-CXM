{{
    config(
        materialized='table',
        tags=['base', 'market_share', 'tiers'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Tier Components - Market Share
    
    Business Logic:
    - Filters components with tier_basis_type = 'MARKET SHARE'
    - Contains tier structure (min/max MS percentages)
    - Foundation for MS compliance calculations
    
    Source: md_dwh.dim_prc_prg_cmpnt, dim_prc_prg
    Target: md_wrk.sv_cntrct_tier_components_ms
*/

SELECT DISTINCT
    c.cntrc_id,
    c.prc_prg_id,
    c.cmpnt_id,
    c.tier_num,
    c.cntrc_cmpnt_nm,
    c.cmpnt_nm,
    c.tier_basis_type,
    p.tier_tmfrm,
    c.src_eff_strt_dt::DATE AS tier_st_dt,
    c.src_eff_end_dt::DATE AS tier_end_dt,
    cn.cntrc_sts,
    cn.cntrc_strt_dt,
    cn.cntrc_end_dt
FROM {{ source('md_dwh', 'dim_prc_prg_cmpnt') }} c
JOIN {{ source('md_dwh', 'dim_prc_prg') }} p
    ON c.prc_prg_id = p.prc_prg_id
    AND c.cntrc_id = p.cntrc_id
JOIN {{ ref('int_cntrct_rcnt_period') }} cn
    ON cn.cntrc_id = p.cntrc_id
WHERE UPPER(c.tier_basis_type) = 'MARKET SHARE'