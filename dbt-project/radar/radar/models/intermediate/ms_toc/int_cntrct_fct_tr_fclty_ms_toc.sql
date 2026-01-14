{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Facility-Level Fact Table for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Aggregates sales data at facility (hospital/provider) level
    - Separates qualified vs total sales for market share calculation
    - Includes facility and contract context
*/

SELECT sls.cntrc_id,
       sls.prc_prg_id,
       sls.cmpnt_id,
       sls.fclty_id,
       fclty.fclty_nm,
       sls.idn_id,
       SUM(CASE WHEN sls.prod_id IS NOT NULL THEN sls.sls_amt ELSE 0 END) AS qual_sls_amt,
       SUM(sls.sls_amt) AS tot_sls_amt,
       compli.per_strt_dt AS compli_per_strt_dt,
       compli.per_end_dt AS compli_per_end_dt
FROM {{ ref('int_cntrct_sls_ms_toc') }} sls
INNER JOIN {{ source('md_dwh', 'dim_fclty') }} fclty
    ON sls.fclty_id = fclty.fclty_id
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} compli
    ON sls.cntrc_id = compli.cntrc_id
GROUP BY sls.cntrc_id, sls.prc_prg_id, sls.cmpnt_id, sls.fclty_id, fclty.fclty_nm, sls.idn_id, compli.per_strt_dt, compli.per_end_dt
