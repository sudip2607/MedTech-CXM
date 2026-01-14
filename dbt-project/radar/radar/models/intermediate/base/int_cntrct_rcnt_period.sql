{{
    config(
        materialized='view',
        tags=['base', 'foundation']
    )
}}

/*
    Recent Contracts (24-Month Window)
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Filters contracts within last 24 months
    - Foundation model for all contract compliance analysis
    - Shared across all workflows (MS TOC, MS ANLTCS, NMS TOC, NMS ANLTCS)
    
    Filter:
    - contract_end_date >= CURRENT_DATE - 24 months
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS cntrc_nm,
       CAST(NULL AS VARCHAR) AS cntrc_sts,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS DATE) AS cntrc_strt_dt,
       CAST(NULL AS DATE) AS cntrc_end_dt,
       CAST(NULL AS DATE) AS load_dt
FROM {{ source('md_dwh', 'dim_cntrc') }} cntrc
WHERE FALSE
