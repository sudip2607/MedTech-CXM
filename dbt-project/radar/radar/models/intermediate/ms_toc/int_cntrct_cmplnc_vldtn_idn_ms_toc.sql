{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    IDN Market Share Compliance Validation for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Calculates market share % = (qualified sales / total sales) * 100 for IDN
    - Validates if IDN meets minimum market share threshold
    - Used for determining rebate eligibility
    
    Calculation:
    - Overall MS % = (sum qualified sales / sum total sales) * 100
    - Compliant if >= minimum threshold (e.g., 75%)
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS DECIMAL(10,4)) AS ms_pct,
       CAST(NULL AS VARCHAR) AS is_compliant
FROM {{ ref('int_cntrct_fct_tr_idn_ms_toc') }} fct
WHERE FALSE
