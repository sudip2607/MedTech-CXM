{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Comprehensive Fact Table for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Combines all contract, customer, product, and compliance data
    - Aggregates sales at contract component level
    - Includes both IDN and facility level compliance metrics
    - Includes contracted pricing information
    - Serves as base for final reporting/mart table
    
    Key Calculations:
    - Overall market share % (contract-level)
    - IDN market share % and tier
    - Facility market share % and tier
    - Total rebates (IDN + facility)
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cmpnt_nm,
       CAST(NULL AS VARCHAR) AS cmt_cust_id,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS VARCHAR) AS idn_nm,
       CAST(NULL AS VARCHAR) AS fclty_id,
       CAST(NULL AS VARCHAR) AS fclty_nm,
       CAST(NULL AS DECIMAL(15,2)) AS qual_sls_amt,
       CAST(NULL AS DECIMAL(15,2)) AS tot_sls_amt,
       CAST(NULL AS DECIMAL(10,4)) AS overall_ms_pct,
       CAST(NULL AS DECIMAL(10,4)) AS idn_ms_pct,
       CAST(NULL AS DECIMAL(10,4)) AS fclty_ms_pct,
       CAST(NULL AS INTEGER) AS idn_tier,
       CAST(NULL AS INTEGER) AS fclty_tier,
       CAST(NULL AS DECIMAL(15,2)) AS idn_rebate,
       CAST(NULL AS DECIMAL(15,2)) AS fclty_rebate,
       CAST(NULL AS DECIMAL(15,2)) AS tot_rebate,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
FROM {{ ref('int_cntrct_cmplnc_vldtn_idn_rnkd_ms_toc') }} idn_rnkd
INNER JOIN {{ ref('int_cntrct_cmplnc_vldtn_fclty_rnkd_ms_toc') }} fclty_rnkd
INNER JOIN {{ ref('int_cntrct_prod_cntrctd_prc_ms_toc') }} prc
    ON idn_rnkd.cntrc_id = prc.cntrc_id
    AND idn_rnkd.prc_prg_id = prc.prc_prg_id
    AND idn_rnkd.cmpnt_id = prc.cmpnt_id
WHERE FALSE
