with shipments as (
    select * from {{ ref('stg_olist__orders') }}
),

hcp as (
    select * from {{ ref('stg_olist__hcp') }}
),

accounts as (
    select * from {{ ref('stg_olist__accounts') }}
),

reviews as (
    select * from {{ ref('stg_olist__reviews') }}
),

final as (
    select
        s.shipment_id,
        s.hcp_id,
        s.shipment_status,
        s.ordered_at,
        s.approved_at,
        s.delivered_at,
        s.estimated_delivery_at,
        
        -- HCP Details
        h.city as hcp_city,
        h.state as hcp_state,
        
        -- Review/NPS Details (Joining on shipment_id)
        r.survey_score,
        r.survey_responded_at,
        
        -- Logic: On-Time Delivery Flag
        case 
            when s.delivered_at <= s.estimated_delivery_at then 1 
            else 0 
        end as is_on_time,
        
        -- Logic: Days to Deliver
        datediff('day', s.ordered_at, s.delivered_at) as days_to_deliver,
        
        -- Logic: NPS Category
        case 
            when r.survey_score >= 4 then 'Promoter'
            when r.survey_score = 3 then 'Passive'
            when r.survey_score is not null then 'Detractor'
            else null
        end as nps_category

    from shipments s
    left join hcp h on s.hcp_id = h.hcp_id
    left join reviews r on s.shipment_id = r.shipment_id
)

select * from final
