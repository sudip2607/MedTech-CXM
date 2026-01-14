{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    Sales Transactions for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Captures all sales transactions for eligible customers and products
    - Filters to qualified products based on contract
    - Includes transaction details (qty, amount, date)
*/

SELECT sls.sls_trn_id,
       elig.cntrc_id,
       elig.prc_prg_id,
       qual.cmpnt_id,
       sls.cmt_cust_id,
       sls.prod_id,
       cust.idn_id,
       cust.fclty_id,
       sls.sls_amt,
       sls.qty,
       sls.sls_dt
FROM {{ source('md_dwh', 'fct_sls_trn') }} sls
INNER JOIN {{ ref('int_cntrct_elgbl_cust_ms_toc') }} elig
    ON sls.cmt_cust_id = elig.cmt_cust_id
INNER JOIN {{ ref('int_cntrct_qual_prod_ms_toc') }} qual
    ON sls.prod_id = qual.prod_id
    AND elig.cntrc_id = qual.cntrc_id
    AND elig.prc_prg_id = qual.prc_prg_id
INNER JOIN {{ source('md_dwh', 'dim_cmt_cust') }} cust
    ON sls.cmt_cust_id = cust.cmt_cust_id
