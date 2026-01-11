with shipments as (
    select * from {{ ref('stg_olist__orders') }}
),

-- 1 row per shipment_id (deterministic)
account_map as (
    select
        shipment_id,
        min(account_id) as account_id
    from {{ ref('int_shipment_items_enriched') }}
    group by 1
),

-- 1 row per shipment_id (latest)
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
                order by survey_responded_at desc nulls last, review_id desc
            ) as rn
        from {{ ref('stg_olist__reviews') }}
    )
    where rn = 1
),

final as (
    select
        s.shipment_id,
        a.account_id,
        s.hcp_id,
        s.shipment_status,
        s.ordered_at,
        s.delivered_at,
        s.estimated_delivery_at,

        r.survey_score,
        r.nps_category,
        r.survey_responded_at,

        case
            when s.delivered_at is null or s.estimated_delivery_at is null then null
            when s.delivered_at <= s.estimated_delivery_at then 1
            else 0
        end as is_on_time,

        case
            when s.delivered_at is null or s.ordered_at is null then null
            else datediff('day', s.ordered_at, s.delivered_at)
        end as days_to_deliver

    from shipments s
    left join account_map a
        on s.shipment_id = a.shipment_id
    left join latest_review r
        on s.shipment_id = r.shipment_id
)

select * from final