select
    seller_id as account_id,
    seller_zip_code_prefix as zip_code,
    seller_city as city,
    seller_state as state,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_sellers') }}