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