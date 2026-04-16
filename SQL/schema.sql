-- ============================================================
-- AtliQ Mart Supply Chain Intelligence
-- Database Schema — Star Schema Design
-- PostgreSQL / Supabase
-- ============================================================

-- Dimension: Customers
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id   BIGINT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    city          TEXT NOT NULL,
    currency      TEXT NOT NULL
);

-- Dimension: Products
CREATE TABLE IF NOT EXISTS dim_products (
    product_id   BIGINT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category     TEXT NOT NULL,
    price_inr    BIGINT,
    price_usd    FLOAT
);

-- Dimension: Order Targets (SLA per customer)
CREATE TABLE IF NOT EXISTS dim_targets_orders (
    customer_id       BIGINT PRIMARY KEY,
    ontime_target_pct BIGINT,
    infull_target_pct BIGINT,
    otif_target_pct   BIGINT
);

-- Fact: Order Line (one row per product per order)
CREATE TABLE IF NOT EXISTS fact_order_line (
    order_id              TEXT,
    order_placement_date  DATE,
    customer_id           BIGINT,
    product_id            BIGINT,
    order_qty             BIGINT,
    agreed_delivery_date  DATE,
    actual_delivery_date  DATE,
    delivery_qty          BIGINT,
    in_full               BIGINT,
    on_time               BIGINT,
    on_time_in_full       BIGINT,
    PRIMARY KEY (order_id, product_id)
);

-- Fact: Aggregate (one row per order)
CREATE TABLE IF NOT EXISTS fact_aggregate (
    order_id             TEXT PRIMARY KEY,
    customer_id          BIGINT,
    order_placement_date DATE,
    on_time              BIGINT,
    in_full              BIGINT,
    otif                 BIGINT
);

-- Add composite PK for fact_order_line (if importing without PK)
-- ALTER TABLE fact_order_line ADD PRIMARY KEY (order_id, product_id);
