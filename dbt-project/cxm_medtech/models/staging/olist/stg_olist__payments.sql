select
    order_id as shipment_id,
    payment_sequential,
    payment_type,
    cast(payment_installments as integer) as payment_installments,
    cast(payment_value as decimal(10,2)) as total_payment_amount,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_order_payments') }}