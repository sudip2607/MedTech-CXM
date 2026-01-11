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
