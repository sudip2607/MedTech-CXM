{{
    config(
        materialized='view',
        tags=['base', 'foundation', 'anltcs']
    )
}}

/*
    Compliance Period - Analytics (All Periods)
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - All historical compliance periods (not just latest)
    - Used for trend analysis and historical compliance
    - Time series dimension
    - Foundation for ANLTCS workflows
    
    Filtering:
    - No rank filter (includes all periods)
    - Shared across MS ANLTCS and NMS ANLTCS workflows
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmt_cust_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS DATE) AS per_strt_dt,
       CAST(NULL AS DATE) AS per_end_dt,
       CAST(NULL AS INTEGER) AS per_num
FROM {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }} cper
WHERE FALSE
