select
    {{ dbt_utils.generate_surrogate_key([
        'review_id',
        'shipment_id',
        'survey_responded_at'
    ]) }} as review_key,

    review_id,
    shipment_id,
    survey_score,
    survey_responded_at,

    case
        when survey_score >= 4 then 'Promoter'
        when survey_score = 3 then 'Passive'
        when survey_score is not null then 'Detractor'
        else null
    end as nps_category

from {{ ref('stg_olist__reviews') }}