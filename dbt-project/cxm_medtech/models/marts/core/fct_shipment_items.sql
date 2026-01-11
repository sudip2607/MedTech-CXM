select
    shipment_item_key,
    shipment_id,
    account_id,
    device_id,
    unit_price,
    freight_amount,
    total_line_value
from {{ ref('int_shipment_items_enriched') }}