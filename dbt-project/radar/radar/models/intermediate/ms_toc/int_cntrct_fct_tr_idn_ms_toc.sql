{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    IDN-Level Fact Table for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Aggregates sales data at IDN (Integrated Delivery Network) level
    - Separates qualified vs total sales for market share calculation
    - Includes customer and contract context
*/

SELECT sls.cntrc_id,
       sls.prc_prg_id,
       sls.cmpnt_id,
       sls.idn_id,
       idn.idn_nm,
       SUM(CASE WHEN sls.prod_id IS NOT NULL THEN sls.sls_amt ELSE 0 END) AS qual_sls_amt,
       SUM(sls.sls_amt) AS tot_sls_amt,
       compli.per_strt_dt AS compli_per_strt_dt,
       compli.per_end_dt AS compli_per_end_dt
FROM {{ ref('int_cntrct_sls_ms_toc') }} sls
INNER JOIN {{ source('md_dwh', 'dim_idn') }} idn
    ON sls.idn_id = idn.idn_id
INNER JOIN {{ ref('int_cntrct_compli_period_toc') }} compli
    ON sls.cntrc_id = compli.cntrc_id
GROUP BY sls.cntrc_id, sls.prc_prg_id, sls.cmpnt_id, sls.idn_id, idn.idn_nm, compli.per_strt_dt, compli.per_end_dt
