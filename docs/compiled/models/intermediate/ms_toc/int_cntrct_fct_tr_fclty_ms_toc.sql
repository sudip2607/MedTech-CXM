

/*
    Transaction Facts at Facility Level
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Keeps sales at facility/customer level
    - Joins with account dimension for facility names
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - fclty_id: Facility ID
    - fclty_nm: Facility name
    - prod_id: Product ID
    - trnsc_dt: Transaction date
    - qty_sold: Quantity sold
    - net_sls_amt: Net sales amount
    - gross_sls_amt: Gross sales amount
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - int_cntrct_sls_ms_toc
    - md_dwh.dim_acct
    
    Target: md_wrk.sv_cntrct_fct_tr_fclty_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS fclty_id,
       CAST(NULL AS VARCHAR) AS fclty_nm,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS trnsc_dt,
       CAST(NULL AS DECIMAL(18,4)) AS qty_sold,
       CAST(NULL AS DECIMAL(18,2)) AS net_sls_amt,
       CAST(NULL AS DECIMAL(18,2)) AS gross_sls_amt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE