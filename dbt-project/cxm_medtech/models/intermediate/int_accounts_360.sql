with account_base as (
    select * from {{ ref('stg_olist__accounts') }}
),

items as (
    select * from {{ ref('int_shipment_items_enriched') }}
),

shipments as (
    select * from {{ ref('int_shipments_enriched') }}
),

-- Commercial metrics from items (correct grain for value)
item_metrics as (
    select
        account_id,
        count(distinct shipment_id) as total_shipments,
        count(distinct device_id) as unique_devices_ordered,
        sum(total_line_value) as total_account_value
    from items
    group by 1
),

-- CX metrics from shipments (correct grain for review + on-time)
shipment_metrics as (
    select
        a.account_id,
        avg(s.survey_score) as avg_account_nps_score,
        avg(s.is_on_time) as on_time_delivery_rate
    from shipments s
    left join items a
        on s.shipment_id = a.shipment_id
    group by 1
),

final as (
    select
        a.account_id,
        a.city,
        a.state,

        coalesce(i.total_shipments, 0) as total_shipments,
        coalesce(i.unique_devices_ordered, 0) as unique_devices_ordered,
        coalesce(i.total_account_value, 0) as total_lifetime_value,

        sm.avg_account_nps_score,
        sm.on_time_delivery_rate,

        case
            when coalesce(i.total_account_value, 0) > 10000 then 'Tier 1 (Key Account)'
            when coalesce(i.total_account_value, 0) > 2000 then 'Tier 2 (Growth)'
            else 'Tier 3 (Standard)'
        end as account_segment

    from account_base a
    left join item_metrics i
        on a.account_id = i.account_id
    left join shipment_metrics sm
        on a.account_id = sm.account_id
)

select * from final