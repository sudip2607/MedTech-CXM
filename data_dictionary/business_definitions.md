# Business Definitions

## 4.1 Domain entities (MedTech CXM)

Account (Hospital / Facility / IDN Node)
Definition: A healthcare delivery organization that places orders and receives shipments.
Source mapping: Derived from Olist entities (initially sellers, potentially enriched later).
Grain: 1 row per account.
End User (HCP: clinician/surgeon/nurse/tech)
Definition: A clinical staff member interacting with product and providing survey responses.
Source mapping: Derived from Olist customers (as “HCP persona”), with synthetic attributes later (specialty, role).
Grain: 1 row per HCP.
Order (Surgical Case Shipment / Device Order)
Definition: A shipment/order event representing a surgical case supply delivery.
Source mapping: Olist orders + order_items.
Grain: 1 row per order (shipments at order level; line items at order_item level).
Product (Device / Kit / Consumable)
Definition: Medical product shipped to fulfill cases.
Source mapping: Olist products.
Grain: 1 row per product.
Survey Response (NPS/CSAT)
Definition: A post-case experience response from an HCP.
Source mapping: Olist order_reviews with “review_score” mapped to NPS/CSAT-like outcomes (document mapping).
Grain: 1 row per review.

## 4.2 KPI definitions (MLP v1)

NPS Band (proxy)
Mapping from review_score (1–5) to NPS:
1–2 = Detractor
3 = Passive
4–5 = Promoter
Note: This is a proxy; we document it clearly.
On-time Delivery % (proxy)
Definition: % orders where delivered timestamp ≤ estimated delivery timestamp.
Source: orders timestamps.
Tickets per 100 Shipments (synthetic)
Definition: (tickets_count / shipments_count) * 100
Source: synthetic support_tickets table joined to orders/accounts.
CX Health Score (rule-based, explainable)
Definition: Weighted score combining delivery performance, NPS band, ticket rate, SLA breaches.
Note: implemented later in MARTS with transparent components.

## 4.3 Grains (non-negotiable)

RAW.olist_orders: 1 row per order id per batch load
RAW.olist_order_items: 1 row per order_item id per batch load
RAW.olist_order_reviews: 1 row per review id per batch load
dim_account: 1 row per account
fct_shipments: 1 row per order (shipment)
