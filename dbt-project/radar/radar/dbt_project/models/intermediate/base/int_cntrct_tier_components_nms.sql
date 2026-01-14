{{
    config(
        materialized='table',
        tags=['base', 'non_market_share', 'tiers'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Tier Components - Non-Market Share
    
    Business Logic:
    - Filters components where tier_basis_type <> 'MARKET SHARE'
    - Includes volume-based, value-based tiers
    - Takes most recent tier per contract (ROW_NUMBER = 1)
    
    Source: md_dwh.dim_prc_prg_cmpnt, dim_prc_prg
    Target: md_wrk.sv_cntrct_tier_components_nms
*/

WITH ranked_components AS (
    SELECT
        c.cntrc_id,
        c.prc_prg_id,
        c.cmpnt_id,
        c.tier_num,
        c.cntrc_cmpnt_nm,
        c.tier_basis_type,
        ac.cntrc_sts,
        ac.cntrc_strt_dt,
        ac.cntrc_end_dt,
        p.tier_tmfrm,
        c.src_eff_strt_dt::DATE AS tier_st_dt,
        c.src_eff_end_dt::DATE AS tier_end_dt,
        ROW_NUMBER() OVER (PARTITION BY c.cntrc_id ORDER BY c.src_eff_strt_dt DESC) AS rnk
    FROM {{ source('md_dwh', 'dim_prc_prg_cmpnt') }} c
    INNER JOIN {{ source('md_dwh', 'dim_prc_prg') }} p
        ON c.prc_prg_id = p.prc_prg_id
        AND c.cntrc_id = p.cntrc_id
    INNER JOIN {{ ref('int_cntrct_rcnt_period') }} ac
        ON p.cntrc_id = ac.cntrc_id
    WHERE UPPER(c.tier_basis_type) <> 'MARKET SHARE'
        AND c.tier_basis_type IS NOT NULL
        AND TRUNC(c.src_eff_strt_dt) <= CURRENT_DATE
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    tier_num,
    cntrc_cmpnt_nm,
    tier_basis_type,
    tier_tmfrm,
    tier_st_dt,
    tier_end_dt,
    cntrc_sts,
    cntrc_strt_dt,
    cntrc_end_dt
FROM ranked_components
WHERE rnk = 1