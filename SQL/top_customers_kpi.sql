/* ============================================================
   Top Customers KPI Analysis
   ============================================================
   Prompt 5 : Top 5 globally by order value + OT% / IF% / OTIF%
   Prompt 6 : Top 5 India customers by order value + OT% / IF% / OTIF%

   Tables:
     fact_summary    — order lines with total_amount
     fact_aggregate  — order level: on_time, in_full, otif flags
     dim_customers   — customer_id, customer_name, city
   ============================================================ */


/* ─── Shared CTE: build per-customer metrics ─────────────────── */

WITH order_value AS (

    SELECT
        customer_id,
        SUM(total_amount) AS order_value
    FROM fact_summary
    GROUP BY customer_id

),

delivery_kpis AS (

    SELECT
        customer_id,
        COUNT(*)                                                     AS total_orders,
        ROUND(100.0 * SUM(on_time) / COUNT(*),                   2) AS ot_pct,
        ROUND(100.0 * SUM(in_full) / COUNT(*),                   2) AS if_pct,
        ROUND(100.0 * SUM(otif)    / COUNT(*),                   2) AS otif_pct
    FROM fact_aggregate
    GROUP BY customer_id

),

customer_summary AS (

    SELECT
        dc.customer_id,
        dc.customer_name,
        dc.city,
        ov.order_value,
        dk.ot_pct,
        dk.if_pct,
        dk.otif_pct
    FROM dim_customers dc
    JOIN order_value   ov ON dc.customer_id = ov.customer_id
    JOIN delivery_kpis dk ON dc.customer_id = dk.customer_id

)


/* ─── Prompt 5: Top 5 Customers — Global ────────────────────── */

SELECT
    ROW_NUMBER() OVER (ORDER BY order_value DESC) AS rank,
    customer_id,
    customer_name,
    city,
    ROUND(order_value, 2)                         AS order_value,
    ot_pct                                        AS "OT %",
    if_pct                                        AS "IF %",
    otif_pct                                      AS "OTIF %"
FROM customer_summary
ORDER BY order_value DESC
LIMIT 5;


/* ─── Prompt 6: Top 5 Customers — India ─────────────────────── */
/* India = exclude cities containing 'US'                         */

SELECT
    ROW_NUMBER() OVER (ORDER BY order_value DESC) AS rank,
    customer_id,
    customer_name,
    city,
    ROUND(order_value, 2)                         AS order_value,
    ot_pct                                        AS "OT %",
    if_pct                                        AS "IF %",
    otif_pct                                      AS "OTIF %"
FROM customer_summary
WHERE city NOT LIKE '%US%'
ORDER BY order_value DESC
LIMIT 5;
