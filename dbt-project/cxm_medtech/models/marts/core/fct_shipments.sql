select
    shipment_id,
    hcp_id,
    shipment_status,
    ordered_at,
    delivered_at,
    estimated_delivery_at,
    is_on_time,
    days_to_deliver,
    survey_score,
    nps_category
from {{ ref('int_shipments_enriched') }}
