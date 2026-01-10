# MedTech-CXM

It's a repo for Customer Experience Management (CXM) within the MedTech industry. CXM in MedTech focuses on improving interactions across the entire customer journey, from sales and installation to clinical support and upgrades, to enhance user satisfaction and drive growth.

## Architecture Flow

Ingestion: Python Script -> AWS S3 (Landing)
Load: S3 -> Snowflake RAW (via External Stage/COPY INTO)
Transform: dbt (STG -> INT -> MARTS)
Visualize: Power BI (Import Mode)
