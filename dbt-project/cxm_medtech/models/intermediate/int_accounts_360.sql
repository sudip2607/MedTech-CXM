with shipment_items as (
    select * from {{ ref('int_shipment_items_enriched') }}
),

shipments as (
    select * from {{ ref('int_shipments_enriched') }}
),

account_base as (
    select * from {{ ref('stg_olist__accounts') }}
),

account_metrics as (
    select
        i.account_id,
        count(distinct i.shipment_id) as total_shipments,
        count(distinct i.device_id) as unique_devices_ordered,
        sum(i.total_line_value) as total_account_value,
        avg(s.survey_score) as avg_account_nps_score,
        sum(s.is_on_time) / count(s.shipment_id) as on_time_delivery_rate
    from shipment_items i
    left join shipments s on i.shipment_id = s.shipment_id
    group by 1
),

final as (
    select
        a.account_id,
        a.city,
        a.state,
        coalesce(m.total_shipments, 0) as total_shipments,
        coalesce(m.unique_devices_ordered, 0) as unique_devices_ordered,
        coalesce(m.total_account_value, 0) as total_lifetime_value,
        m.avg_account_nps_score,
        m.on_time_delivery_rate,
        
        -- Logic: Account Segment
        case 
            when m.total_account_value > 10000 then 'Tier 1 (Key Account)'
            when m.total_account_value > 2000 then 'Tier 2 (Growth)'
            else 'Tier 3 (Standard)'
        end as account_segment

    from account_base a
    left join account_metrics m on a.account_id = m.account_id
)

select * from final
