{{
    config(
        materialized='view',
        tags=['ms', 'toc', 'market_share', 'documentation']
    )
}}

/*
    IDN Tier Achievement & Rebate Calculation for MS TOC
    
    **STATUS:** Documentation Model (No actual data)
    
    Business Logic:
    - Ranks IDNs by market share achievement into tiers
    - Assigns rebate rates based on tier achieved
    - Calculates total rebate amount based on tier and sales volume
    
    Tier Structure Example:
    - Tier 1 (90-100%): 2.5% rebate
    - Tier 2 (80-89%): 2.0% rebate
    - Tier 3 (75-79%): 1.5% rebate
*/

SELECT CAST(NULL AS VARCHAR) AS cntrc_id,
       CAST(NULL AS VARCHAR) AS prc_prg_id,
       CAST(NULL AS VARCHAR) AS cmpnt_id,
       CAST(NULL AS VARCHAR) AS idn_id,
       CAST(NULL AS DECIMAL(10,4)) AS ms_pct,
       CAST(NULL AS INTEGER) AS tier,
       CAST(NULL AS DECIMAL(5,2)) AS rebate_pct,
       CAST(NULL AS DECIMAL(15,2)) AS total_rebate
FROM {{ ref('int_cntrct_cmplnc_vldtn_idn_ms_toc') }} cmpl
WHERE FALSE
