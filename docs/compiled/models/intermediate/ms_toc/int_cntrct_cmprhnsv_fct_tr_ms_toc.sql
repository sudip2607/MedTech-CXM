

/*
    Comprehensive Fact Table for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Combines all contract, customer, product, and compliance data
    - Aggregates sales at contract component level
    - Includes both IDN and facility level compliance metrics
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
WHERE FALSE