with hcp_base as (
    select * from {{ ref('stg_olist__hcp') }}
),

shipments as (
    select * from {{ ref('int_shipments_enriched') }}
),

hcp_metrics as (
    select
        hcp_id,
        count(shipment_id) as total_orders,
        min(ordered_at) as first_order_at,
        max(ordered_at) as last_order_at,
        avg(survey_score) as avg_hcp_nps_score,
        count(case when nps_category = 'Detractor' then 1 end) as total_detractions
    from shipments
    group by 1
),

final as (
    select
        h.hcp_id,
        h.city,
        h.state,
        coalesce(m.total_orders, 0) as total_orders,
        m.first_order_at,
        m.last_order_at,
        m.avg_hcp_nps_score,
        m.total_detractions,
        
        -- Logic: HCP Loyalty Status
        case 
            when m.total_orders > 5 then 'Frequent User'
            when m.total_orders > 1 then 'Repeat User'
            else 'New/One-time User'
        end as loyalty_status

    from hcp_base h
    left join hcp_metrics m on h.hcp_id = m.hcp_id
)

select * from final
