{{
    config(
        materialized='table',
        tags=['base', 'foundation'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Recent Contract Period Base Model
    
    Business Logic:
    - Filters contracts active within last 24 months (configurable)
    - Foundation for all downstream MS/NMS workflows
    
    Source: md_dwh.dim_cntrc
    Target: md_wrk.sv_cntrct_rcnt_period
*/

SELECT
    cntrc_id,
    cntrc_sts,
    cntrc_nm,
    cntrc_strt_dt,
    cntrc_end_dt
FROM {{ source('md_dwh', 'dim_cntrc') }}
WHERE cntrc_end_dt >= DATEADD(
    month,
    -{{ var('recent_contract_months', 24) }},
    CURRENT_DATE
)