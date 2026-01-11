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