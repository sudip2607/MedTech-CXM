select
    shipment_id,
    account_id,
    hcp_id,
    shipment_status,
    ordered_at,
    delivered_at,
    estimated_delivery_at,
    is_on_time,
    days_to_deliver,
    survey_score,
    nps_category,
    survey_responded_at
from {{ ref('int_shipments_enriched') }}