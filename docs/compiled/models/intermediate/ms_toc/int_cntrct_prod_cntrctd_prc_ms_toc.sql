

/*
    Contracted Pricing for Qualified Products
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Gets contracted price for each qualified product
    - Uses most recent price effective within compliance period
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - prod_id: Product ID
    - cntrctd_prc: Contracted unit price
    - eff_st_dt: Effective start date
    - eff_end_dt: Effective end date
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.dim_cntrc_prod_line_item
    - int_cntrct_qual_prod_ms_toc
    
    Target: md_wrk.sv_cntrct_prod_cntrctd_prc_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS prod_id,
       CAST(NULL AS DECIMAL(18,4)) AS cntrctd_prc,
       CAST(NULL AS DATE) AS eff_st_dt,
       CAST(NULL AS DATE) AS eff_end_dt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE