select
    account_id,
    city,
    state,
    account_segment,
    total_shipments,
    unique_devices_ordered,
    total_lifetime_value,
    avg_account_nps_score,
    on_time_delivery_rate
from {{ ref('int_accounts_360') }}