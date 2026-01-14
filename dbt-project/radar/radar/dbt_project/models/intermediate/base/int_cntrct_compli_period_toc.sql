{{
    config(
        materialized='table',
        tags=['base', 'compliance', 'toc'],
        post_hook="ANALYZE {{ this }}"
    )
}}

/*
    Compliance Period - Time of Compliance (Latest Period Only)
    
    Business Logic:
    - Returns latest compliance period per contract/program/component
    - Two scopes:
      * 'no_cust': Aggregate level (no customer breakdown)
      * 'with_cust': Customer-level breakdown
    - Used for TOC (Time of Compliance) reporting
    
    Source: md_dwh.dim_prc_prg_cmpli_per_rslts
    Target: md_wrk.sv_cntrct_compli_period_toc
*/

WITH base_prod AS (
    SELECT DISTINCT
        dppcprv.cntrc_id,
        dppcprv.prc_prg_id,
        NULL AS cmt_cust_id,
        dppcprv.cmpnt_id,
        dppcprv.per_strt_dt,
        dppcprv.per_end_dt,
        ROW_NUMBER() OVER (
            PARTITION BY dppcprv.cntrc_id, dppcprv.prc_prg_id, dppcprv.cmpnt_id
            ORDER BY dppcprv.per_end_dt DESC
        ) AS rnk,
        'no_cust' AS rank_scope
    FROM {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }} dppcprv
    JOIN {{ ref('int_cntrct_rcnt_period') }} dcv
        ON dcv.cntrc_id = dppcprv.cntrc_id
    WHERE dppcprv.per_end_dt <= CURRENT_DATE
        AND dppcprv.per_end_dt <= dcv.cntrc_end_dt
),

base_cust AS (
    SELECT DISTINCT
        dppcprv.cntrc_id,
        dppcprv.prc_prg_id,
        dppcprv.cmt_cust_id,
        dppcprv.cmpnt_id,
        dppcprv.per_strt_dt,
        dppcprv.per_end_dt,
        ROW_NUMBER() OVER (
            PARTITION BY dppcprv.cntrc_id, dppcprv.prc_prg_id, dppcprv.cmpnt_id, dppcprv.cmt_cust_id
            ORDER BY dppcprv.per_end_dt DESC
        ) AS rnk,
        'with_cust' AS rank_scope
    FROM {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }} dppcprv
    JOIN {{ ref('int_cntrct_rcnt_period') }} dcv
        ON dcv.cntrc_id = dppcprv.cntrc_id
    WHERE dppcprv.per_end_dt <= CURRENT_DATE
        AND dppcprv.per_end_dt <= dcv.cntrc_end_dt
)

SELECT
    cntrc_id,
    prc_prg_id,
    cmt_cust_id,
    cmpnt_id,
    per_strt_dt,
    per_end_dt,
    rank_scope
FROM base_prod
WHERE rnk = 1

UNION ALL

SELECT
    cntrc_id,
    prc_prg_id,
    cmt_cust_id,
    cmpnt_id,
    per_strt_dt,
    per_end_dt,
    rank_scope
FROM base_cust
WHERE rnk = 1