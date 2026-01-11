select
    geolocation_zip_code_prefix as zip_code,
    cast(geolocation_lat as float) as latitude,
    cast(geolocation_lng as float) as longitude,
    geolocation_city as city,
    geolocation_state as state,
    _load_timestamp,
    _batch_id
from {{ source('olist', 'olist_geolocation') }}