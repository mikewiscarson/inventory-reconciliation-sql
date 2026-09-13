-- Inventory allocation and reconciliation
--
-- Demand is evaluated line by line. Inventory is held at the part number,
-- batch and plant level, and each of those combinations is a separate bucket
-- that must be consumed on its own. A single demand line may draw from several
-- buckets, and inventory consumed by an earlier line is not available to a
-- later one.
--
-- The allocation is done by giving both demand and inventory a running total
-- per part number, which turns each row into a numeric interval. Where a
-- demand interval and an inventory interval overlap, that overlap is the
-- quantity allocated from that bucket to that line.

DROP TABLE IF EXISTS demand_position;
CREATE TABLE demand_position AS
SELECT
    demand_line_id,
    asn,
    part_number,
    delivery_date,
    quantity_needed,
    SUM(quantity_needed) OVER (
        PARTITION BY part_number
        ORDER BY demand_line_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS demand_start,
    SUM(quantity_needed) OVER (
        PARTITION BY part_number
        ORDER BY demand_line_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS demand_end
FROM demand;

DROP TABLE IF EXISTS inventory_position;
CREATE TABLE inventory_position AS
SELECT
    part_number,
    batch,
    plant,
    quantity_on_hand,
    SUM(quantity_on_hand) OVER (
        PARTITION BY part_number
        ORDER BY batch, plant
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS inventory_start,
    SUM(quantity_on_hand) OVER (
        PARTITION BY part_number
        ORDER BY batch, plant
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS inventory_end
FROM inventory;

DROP TABLE IF EXISTS allocation;
CREATE TABLE allocation AS
SELECT
    d.demand_line_id,
    d.asn,
    d.part_number,
    d.delivery_date,
    d.quantity_needed,
    i.batch,
    i.plant,
    MIN(d.demand_end, i.inventory_end)
        - MAX(COALESCE(d.demand_start, 0), COALESCE(i.inventory_start, 0))
        AS quantity_allocated
FROM demand_position d
JOIN inventory_position i
  ON d.part_number = i.part_number
WHERE MIN(d.demand_end, i.inventory_end)
      > MAX(COALESCE(d.demand_start, 0), COALESCE(i.inventory_start, 0));

DROP TABLE IF EXISTS line_status;
CREATE TABLE line_status AS
SELECT
    d.demand_line_id,
    d.asn,
    d.part_number,
    d.delivery_date,
    d.quantity_needed,
    COALESCE(SUM(a.quantity_allocated), 0) AS quantity_allocated,
    d.quantity_needed - COALESCE(SUM(a.quantity_allocated), 0) AS quantity_short,
    COUNT(a.batch) AS buckets_used,
    CASE
        WHEN COALESCE(SUM(a.quantity_allocated), 0) = 0 THEN 'UNFULFILLABLE'
        WHEN SUM(a.quantity_allocated) < d.quantity_needed THEN 'PARTIAL'
        ELSE 'FULL'
    END AS status
FROM demand d
LEFT JOIN allocation a
  ON d.demand_line_id = a.demand_line_id
GROUP BY d.demand_line_id, d.asn, d.part_number,
         d.delivery_date, d.quantity_needed;

DROP TABLE IF EXISTS full_orders;
CREATE TABLE full_orders AS
SELECT * FROM line_status WHERE status = 'FULL';

DROP TABLE IF EXISTS partial_orders;
CREATE TABLE partial_orders AS
SELECT * FROM line_status WHERE status = 'PARTIAL';

DROP TABLE IF EXISTS unfulfillable_orders;
CREATE TABLE unfulfillable_orders AS
SELECT * FROM line_status WHERE status = 'UNFULFILLABLE';
