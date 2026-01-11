with source as (
    select * from {{ source('olist', 'olist_order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id as shipment_id,
        cast(review_score as integer) as survey_score,
        review_comment_title as survey_title,
        review_comment_message as survey_comments,
        cast(review_creation_date as timestamp_ntz) as survey_sent_at,
        cast(review_answer_timestamp as timestamp_ntz) as survey_responded_at,
        _load_timestamp,
        _batch_id
    from source
)

select * from renamed