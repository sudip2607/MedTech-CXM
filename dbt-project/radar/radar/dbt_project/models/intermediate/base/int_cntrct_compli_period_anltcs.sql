{{
    config(
        materialized='table',
        tags=['base', 'compliance', 'analytics'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Compliance Period - Analytics (All Historical Periods)
    
    Business Logic:
    - Returns ALL compliance periods (not just latest)
    - Used for analytics and trending over time
    - No ranking - includes full history
    
    Source: md_dwh.dim_prc_prg_cmpli_per_rslts
    Target: md_wrk.sv_cntrct_compli_period_anltcs
*/

SELECT DISTINCT
    cntrc_id,
    prc_prg_id,
    cmpnt_id,
    cmt_cust_id,
    per_strt_dt,
    per_end_dt
FROM {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }}
WHERE CURRENT_DATE BETWEEN per_strt_dt AND per_end_dt