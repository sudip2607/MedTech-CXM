with source as (
    select * from {{ source('olist', 'olist_customers') }}
),

renamed as (
    select
        customer_id as hcp_id,
        customer_unique_id as hcp_unique_id,
        customer_zip_code_prefix as zip_code,
        customer_city as city,
        customer_state as state,
        _load_timestamp,
        _batch_id
    from source
)

select * from renamed