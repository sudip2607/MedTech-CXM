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