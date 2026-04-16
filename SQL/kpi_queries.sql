-- ============================================================
-- AtliQ Mart Supply Chain Intelligence
-- KPI Queries — Supply Chain Analytics
-- ============================================================

-- ── 1. TOTAL ORDER LINES ─────────────────────────────────────
SELECT COUNT(*) AS total_order_lines
FROM fact_order_line;

-- ── 2. TOTAL ORDERS ──────────────────────────────────────────
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM fact_aggregate;

-- ── 3. LINE FILL RATE ─────────────────────────────────────────
SELECT
    ROUND(SUM(in_full)::NUMERIC / COUNT(*) * 100, 2) AS line_fill_rate_pct
FROM fact_order_line;

-- ── 4. VOLUME FILL RATE ───────────────────────────────────────
SELECT
    ROUND(SUM(delivery_qty)::NUMERIC / SUM(order_qty) * 100, 2) AS volume_fill_rate_pct
FROM fact_order_line;

-- ── 5. ON TIME DELIVERY % ─────────────────────────────────────
SELECT
    ROUND(SUM(on_time)::NUMERIC / COUNT(*) * 100, 2) AS on_time_pct
FROM fact_aggregate;

-- ── 6. IN FULL DELIVERY % ─────────────────────────────────────
SELECT
    ROUND(SUM(in_full)::NUMERIC / COUNT(*) * 100, 2) AS in_full_pct
FROM fact_aggregate;

-- ── 7. OTIF % ─────────────────────────────────────────────────
SELECT
    ROUND(SUM(otif)::NUMERIC / COUNT(*) * 100, 2) AS otif_pct
FROM fact_aggregate;

-- ── 8. ALL KPIs IN ONE QUERY ──────────────────────────────────
SELECT
    (SELECT COUNT(*) FROM fact_order_line)                                          AS total_order_lines,
    (SELECT COUNT(DISTINCT order_id) FROM fact_aggregate)                           AS total_orders,
    ROUND(SUM(fol.in_full)::NUMERIC / COUNT(fol.*) * 100, 2)                       AS line_fill_rate_pct,
    ROUND(SUM(fol.delivery_qty)::NUMERIC / SUM(fol.order_qty) * 100, 2)            AS volume_fill_rate_pct,
    ROUND(SUM(fa.on_time)::NUMERIC / COUNT(fa.*) * 100, 2)                         AS on_time_pct,
    ROUND(SUM(fa.in_full)::NUMERIC / COUNT(fa.*) * 100, 2)                         AS in_full_pct,
    ROUND(SUM(fa.otif)::NUMERIC / COUNT(fa.*) * 100, 2)                            AS otif_pct
FROM fact_order_line fol
CROSS JOIN fact_aggregate fa;

-- ── 9. TOP 5 CUSTOMERS BY ORDER VALUE (GLOBAL) ───────────────
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    ROUND(SUM(fol.delivery_qty * p.price_usd)::NUMERIC, 2)      AS order_value_usd,
    ROUND(AVG(fol.on_time) * 100, 2)                             AS on_time_pct,
    ROUND(AVG(fol.in_full) * 100, 2)                             AS in_full_pct,
    ROUND(AVG(fol.on_time_in_full) * 100, 2)                     AS otif_pct
FROM fact_order_line fol
JOIN dim_customers c   ON fol.customer_id = c.customer_id
JOIN dim_products p    ON fol.product_id  = p.product_id
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY order_value_usd DESC
LIMIT 5;

-- ── 10. TOP 5 CUSTOMERS IN INDIA ──────────────────────────────
SELECT
    c.customer_id,
    c.customer_name,
    c.city,
    ROUND(SUM(fol.delivery_qty * p.price_inr)::NUMERIC, 2)       AS order_value_inr,
    ROUND(AVG(fol.on_time) * 100, 2)                              AS on_time_pct,
    ROUND(AVG(fol.in_full) * 100, 2)                              AS in_full_pct,
    ROUND(AVG(fol.on_time_in_full) * 100, 2)                      AS otif_pct
FROM fact_order_line fol
JOIN dim_customers c   ON fol.customer_id = c.customer_id
JOIN dim_products p    ON fol.product_id  = p.product_id
WHERE c.city NOT LIKE '%US%'
GROUP BY c.customer_id, c.customer_name, c.city
ORDER BY order_value_inr DESC
LIMIT 5;

-- ── 11. OTIF GAP VS TARGET ────────────────────────────────────
SELECT
    c.customer_name,
    c.city,
    ROUND(AVG(fa.otif) * 100, 2)     AS actual_otif_pct,
    t.otif_target_pct                 AS target_otif_pct,
    t.otif_target_pct - ROUND(AVG(fa.otif) * 100, 2) AS gap_points
FROM fact_aggregate fa
JOIN dim_customers c        ON fa.customer_id = c.customer_id
JOIN dim_targets_orders t   ON fa.customer_id = t.customer_id
GROUP BY c.customer_name, c.city, t.otif_target_pct
ORDER BY gap_points DESC
LIMIT 10;

-- ── 12. REVENUE LOSS FROM UNDELIVERED ORDERS ──────────────────
SELECT
    ROUND(SUM(fol.order_qty   * p.price_inr)::NUMERIC, 0)    AS total_ordered_revenue_inr,
    ROUND(SUM(fol.delivery_qty * p.price_inr)::NUMERIC, 0)    AS total_delivered_revenue_inr,
    ROUND((SUM(fol.order_qty) - SUM(fol.delivery_qty))
           * AVG(p.price_inr)::NUMERIC, 0)                    AS revenue_loss_inr,
    ROUND(
        (1 - SUM(fol.delivery_qty)::NUMERIC / SUM(fol.order_qty)) * 100, 2
    )                                                          AS revenue_loss_pct
FROM fact_order_line fol
JOIN dim_products p ON fol.product_id = p.product_id;

-- ── 13. PRODUCT CATEGORY IN FULL ANALYSIS ─────────────────────
SELECT
    p.category,
    ROUND(AVG(fol.in_full) * 100, 2)                          AS in_full_rate_pct,
    ROUND(SUM(fol.delivery_qty)::NUMERIC
          / SUM(fol.order_qty) * 100, 2)                      AS volume_fill_rate_pct,
    COUNT(*)                                                   AS total_order_lines
FROM fact_order_line fol
JOIN dim_products p ON fol.product_id = p.product_id
GROUP BY p.category
ORDER BY in_full_rate_pct;

-- ── 14. AVERAGE DELAY FOR LATE DELIVERIES ─────────────────────
SELECT
    COUNT(*)                                                            AS total_late_deliveries,
    ROUND(AVG(actual_delivery_date - agreed_delivery_date)::NUMERIC, 2) AS avg_delay_days,
    MAX(actual_delivery_date - agreed_delivery_date)                    AS max_delay_days
FROM fact_order_line
WHERE on_time = 0
  AND actual_delivery_date > agreed_delivery_date;

-- ── 15. MONTHLY OTIF TREND ────────────────────────────────────
SELECT
    DATE_TRUNC('month', order_placement_date)  AS month,
    ROUND(AVG(otif) * 100, 2)                  AS otif_pct,
    ROUND(AVG(on_time) * 100, 2)               AS on_time_pct,
    ROUND(AVG(in_full) * 100, 2)               AS in_full_pct,
    COUNT(*)                                   AS total_orders
FROM fact_aggregate
GROUP BY 1
ORDER BY 1;
