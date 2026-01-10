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
