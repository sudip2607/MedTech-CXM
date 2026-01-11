with base as (
    select * from {{ ref('dim_account') }}
),

scored as (
    select
        *,
        /* Score Components (0–100) */
        round(on_time_delivery_rate * 40, 1) as delivery_score,
        round(coalesce(avg_account_nps_score, 0) / 5 * 40, 1) as sentiment_score,
        case 
            when total_shipments >= 10 then 20
            when total_shipments >= 3 then 10
            else 5
        end as engagement_score
    from base
),

final as (
    select
        account_id,
        delivery_score,
        sentiment_score,
        engagement_score,
        delivery_score + sentiment_score + engagement_score as cx_health_score,
        case
            when delivery_score + sentiment_score + engagement_score >= 80 then 'Healthy'
            when delivery_score + sentiment_score + engagement_score >= 60 then 'Watch'
            else 'At Risk'
        end as cx_health_status
    from scored
)

select * from final