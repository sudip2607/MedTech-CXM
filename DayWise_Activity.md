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

you can revert commits, but feature branches are the enterprise standard.

Reverting Commits (Without Feature Branch)
Option 1: Undo last commit (before pushing)
Undo commit but keep changes
git reset --soft HEAD~1

Undo commit and discard changes
git reset --hard HEAD~1

Option 2: Revert after pushing
Creates a new commit that undoes changes
git revert <commit-hash>
git push

Option 3: Force push (dangerous - avoid in teams)
git reset --hard HEAD~1
git push --force

Enterprise Real-World Standard: YES, Always Use Feature Branches

Standard workflow (Git Flow/GitHub Flow):


1. Create feature branch
git checkout -b feature/add-customer-model

2. Make changes and commit
git add .
git commit -m "feat: add customer dimension model"

3. Push feature branch
git push -u origin feature/add-customer-model

4. Create Pull Request (PR) on GitHub
Team reviews → approve → merge to main

5. Switch back to main and pull latest
git checkout main
git pull

Why enterprises use feature branches:
✅ main stays stable and deployable
✅ Code review via Pull Requests
✅ Easy to abandon bad features
✅ Multiple people can work simultaneously
✅ CI/CD runs tests before merging

Your workflow should be:

main = production-ready code only
feature/* = work-in-progress branches
Merge via Pull Requests with reviews

### H) Definition of Done (DoD) Day 3

All 6 Olist tables loaded into Snowflake RAW.
dbt debug passes (Green checkmarks for connection).
sources.yml created and pointing to the correct Snowflake tables.

## Day 4 – The Staging Layer (MedTech-ifying the Data)

### A) Today’s Outcome Day 4

We will create your first Staging Models. This is where we:

Rename Olist columns to MedTech terms (e.g., customer_id → hcp_id).
Cast data types (e.g., Strings to Timestamps/Decimals).
Clean basic data (handling nulls).

### B) Prerequisites / Checks Day 4

✅ dbt debug is passing.
✅ macros/generate_schema_name.sql is created.
✅ models/staging/sources.yml is updated with all 9 tables.

### C) Step-by-Step Tasks Day 4

1️⃣ Create the Staging Folder Structure

Inside dbt_project/cxm_medtech/models/staging/, create a subfolder called olist/. We keep sources separated in case we add AWS synthetic data later.

2️⃣ Create stg_olist__orders.sql

Create dbt_project/cxm_medtech/models/staging/olist/stg_olist__orders.sql:

with source as (
    select * from {{ source('olist', 'olist_orders') }}
),

renamed as (
    select
        -- Primary Key
        order_id as shipment_id,
        
        -- Foreign Keys
        customer_id as hcp_id,
        
        -- Statuses
        order_status as shipment_status,
        
        -- Timestamps (Casting from String to Timestamp)
        cast(order_purchase_timestamp as timestamp_ntz) as ordered_at,
        cast(order_approved_at as timestamp_ntz) as approved_at,
        cast(order_delivered_carrier_date as timestamp_ntz) as handed_over_to_logistics_at,
        cast(order_delivered_customer_date as timestamp_ntz) as delivered_at,
        cast(order_estimated_delivery_date as timestamp_ntz) as estimated_delivery_at,
        
        -- Metadata from RAW
        _load_timestamp,
        _batch_id

    from source
)

select * from renamed

3️⃣ Create stg_olist__hcp.sql (Mapping Customers to HCPs)

Create dbt_project/cxm_medtech/models/staging/olist/stg_olist__hcp.sql:

with source as (
    select * from {{ source('olist', 'olist_customers') }}
),

renamed as (
    select
        customer_id as hcp_id,
        customer_unique_id as hcp_unique_id,
        customer_zip_code_prefix as zip_code,
        customer_city as city,
        customer_state as state,
        _load_timestamp,
        _batch_id
    from source
)

select * from renamed

4️⃣ Create stg_olist__reviews.sql (Mapping Reviews to NPS)

Create dbt_project/cxm_medtech/models/staging/olist/stg_olist__reviews.sql:

with source as (
    select * from {{ source('olist', 'olist_order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id as shipment_id,
        cast(review_score as integer) as survey_score,
        review_comment_title as survey_title,
        review_comment_message as survey_comments,
        cast(review_creation_date as timestamp_ntz) as survey_sent_at,
        cast(review_answer_timestamp as timestamp_ntz) as survey_responded_at,
        _load_timestamp,
        _batch_id
    from source
)

select * from renamed

### D) Exact Commands to Run Day 4

cd dbt_project/cxm_medtech
dbt run --select staging.olist

### E) Validation Queries Day 4

In Snowflake, check the STG schema:

-- Check if the view was created and columns are renamed/typed
SELECT * FROM CXM_MEDTECH.STG.STG_OLIST__ORDERS LIMIT 10;

-- Verify the data type of 'ordered_at' is TIMESTAMP
DESCRIBE VIEW CXM_MEDTECH.STG.STG_OLIST__ORDERS;

### F) Common Failure Modes Day 4

Casting Errors: If a date string in RAW is malformed, cast(... as timestamp_ntz) will fail. If this happens, we may need to use try_to_timestamp().
Macro Missing: If your schema name in Snowflake is STG_STG, you forgot the generate_schema_name.sql macro.

### G) What I did commit to Git Day 4

macros/generate_schema_name.sql
models/staging/olist/stg_olist__orders.sql
models/staging/olist/stg_olist__hcp.sql
models/staging/olist/stg_olist__reviews.sql
Commit Message: feat: add staging models for orders, hcp, and reviews with medtech renaming

### H) Definition of Done (DoD) Day 4

dbt run completes successfully for the 3 staging models.
Snowflake STG schema contains 3 new views.
Column names in STG match our MedTech mapping (Shipment, HCP, Survey).

## Day 5 – Completing the Staging Layer & First Tests

### A) Today’s Outcome Day 5

Create the remaining 6 Staging models (accounts, products, items, payments, categories, geo).
Implement dbt tests to ensure data integrity (Unique, Not Null, Relationships).
Generate first dbt Documentation site.

### B) Prerequisites / Checks Day 5

✅ STG_OLIST__ORDERS, STG_OLIST__HCP, and STG_OLIST__REVIEWS are live in Snowflake.
✅ dbt run is working.

### C) Step-by-Step Tasks Day 5

1️⃣ Create the remaining Staging Models

Create these files in dbt_project/cxm_medtech/models/staging/olist/:

stg_olist__accounts.sql (Mapping Sellers to Accounts/Distributors)

select
    seller_id as account_id,
    seller_zip_code_prefix as zip_code,
    seller_city as city,
    seller_state as state,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_sellers') }}

stg_olist__products.sql (Mapping Products to Medical Devices)

select
    product_id as device_id,
    product_category_name as category_name,
    cast(product_weight_g as float) as weight_g,
    cast(product_length_cm as float) as length_cm,
    cast(product_height_cm as float) as height_cm,
    cast(product_width_cm as float) as width_cm,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_products') }}

stg_olist__shipment_items.sql (Mapping Order Items to Shipment Lines)

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as shipment_item_key,
    order_id as shipment_id,
    order_item_id as line_item_number,
    product_id as device_id,
    seller_id as account_id,
    cast(shipping_limit_date as timestamp_ntz) as shipping_limit_at,
    cast(price as decimal(10,2)) as unit_price,
    cast(freight_value as decimal(10,2)) as freight_amount,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_order_items') }}

(Note: If dbt_utils isn't installed, just use md5(order_id || order_item_id) for now, or I can show you how to add the package.)

stg_olist__payments.sql

select
    order_id as shipment_id,
    payment_sequential,
    payment_type,
    cast(payment_installments as integer) as payment_installments,
    cast(payment_value as decimal(10,2)) as total_payment_amount,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_order_payments') }}

stg_olist__categories.sql

select
    product_category_name as category_name,
    product_category_name_english as category_name_en,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'product_category_name_translation') }}

stg_olist__geo.sql

select
    geolocation_zip_code_prefix as zip_code,
    cast(geolocation_lat as float) as latitude,
    cast(geolocation_lng as float) as longitude,
    geolocation_city as city,
    geolocation_state as state,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_geolocation') }}

2️⃣ Add dbt Tests

Create dbt_project/cxm_medtech/models/staging/olist/_stg_olist__models.yml:

version: 2

models:
  - name: stg_olist__orders
    columns:
      - name: shipment_id
        tests:
          - unique
          - not_null
      - name: hcp_id
        tests:
          - not_null
          - relationships:
              to: ref('stg_olist__hcp')
              field: hcp_id

  - name: stg_olist__hcp
    columns:
      - name: hcp_id
        tests:
          - unique
          - not_null

### D) Exact Commands to Run Day 5

cd dbt_project
-- Run all models
dbt run
-- Run all tests
dbt test
-- Generate and serve docs (this will open a browser tab)
dbt docs generate
dbt docs serve

### E) Validation Queries Day 5

In Snowflake, verify the STG schema has 9 views.

SELECT table_name, table_type 
FROM CXM_MEDTECH.INFORMATION_SCHEMA.VIEWS 
WHERE table_schema = 'STG';

### F) Common Failure Modes Day 5

Relationship Test Failure: If an order has a customer_id that doesn't exist in the customers table, the test will fail. This is common in real-world data! If it fails, don't panic—it's doing its job.
Duplicate Keys: If shipment_id isn't unique in the orders table, we'll need to investigate why (usually it's a data quality issue in the source).

### G) What I did commit to Git Day 5

All 6 new .sql files in models/staging/olist/
models/staging/olist/_stg_olist__models.yml
Commit Message: feat: complete staging layer and add schema tests

### H) Definition of Done (DoD) Day 5

All 9 staging models exist as views in Snowflake.
dbt test passes (or you have identified which rows failed).
You have viewed the dbt lineage graph in dbt docs serve.

## Day 6½ – Publish dbt Docs to S3 (Static Site)

This is a short, focused step before we start INT models.

### A) Today’s Outcome Day 6½

dbt docs published to S3
Public (or private) URL you can share
Clear AWS architecture story

### B) S3 Setup for Docs

1️⃣ Create a new S3 bucket (separate from landing)
Bucket name:

cxm-medtech-dbt-docs-ssen27

Settings:

Region: us-east-1
Enable static website hosting
Index document: index.html
Error document: index.html

### C) Generate dbt docs artifacts

From your dbt project root:

This creates:

target/
  index.html
  manifest.json
  catalog.json
  assets/

### D) Upload docs to S3

From project root:

aws s3 sync target/ s3://cxm-medtech-dbt-docs-ssen27/ --delete
✅ --delete keeps the site in sync across regenerations.

### E) Make it accessible

Option 1: Public (simplest for portfolio)
Add this bucket policy (replace bucket name):

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::cxm-medtech-dbt-docs-ssen27/*"
    }
  ]
}

You’ll get a URL like:

http://cxm-medtech-dbt-docs-ssen27.s3-website-us-east-1.amazonaws.com

Option 2 (Later): Private + CloudFront + IAM
We can upgrade later if you want to show security best practices.

### F) Document this in your repo

Create:

architecture/dbt_docs_hosting.md
Include:

Why dbt docs matter
Why S3 static hosting
How it’s regenerated
This is AWS Community Builder gold.

### G) Commit to Git (Optional)

Files

architecture/dbt_docs_hosting.md
(No target/ files — correct)
Commit message

docs: document dbt docs publishing via S3 static hosting

### H) Definition of Done (Day 6½)

 dbt docs load from S3 URL
 Lineage graph visible in browser
 .gitignore unchanged
 Architecture doc committed

## Day 6 (rest of the work) – The Intermediate Layer: Building Business Entities

### A) Today’s Outcome Day 6

We will create your first Intermediate Models. In the Medallion architecture, the INT layer is where we join multiple staging tables to create "Enriched" entities.
Today, we build the int_shipments_enriched model, which will be the backbone of your CX analytics.

### B) Prerequisites / Checks Day 6

✅ dbt --version shows Core 1.11.2.
✅ All 9 staging models are working.
✅ dbt_project.yml has the intermediate schema configured as +schema: int.

### C) Step-by-Step Tasks Day 6

1️⃣ Create the Intermediate Folder

Create the folder: dbt_project/models/intermediate/.

2️⃣ Create int_shipments_enriched.sql

This model joins shipments (orders) with HCPs, Accounts, and Reviews to create a single "wide" table of shipment events.

with shipments as (
    select * from {{ ref('stg_olist__orders') }}
),

hcp as (
    select * from {{ ref('stg_olist__hcp') }}
),

accounts as (
    select * from {{ ref('stg_olist__accounts') }}
),

reviews as (
    select * from {{ ref('stg_olist__reviews') }}
),

final as (
    select
        s.shipment_id,
        s.hcp_id,
        s.shipment_status,
        s.ordered_at,
        s.approved_at,
        s.delivered_at,
        s.estimated_delivery_at,
        
        -- HCP Details
        h.city as hcp_city,
        h.state as hcp_state,
        
        -- Review/NPS Details (Joining on shipment_id)
        r.survey_score,
        r.survey_responded_at,
        
        -- Logic: On-Time Delivery Flag
        case 
            when s.delivered_at <= s.estimated_delivery_at then 1 
            else 0 
        end as is_on_time,
        
        -- Logic: Days to Deliver
        datediff('day', s.ordered_at, s.delivered_at) as days_to_deliver,
        
        -- Logic: NPS Category
        case 
            when r.survey_score >= 4 then 'Promoter'
            when r.survey_score = 3 then 'Passive'
            when r.survey_score is not null then 'Detractor'
            else null
        end as nps_category

    from shipments s
    left join hcp h on s.hcp_id = h.hcp_id
    left join reviews r on s.shipment_id = r.shipment_id
)

select * from final

3️⃣ Create int_shipment_items_enriched.sql

This model joins shipment items with products and categories to get the "MedTech Device" context.

with items as (
    select * from {{ ref('stg_olist__shipment_items') }}
),

products as (
    select * from {{ ref('stg_olist__products') }}
),

categories as (
    select * from {{ ref('stg_olist__categories') }}
),

final as (
    select
        i.shipment_item_key,
        i.shipment_id,
        i.device_id,
        i.account_id,
        i.unit_price,
        i.freight_amount,
        
        -- Product/Device Details
        p.category_name,
        c.category_name_en as device_category_english,
        
        -- Logic: Total Line Value
        (i.unit_price + i.freight_amount) as total_line_value

    from items i
    left join products p on i.device_id = p.device_id
    left join categories c on p.category_name = c.category_name
)

select * from final

### D) Exact Commands to Run Day 6

cd dbt_project
dbt run --select intermediate

### E) Validation Queries Day 6

In Snowflake, check the INT schema:

-- Check the enriched shipments
SELECT 
    shipment_status, 
    nps_category, 
    is_on_time, 
    count(*) 
FROM CXM_MEDTECH.INT.INT_SHIPMENTS_ENRICHED 
GROUP BY 1, 2, 3;

### F) Common Failure Modes Day 6

Fan-out: If a shipment has multiple reviews (rare in Olist but possible), the left join on reviews might duplicate shipment rows. We will check for this in the next step with a unique test.
Nulls: If category_name_en is null, it means some categories in the product table aren't in the translation table.

### G) What I should commit to Git Day 6

models/intermediate/int_shipments_enriched.sql
models/intermediate/int_shipment_items_enriched.sql
Commit Message: feat: add intermediate enriched models for shipments and items

### H) Definition of Done (DoD) Day 6

dbt run succeeds for both intermediate models.
Snowflake INT schema contains the new views.
You can see the is_on_time and nps_category columns populated in Snowflake.