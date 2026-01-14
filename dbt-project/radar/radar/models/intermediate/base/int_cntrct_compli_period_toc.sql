{{
    config(
        materialized='view',
        tags=['base', 'foundation', 'toc']
    )
}}

/*
    Compliance Period - Time of Compliance (TOC)
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Latest compliance period per contract/program/component
    - Time of Compliance = single snapshot period (most recent)
    - Rank 1 = most recent compliance period
    - Shared across all TOC workflows
    
    Filtering:
    - Only rank = 1 (latest period)
    - Scopes: 'no_cust' (contract-level), 'with_cust' (customer-level)
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmt_cust_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS DATE) AS per_strt_dt,
       CAST(NULL AS DATE) AS per_end_dt,
       CAST(NULL AS VARCHAR) AS rank_scope,
       CAST(NULL AS INTEGER) AS rnk
FROM {{ source('md_dwh', 'dim_prc_prg_cmpli_per_rslts') }} cper
INNER JOIN {{ ref('int_cntrct_rcnt_period') }} rcnt
WHERE FALSE
