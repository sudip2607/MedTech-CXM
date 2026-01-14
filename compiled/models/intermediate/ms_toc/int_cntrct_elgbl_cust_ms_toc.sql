

/*
    Eligible Customers for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Identifies eligible customers for market share compliance
    - Joins customer eligibility with compliance periods
    - Filters to latest compliance period (TOC)
    
    Expected Columns:
    - cntrc_id: Contract ID
    - prc_prg_id: Pricing program ID
    - cmpnt_id: Component ID
    - cmt_cust_id: Compliant customer ID
    - elig_st_dt: Eligibility start date
    - elig_end_dt: Eligibility end date
    - compli_per_strt_dt: Compliance period start date
    - compli_per_end_dt: Compliance period end date
    
    Source Tables:
    - md_dwh.dim_prc_cmpnt_cust_elig
    - dim_prc_prg_cmpli_per_rslts
    
    Target: md_wrk.sv_cntrct_elgbl_cust_ms_toc
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS cmt_cust_id,
       CAST(NULL AS DATE) AS elig_st_dt,
       CAST(NULL AS DATE) AS elig_end_dt,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt
WHERE FALSE