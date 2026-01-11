select
    product_category_name as category_name,
    product_category_name_english as category_name_en,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'product_category_name_translation') }}