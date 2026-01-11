# Activity List

## Day 1 – Foundation & AWS/Snowflake Setup

### A) Today's Outcome

Established the "Physical & Cloud Infrastructure" skeleton. Will have a local repo, a Snowflake environment, and an AWS S3 bucket ready to receive data.

### B) Prerequisites / Checks

✅ AWS Account: Free tier access to the AWS Console (Free Tier is fine). sudip2607
✅ Snowflake Account: PJKJJTN-RDC47631.
✅ Local Tools: Python 3.10+, Git, and AWS CLI installed (brew install awscli).

### C) Step-by-Step Tasks

1️⃣ Local Repo Initialization
Open bash terminal and run:

mkdir MedTech-CXM
cd MedTech-CXM
git init

### Create the folder structure

mkdir -p architecture/diagrams data_dictionary ingestion/olist ingestion/synthetic dbt/cxm_medtech powerbi ci/github_actions scripts/setup

### Create placeholder READMEs

touch README.md architecture/README.md data_dictionary/business_definitions.md

2️⃣ AWS S3 Setup (The Landing Zone)

Log into AWS Console.
Go to S3 -> Create Bucket.
Name: cxm-medtech-landing-ssen27.
Region: us-east-1.
Create three folders inside the bucket: raw/olist/, raw/synthetic/, and archive/.

3️⃣ Snowflake Infrastructure (The Medallion Backbone)

Run this in a Snowflake Worksheet (Role: ACCOUNTADMIN or SYSADMIN):

-- 1. Warehouse
CREATE OR REPLACE WAREHOUSE WH_CXM
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- 2. Database
CREATE OR REPLACE DATABASE CXM_MEDTECH;

-- 3. Medallion Schemas
USE DATABASE CXM_MEDTECH;
CREATE OR REPLACE SCHEMA RAW;        -- Landing for S3 data
CREATE OR REPLACE SCHEMA STG;        -- dbt: Cleaning/Renaming
CREATE OR REPLACE SCHEMA INT;        -- dbt: Joins/Logic
CREATE OR REPLACE SCHEMA MARTS;      -- dbt: Analytics Ready
CREATE OR REPLACE SCHEMA SNAPSHOTS;  -- dbt: SCD Type 2
CREATE OR REPLACE SCHEMA SEEDS;      -- dbt: Static Mappings

SELECT CURRENT_REGION() AS snowflake_region;

4️⃣ Define the "MedTech-ified" MLP (Minimum Lovable Product)

Edit data_dictionary/business_definitions.md to define what we are building:

The "Account": Olist Sellers will be treated as Medical Device Distributors/Hospitals.
The "End User": Olist Customers will be treated as HCPs (Healthcare Professionals).
The "Product": Olist Products will be Surgical Kits/Medical Devices.
The "Event": Olist Orders will be Surgical Case Shipments.

5️⃣ Documentation: Architecture Skeleton

Edit architecture/README.md and add this text:

Architecture Flow:
Ingestion: Python Script -> AWS S3 (Landing)
Load: S3 -> Snowflake RAW (via External Stage/COPY INTO)
Transform: dbt (STG -> INT -> MARTS)
Visualize: Power BI (Import Mode)

### D) Exact Commands to Run After creating files and folders

git add .
git commit -m "chore: initial project structure with AWS S3 landing and Snowflake medallion schemas"
git remote add origin <https://github.com/sudip2607/MedTech-CXM.git>
git branch -M main
git push -u origin main

### E) Validation Checks

 AWS: Can see the raw/olist/ folder in your S3 bucket
 Snowflake: Can see the CXM_MEDTECH database and all 6 schemas
 GitHub: Folder structure visible online

### F) IAM permissions + AWS CLI config (so Python can upload to S3)

#### A1) Create IAM policy (least privilege)

AWS Console → IAM → Policies → Create policy → JSON tab

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::cxm-medtech-landing-ssen27"
    },
    {
      "Sid": "RWObjectsInLanding",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::cxm-medtech-landing-ssen27/*"
    }
  ]
}

#### A2) Create IAM user

IAM → Users → Create user:

User name: cxm-medtech-ingestion
Select: “Provide user access to the AWS Management Console” → No (programmatic only)
Permissions:

Attach policy: CXMMedTechLandingS3Access
Create access key:

Security credentials → Create access key → Command Line Interface (CLI)
Copy:

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

#### A3) Configure AWS CLI on macOS

In terminal:
aws configure

Enter:
AWS Access Key ID: <...>
AWS Secret Access Key: <...>
Default region name: us-east-2 (or us-east-1 if you create the new bucket)
Default output format: json

Validate:
aws sts get-caller-identity
aws s3 ls
aws s3 ls s3://cxm-medtech-landing-ssen27/

Good looks like: commands succeed and list your bucket/prefixes.

### G) Common Failure Modes

S3 Region Mismatch: If S3 is in us-east-1 and Snowflake is in eu-central-1, you will pay small egress fees. Try to keep them in the same region.
Permissions: Ensure your local AWS CLI is configured (aws configure) with a user that has S3FullAccess.

### H) Definition of Done (DoD)

Local repo initialized and pushed to GitHub.
AWS S3 Bucket created with raw/ folders.
Snowflake DB, Warehouse, and Schemas created.
Business definitions (MedTech mapping) documented.

## Day 2 – The Ingestion Engine (Local to S3 to Snowflake)

### A) Today’s Outcome

We will build a "Production-Ready" ingestion pipeline for the first 3 Olist tables. Data will flow from local machine → S3 Landing → Snowflake RAW tables with enterprise metadata (batch IDs and timestamps).

### B) Prerequisites / Checks for Day2

✅ AWS CLI configured and validated (Done).
✅ Snowflake RAW schema exists (Done).
✅ Olist Dataset: Download the Olist Dataset from Kaggle ([https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce]) and place the CSVs in a local folder (e.g., ~/Downloads/olist_data/).

### C) Step-by-Step Tasks for Day2

1️⃣ Create the Python Ingestion Script

We want a script that doesn't just "upload," but adds Batch Metadata.

Create ingestion/olist/ingest_to_s3.py:

import boto3
import os
import datetime

// Configuration
BUCKET_NAME = 'cxm-medtech-landing-ssen27'
LOCAL_DATA_PATH = './data/olist/' # Update this to where your CSVs are
TABLES = [
    'olist_orders_dataset.csv',
    'olist_customers_dataset.csv',
    'olist_order_items_dataset.csv'
]

s3 = boto3.client('s3')

def upload_to_s3():
    batch_id = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')

    for table_csv in TABLES:
        # Define S3 Path: raw/olist/table_name/batch_id/file.csv
        table_name = table_csv.replace('.csv', '')
        s3_path = f"raw/olist/{table_name}/{batch_id}/{table_csv}"
        
        print(f"Uploading {table_csv} to s3://{BUCKET_NAME}/{s3_path}...")
        s3.upload_file(os.path.join(LOCAL_DATA_PATH, table_csv), BUCKET_NAME, s3_path)

if __name__ == "__main__":
    upload_to_s3()

#### How to run the Python script

To run the script, you need the boto3 library installed in your Python environment.

In your terminal:

1. Install the AWS SDK for Python.
pip install boto3

2. Ensure you have the Olist data in the right place. Create a 'data/olist' folder in your project root and put the CSVs there
mkdir -p data/olist
(Move your downloaded olist_orders_dataset.csv etc. into that folder)

3. Run the script
python ingestion/olist/ingest_to_s3.py

2️⃣ Snowflake: Create the External Stage

Snowflake needs a "window" to look into S3. We will use a Simple Stage for now (using your Access Keys) to keep it moving.

Run in Snowflake:

USE ROLE ACCOUNTADMIN; -- Or a role with CREATE STAGE info
USE DATABASE CXM_MEDTECH;
USE SCHEMA RAW;

-- Create a File Format (Olist CSVs are standard comma-separated with headers)
CREATE OR REPLACE FILE FORMAT csv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  NULL_IF = ('', 'null')
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Create the Stage (Replace with your IAM User keys from yesterday)

CREATE OR REPLACE STAGE olist_s3_stage
  URL = 's3://cxm-medtech-landing-ssen27/raw/olist/'
  CREDENTIALS = (AWS_KEY_ID = 'YOUR_KEY' AWS_SECRET_KEY = 'YOUR_SECRET')
  FILE_FORMAT = csv_format;

-- Test the stage
LIST @olist_s3_stage;

3️⃣ Snowflake: Create RAW Tables with Metadata

We don't just load data; we track when and where it came from.

Run in Snowflake:
-- Example for Orders
CREATE OR REPLACE TABLE RAW.OLIST_ORDERS (
    -- Data Columns (We will keep them VARCHAR for now to ensure load success)
    ORDER_ID VARCHAR,
    CUSTOMER_ID VARCHAR,
    ORDER_STATUS VARCHAR,
    ORDER_PURCHASE_TIMESTAMP VARCHAR,
    ORDER_APPROVED_AT VARCHAR,
    ORDER_DELIVERED_CARRIER_DATE VARCHAR,
    ORDER_DELIVERED_CUSTOMER_DATE VARCHAR,
    ORDER_ESTIMATED_DELIVERY_DATE VARCHAR,
    -- Metadata Columns (The "Enterprise" touch)
    _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    _BATCH_ID VARCHAR,
    _SOURCE_FILENAME VARCHAR
);

4️⃣ The "COPY INTO" Command

This moves data from the Stage to the Table.

COPY INTO RAW.OLIST_ORDERS
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7, $8,
    CURRENT_TIMESTAMP(),
    'MANUAL_BATCH_01',
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_orders_dataset/
)
PATTERN = '.*.csv';

### D) Validation Queries Day 2

Run these to ensure "Good" looks like data in tables:

-- 1. Check row count
SELECT COUNT(*), _BATCH_ID, _SOURCE_FILENAME FROM RAW.OLIST_ORDERS GROUP BY 2, 3;

-- 2. Check for nulls in critical IDs
SELECT COUNT(*) FROM RAW.OLIST_ORDERS WHERE ORDER_ID IS NULL;

### E) Common Failure Modes

CSV Header Mismatch: If the Olist CSV has 9 columns but your table has 8, COPY INTO will fail. Always check the CSV header first.
S3 Pathing: Ensure the Python script and the Snowflake Stage URL match exactly.

### F) What I should commit to Git

ingestion/olist/ingest_to_s3.py
scripts/setup/snowflake_raw_setup.sql (Save your Snowflake SQL here)
Commit Message: feat: add python ingestion script and snowflake raw table for orders

### G) Definition of Done (DoD) Day 2

Python script successfully uploads at least 1 CSV to S3.
Snowflake Stage can "see" the file (LIST @stage).
RAW.OLIST_ORDERS has data in it.

#### Note to remember

I just did a git commit. And it included all the venv files that I don't want to push to github. I had to install boto3 and it created those folders and libraries in my project folder.

Step 1: Create a .gitignore file in your project root.
Step 2: Remove venv from Git tracking
git rm -r --cached venv
git add .
git commit -m "chore: add .gitignore and remove venv from tracking"
Step 3: Verify
git status

## Day 3 – Completing the RAW Layer & dbt Initialization

### A) Today’s Outcome Day 3

Ingest the remaining core Olist tables into Snowflake RAW.
Initialize the dbt project (cxm_medtech).
Configure the dbt_project.yml and profiles.yml to connect to your Snowflake account.

### B) Prerequisites / Checks Day 3

✅ RAW.OLIST_ORDERS has 99,441 rows.
✅ Python script ingest_to_s3.py is working.
✅ dbt-core installed (dbt --version).

### C) Step-by-Step Tasks Day 3

1️⃣ Ingest the remaining tables

Update your ingest_to_s3.py TABLES list to include the rest of the core files:

TABLES = [
    'olist_orders_dataset.csv',
    'olist_customers_dataset.csv',
    'olist_order_items_dataset.csv',
    'olist_order_reviews_dataset.csv',
    'olist_products_dataset.csv',
    'olist_sellers_dataset.csv',
    'olist_order_payments_dataset.csv',
    'product_category_name_translation.csv',
    'olist_geolocation_dataset.csv'
]

Run the script. Then, in Snowflake, create the tables and run COPY INTO for each.

USE WAREHOUSE WH_CXM;
USE DATABASE CXM_MEDTECH;
USE SCHEMA RAW;

-- Confirm file format exists (create if not)
CREATE FILE FORMAT IF NOT EXISTS csv_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  NULL_IF = ('', 'null')
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Confirm stage exists (adjust if your stage name differs)
-- If you already created it, this is safe to re-run.
CREATE STAGE IF NOT EXISTS olist_s3_stage
  URL = 's3://cxm-medtech-landing-ssen27/raw/olist/'
  FILE_FORMAT = csv_format;

-- Confirm Snowflake can see files (these should return rows)
LIST @olist_s3_stage;
LIST @olist_s3_stage/olist_orders_dataset;

USE WAREHOUSE WH_CXM;
USE DATABASE CXM_MEDTECH;
USE SCHEMA RAW;

-- ORDERS (you already have this; keep as-is or replace with this definition)
CREATE OR REPLACE TABLE RAW.OLIST_ORDERS (
  ORDER_ID VARCHAR,
  CUSTOMER_ID VARCHAR,
  ORDER_STATUS VARCHAR,
  ORDER_PURCHASE_TIMESTAMP VARCHAR,
  ORDER_APPROVED_AT VARCHAR,
  ORDER_DELIVERED_CARRIER_DATE VARCHAR,
  ORDER_DELIVERED_CUSTOMER_DATE VARCHAR,
  ORDER_ESTIMATED_DELIVERY_DATE VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_CUSTOMERS (
  CUSTOMER_ID VARCHAR,
  CUSTOMER_UNIQUE_ID VARCHAR,
  CUSTOMER_ZIP_CODE_PREFIX VARCHAR,
  CUSTOMER_CITY VARCHAR,
  CUSTOMER_STATE VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_ORDER_ITEMS (
  ORDER_ID VARCHAR,
  ORDER_ITEM_ID VARCHAR,
  PRODUCT_ID VARCHAR,
  SELLER_ID VARCHAR,
  SHIPPING_LIMIT_DATE VARCHAR,
  PRICE VARCHAR,
  FREIGHT_VALUE VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_ORDER_REVIEWS (
  REVIEW_ID VARCHAR,
  ORDER_ID VARCHAR,
  REVIEW_SCORE VARCHAR,
  REVIEW_COMMENT_TITLE VARCHAR,
  REVIEW_COMMENT_MESSAGE VARCHAR,
  REVIEW_CREATION_DATE VARCHAR,
  REVIEW_ANSWER_TIMESTAMP VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_PRODUCTS (
  PRODUCT_ID VARCHAR,
  PRODUCT_CATEGORY_NAME VARCHAR,
  PRODUCT_NAME_LENGHT VARCHAR,
  PRODUCT_DESCRIPTION_LENGHT VARCHAR,
  PRODUCT_PHOTOS_QTY VARCHAR,
  PRODUCT_WEIGHT_G VARCHAR,
  PRODUCT_LENGTH_CM VARCHAR,
  PRODUCT_HEIGHT_CM VARCHAR,
  PRODUCT_WIDTH_CM VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_SELLERS (
  SELLER_ID VARCHAR,
  SELLER_ZIP_CODE_PREFIX VARCHAR,
  SELLER_CITY VARCHAR,
  SELLER_STATE VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_ORDER_PAYMENTS (
  ORDER_ID VARCHAR,
  PAYMENT_SEQUENTIAL VARCHAR,
  PAYMENT_TYPE VARCHAR,
  PAYMENT_INSTALLMENTS VARCHAR,
  PAYMENT_VALUE VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.PRODUCT_CATEGORY_NAME_TRANSLATION (
  PRODUCT_CATEGORY_NAME VARCHAR,
  PRODUCT_CATEGORY_NAME_ENGLISH VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

CREATE OR REPLACE TABLE RAW.OLIST_GEOLOCATION (
  GEOLOCATION_ZIP_CODE_PREFIX VARCHAR,
  GEOLOCATION_LAT VARCHAR,
  GEOLOCATION_LNG VARCHAR,
  GEOLOCATION_CITY VARCHAR,
  GEOLOCATION_STATE VARCHAR,
  _LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  _BATCH_ID VARCHAR,
  _SOURCE_FILENAME VARCHAR
);

COPY INTO RAW.OLIST_ORDERS
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7, $8,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_orders_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_CUSTOMERS
FROM (
  SELECT
    $1, $2, $3, $4, $5,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_customers_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_ORDER_ITEMS
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_order_items_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_ORDER_REVIEWS
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_order_reviews_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_PRODUCTS
FROM (
  SELECT
    $1, $2, $3, $4, $5, $6, $7, $8, $9,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_products_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_SELLERS
FROM (
  SELECT
    $1, $2, $3, $4,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_sellers_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_ORDER_PAYMENTS
FROM (
  SELECT
    $1, $2, $3, $4, $5,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_order_payments_dataset
)
PATTERN = '.*\.csv';

COPY INTO RAW.PRODUCT_CATEGORY_NAME_TRANSLATION
FROM (
  SELECT
    $1, $2,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/product_category_name_translation
)
PATTERN = '.*\.csv';

COPY INTO RAW.OLIST_GEOLOCATION
FROM (
  SELECT
    $1, $2, $3, $4, $5,
    CURRENT_TIMESTAMP(),
    SPLIT_PART(METADATA$FILENAME, '/', 2),
    METADATA$FILENAME
  FROM @olist_s3_stage/olist_geolocation_dataset
)
PATTERN = '.*\.csv';

Pro-tip: Use the same metadata pattern (_LOAD_TIMESTAMP, _BATCH_ID, _SOURCE_FILENAME) for every table. This is the "Audit Trail."

SELECT 'OLIST_ORDERS' AS tbl, COUNT(*) AS cnt FROM RAW.OLIST_ORDERS
UNION ALL SELECT 'OLIST_CUSTOMERS', COUNT(*) FROM RAW.OLIST_CUSTOMERS
UNION ALL SELECT 'OLIST_ORDER_ITEMS', COUNT(*) FROM RAW.OLIST_ORDER_ITEMS
UNION ALL SELECT 'OLIST_ORDER_REVIEWS', COUNT(*) FROM RAW.OLIST_ORDER_REVIEWS
UNION ALL SELECT 'OLIST_PRODUCTS', COUNT(*) FROM RAW.OLIST_PRODUCTS
UNION ALL SELECT 'OLIST_SELLERS', COUNT(*) FROM RAW.OLIST_SELLERS
UNION ALL SELECT 'OLIST_ORDER_PAYMENTS', COUNT(*) FROM RAW.OLIST_ORDER_PAYMENTS
UNION ALL SELECT 'PRODUCT_CATEGORY_NAME_TRANSLATION', COUNT(*) FROM RAW.PRODUCT_CATEGORY_NAME_TRANSLATION
UNION ALL SELECT 'OLIST_GEOLOCATION', COUNT(*) FROM RAW.OLIST_GEOLOCATION;

SELECT
  _BATCH_ID,
  COUNT(*) AS rows_loaded,
  MIN(_LOAD_TIMESTAMP) AS first_load_ts,
  MAX(_LOAD_TIMESTAMP) AS last_load_ts
FROM RAW.OLIST_ORDER_ITEMS
GROUP BY 1
ORDER BY 1 DESC;

2️⃣ Initialize dbt

In your bash terminal, navigate to the dbt/ folder and initialize the project:

cd dbt
dbt init cxm_medtech
When prompted for the database, choose snowflake.

It will ask for account, user, password, role, warehouse. Use the details from Day 1.

3️⃣ Configure dbt_project.yml

Open dbt/cxm_medtech/dbt_project.yml. Update the models section to reflect our medallion architecture:

models:
  cxm_medtech:
    staging:
      +schema: stg
      +materialized: view
    intermediate:
      +schema: int
      +materialized: ephemeral
    marts:
      +schema: marts
      +materialized: table

4️⃣ Create the sources.yml

This tells dbt where your RAW data lives. Create dbt/cxm_medtech/models/staging/sources.yml:

version: 2

sources:
  - name: olist
    database: CXM_MEDTECH
    schema: RAW
    tables:
      - name: olist_orders
      - name: olist_customers
      - name: olist_order_items
      - name: olist_order_reviews
      - name: olist_products
      - name: olist_sellers
      - name: olist_order_payments
      - name: product_category_name_translation
      - name: olist_geolocation

### D) Exact Commands to Run

Test your dbt connection

cd dbt/cxm_medtech
dbt debug

### E) Validation Queries

In Snowflake, verify all 6 tables are loaded:

Copy
SELECT 'orders' as tbl, count(*) FROM RAW.OLIST_ORDERS
UNION ALL
SELECT 'customers', count(*) FROM RAW.OLIST_CUSTOMERS
-- ... repeat for all 6

### F) Common Failure Modes

dbt Profiles: If dbt debug fails, it’s usually a profiles.yml issue. dbt usually stores this in ~/.dbt/profiles.yml. Ensure the account field does not include https://. It should just be PJKJJTN-RDC47631.
Schema Names: Ensure dbt is pointing to CXM_MEDTECH.

### G) What I should commit to Git

dbt/cxm_medtech/ (The whole folder created by dbt init)
dbt/cxm_medtech/models/staging/sources.yml
Commit Message: feat: initialize dbt project and define raw sources

Note:
git add . only adds files in the current directory (cxm_medtech)
Your changes are in parent directories (../../DayWise_Activity.md, etc.)
You need to run git add from the project root or use git add -A to add all changes

### H) Definition of Done (DoD) Day 3

All 6 Olist tables loaded into Snowflake RAW.
dbt debug passes (Green checkmarks for connection).
sources.yml created and pointing to the correct Snowflake tables.

### I) What you should reply back with

Confirmation that all 6 tables are in RAW.
The output of dbt debug (just the last few lines showing success).
Did you have to modify profiles.yml manually?