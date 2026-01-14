

/*
    Market Share Time of Compliance Mart
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Final reporting table for MS TOC compliance
    - Aggregated metrics at contract/program/component level
    - Latest compliance period snapshot
    - Ready for BI/Dashboard consumption
    
    Expected Output:
    - mart_cntrct_ms_toc table in ldw schema
    
    Source Models:
    - int_cntrct_cmprhnsv_fct_tr_ms_toc
    - int_cntrct_rcnt_period
    - int_cntrct_tier_components_ms
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS cntrc_nm,
       CAST(NULL AS VARCHAR) AS cntrc_sts,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS INTEGER) AS tier_num,
       CAST(NULL AS DECIMAL(10,4)) AS tier_ms_min_pct,
       CAST(NULL AS DECIMAL(10,4)) AS tier_ms_max_pct,
       CAST(NULL AS DATE) AS compli_per_strt_dt,
       CAST(NULL AS DATE) AS compli_per_end_dt,
       CAST(NULL AS INTEGER) AS period_days,
       CAST(NULL AS INTEGER) AS total_customers,
       CAST(NULL AS INTEGER) AS eligible_customers,
       CAST(NULL AS DECIMAL(10,4)) AS eligible_customer_pct,
       CAST(NULL AS INTEGER) AS total_products,
       CAST(NULL AS INTEGER) AS qualified_products,
       CAST(NULL AS DECIMAL(10,4)) AS qualified_product_pct,
       CAST(NULL AS INTEGER) AS total_idns,
       CAST(NULL AS DECIMAL(18,2)) AS total_sales,
       CAST(NULL AS DECIMAL(18,2)) AS qualified_sales,
       CAST(NULL AS DECIMAL(10,4)) AS overall_ms_pct,
       CAST(NULL AS DECIMAL(18,4)) AS total_quantity,
       CAST(NULL AS DECIMAL(18,4)) AS qualified_quantity,
       CAST(NULL AS DECIMAL(18,2)) AS total_idn_rebate,
       CAST(NULL AS DECIMAL(18,2)) AS total_fclty_rebate,
       CAST(NULL AS DECIMAL(18,2)) AS total_rebate,
       CAST(NULL AS DECIMAL(10,4)) AS avg_idn_ms_pct,
       CAST(NULL AS DECIMAL(10,4)) AS avg_fclty_ms_pct,
       CAST(NULL AS DECIMAL(10,4)) AS avg_idn_tier,
       CAST(NULL AS DECIMAL(10,4)) AS avg_fclty_tier,
       CAST(NULL AS INTEGER) AS is_compliant,
       CAST(NULL AS INTEGER) AS transaction_count,
       CAST(NULL AS TIMESTAMP) AS last_updated_ts,
       CAST(NULL AS TIMESTAMP) AS mart_created_ts
WHERE FALSE