/* ============================================================
   Supply Chain KPI Calculations
   ============================================================
   Tables used:
     fact_order_line  — one row per product line per order
     fact_aggregate   — one row per order (aggregated view)

   Compatible with: PostgreSQL, MySQL 8+, SQL Server, BigQuery
   (minor syntax notes added where dialects differ)
   ============================================================ */


-- ─────────────────────────────────────────────────────────────
-- KPI 1 & 2 & 3 — Order line level metrics
-- ─────────────────────────────────────────────────────────────

SELECT

    -- 1. Total Order Lines
    COUNT(*)                                                    AS total_order_lines,

    -- 2. Line Fill Rate
    --    Lines fully delivered / total lines
    ROUND(
        100.0 * SUM(in_full) / COUNT(*),
        2
    )                                                           AS line_fill_rate_pct,

    -- 3. Volume Fill Rate
    --    Actual delivery qty vs ordered qty
    ROUND(
        100.0 * SUM(delivery_qty) / NULLIF(SUM(order_qty), 0),
        2
    )                                                           AS volume_fill_rate_pct

FROM fact_order_line;


-- ─────────────────────────────────────────────────────────────
-- KPI 4, 5, 6 & 7 — Order level metrics
-- ─────────────────────────────────────────────────────────────

SELECT

    -- 4. Total Orders (distinct)
    COUNT(DISTINCT order_id)                                    AS total_orders,

    -- 5. On Time Delivery %
    ROUND(
        100.0 * SUM(on_time) / COUNT(*),
        2
    )                                                           AS on_time_delivery_pct,

    -- 6. In Full Delivery %
    ROUND(
        100.0 * SUM(in_full) / COUNT(*),
        2
    )                                                           AS in_full_delivery_pct,

    -- 7. On Time In Full (OTIF) %
    ROUND(
        100.0 * SUM(otif) / COUNT(*),
        2
    )                                                           AS otif_pct

FROM fact_aggregate;


/* ============================================================
   BONUS: All 7 KPIs in a single query using CTEs
   ============================================================ */

WITH line_metrics AS (
    SELECT
        COUNT(*)                                                AS total_order_lines,
        ROUND(100.0 * SUM(in_full)      / COUNT(*),         2) AS line_fill_rate_pct,
        ROUND(100.0 * SUM(delivery_qty) / NULLIF(SUM(order_qty), 0), 2)
                                                                AS volume_fill_rate_pct
    FROM fact_order_line
),

order_metrics AS (
    SELECT
        COUNT(DISTINCT order_id)                                AS total_orders,
        ROUND(100.0 * SUM(on_time) / COUNT(*),              2) AS on_time_pct,
        ROUND(100.0 * SUM(in_full) / COUNT(*),              2) AS in_full_pct,
        ROUND(100.0 * SUM(otif)    / COUNT(*),              2) AS otif_pct
    FROM fact_aggregate
)

SELECT
    lm.total_order_lines,
    lm.line_fill_rate_pct,
    lm.volume_fill_rate_pct,
    om.total_orders,
    om.on_time_pct,
    om.in_full_pct,
    om.otif_pct
FROM line_metrics lm
CROSS JOIN order_metrics om;


/* ============================================================
   BONUS: KPIs sliced by Customer
   Useful for identifying which customers have worst OTIF
   ============================================================ */

SELECT
    fa.customer_id,
    dc.customer_name,
    COUNT(DISTINCT fa.order_id)                                 AS total_orders,
    ROUND(100.0 * SUM(fa.on_time) / COUNT(*),               2) AS on_time_pct,
    ROUND(100.0 * SUM(fa.in_full) / COUNT(*),               2) AS in_full_pct,
    ROUND(100.0 * SUM(fa.otif)    / COUNT(*),               2) AS otif_pct
FROM fact_aggregate fa
LEFT JOIN dim_customers dc
    ON fa.customer_id = dc.customer_id
GROUP BY
    fa.customer_id,
    dc.customer_name
ORDER BY
    otif_pct ASC;   -- worst performers first
