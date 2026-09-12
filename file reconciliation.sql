DROP TABLE IF EXISTS full_orders;
CREATE TABLE full_orders AS
SELECT d.part_number,
       SUM(d.quantity_needed) AS total_demand,
       COALESCE(SUM(i.quantity_on_hand), 0) AS total_inventory
FROM demand d
LEFT JOIN inventory i ON d.part_number = i.part_number
GROUP BY d.part_number
HAVING COALESCE(SUM(i.quantity_on_hand), 0) >= SUM(d.quantity_needed);

DROP TABLE IF EXISTS partial_orders;
CREATE TABLE partial_orders AS
SELECT d.part_number,
       SUM(d.quantity_needed) AS total_demand,
       COALESCE(SUM(i.quantity_on_hand), 0) AS total_inventory
FROM demand d
LEFT JOIN inventory i ON d.part_number = i.part_number
GROUP BY d.part_number
HAVING COALESCE(SUM(i.quantity_on_hand), 0) > 0
   AND COALESCE(SUM(i.quantity_on_hand), 0) < SUM(d.quantity_needed);

DROP TABLE IF EXISTS unfulfillable_orders;
CREATE TABLE unfulfillable_orders AS
SELECT d.part_number,
       SUM(d.quantity_needed) AS total_demand,
       0 AS total_inventory
FROM demand d
LEFT JOIN inventory i ON d.part_number = i.part_number
GROUP BY d.part_number
HAVING COALESCE(SUM(i.quantity_on_hand), 0) = 0;
