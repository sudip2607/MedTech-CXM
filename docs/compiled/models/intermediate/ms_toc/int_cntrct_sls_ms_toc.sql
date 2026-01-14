

/*
    Sales Data for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Transaction-level sales for qualified products
    - Filtered to compliance period date range
    - Foundation for market share calculations
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - cust_id: Customer ID
    - prod_id: Product ID
    - trnsc_dt: Transaction date
    - qty_sold: Quantity sold
    - net_sls_amt: Net sales amount
    - gross_sls_amt: Gross sales amount
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.sv_fact_transaction
    - int_cntrct_qual_prod_ms_toc
    
    Target: md_wrk.sv_cntrct_sls_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cust_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DATE) AS trnsc_dt,
       CAST(NULL AS DECIMAL(18,4)) AS qty_sold,
       CAST(NULL AS DECIMAL(18,2)) AS net_sls_amt,
       CAST(NULL AS DECIMAL(18,2)) AS gross_sls_amt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE