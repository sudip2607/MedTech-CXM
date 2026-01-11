select
    hcp_id,
    city,
    state,
    loyalty_status,
    total_orders,
    avg_hcp_nps_score,
    total_detractions,
    first_order_at,
    last_order_at
from {{ ref('int_hcp_360') }}
