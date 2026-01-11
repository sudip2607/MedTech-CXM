with shipments as (
    select * from {{ ref('stg_olist__orders') }}
),

hcp as (
    select * from {{ ref('stg_olist__hcp') }}
),

-- Keep ALL reviews in staging, but select ONLY the latest per shipment here
latest_review as (
    select
        shipment_id,
        survey_score,
        survey_responded_at,

        case
            when survey_score >= 4 then 'Promoter'
            when survey_score = 3 then 'Passive'
            when survey_score is not null then 'Detractor'
            else null
        end as nps_category

    from (
        select
            shipment_id,
            survey_score,
            survey_responded_at,
            row_number() over (
                partition by shipment_id
                order by survey_responded_at desc nulls last
            ) as rn
        from {{ ref('stg_olist__reviews') }}
    )
    where rn = 1
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

        -- HCP details
        h.city as hcp_city,
        h.state as hcp_state,

        -- Latest review (one row per shipment, safe)
        r.survey_score,
        r.nps_category,
        r.survey_responded_at,

        -- On-time flag
        case
            when s.delivered_at is null or s.estimated_delivery_at is null then null
            when s.delivered_at <= s.estimated_delivery_at then 1
            else 0
        end as is_on_time,

        -- Days to deliver
        case
            when s.delivered_at is null or s.ordered_at is null then null
            else datediff('day', s.ordered_at, s.delivered_at)
        end as days_to_deliver

    from shipments s
    left join hcp h
        on s.hcp_id = h.hcp_id
    left join latest_review r
        on s.shipment_id = r.shipment_id
)

select * from final
