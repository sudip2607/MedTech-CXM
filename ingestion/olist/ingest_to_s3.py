import boto3
import os
import datetime

# Configuration
BUCKET_NAME = 'cxm-medtech-landing-ssen27'
# LOCAL_DATA_PATH = '/Users/sudipsen/Documents/Visual Studio_All Work/MedTech-CXM/src_data/' # Update this to where your CSVs are
LOCAL_DATA_PATH = './src_data/' # Update this to where your CSVs are

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