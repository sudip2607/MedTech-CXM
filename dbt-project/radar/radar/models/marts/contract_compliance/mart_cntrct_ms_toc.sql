{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'mart', 'documentation']
    )
}}

/*
    Market Share Time of Compliance Mart
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Final reporting table for MS TOC compliance
    - Aggregated metrics at contract/program/component level
    - Latest compliance period snapshot
    - Ready for BI/Dashboard consumption
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS cntrc_nm,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cmpnt_nm,
       CAST(NULL AS DECIMAL(10,4)) AS overall_ms_pct,
       CAST(NULL AS VARCHAR) AS is_compliant,
       CAST(NULL AS DECIMAL(15,2)) AS total_sales,
       CAST(NULL AS DECIMAL(15,2)) AS qualified_sales,
       CAST(NULL AS DECIMAL(15,2)) AS total_rebate,
       CAST(NULL AS DECIMAL(10,4)) AS avg_idn_ms_pct,
       CAST(NULL AS DECIMAL(10,4)) AS avg_fclty_ms_pct,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
FROM {{ ref('int_cntrct_cmprhnsv_fct_tr_ms_toc') }} fct
WHERE FALSE
