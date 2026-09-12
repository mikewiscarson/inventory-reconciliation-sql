# Inventory Reconciliation SQL Project

## Problem
A demand list of parts needed and an inventory list of parts on hand rarely match up perfectly. Some demand can be fully covered by available inventory, some can only be partially covered, and some cannot be covered at all. Manually comparing these lists line by line does not scale and is easy to get wrong.

## Approach
Using SQLite, demand and inventory data were loaded into two tables and joined on part number. Three SQL queries classified every part into one of three outcomes:

* **Full orders**: total inventory on hand meets or exceeds total demand
* **Partial orders**: some inventory exists but not enough to fully cover demand
* **Unfulfillable orders**: no inventory exists at all for that part

Each query grouped and summed quantities by part number, then filtered based on how inventory compared to demand.

## Result
The reconciliation split demand into three clear, exportable lists: full_orders.csv, partial_orders.csv, and unfulfillable_orders.csv. This mirrors a real reconciliation process used to identify which demand can be fulfilled immediately, which needs partial fulfillment, and which requires further sourcing or investigation, without manually cross checking thousands of lines by hand.

## Files
* `demand.csv` — sample demand data (part number, reference ID, quantity needed)
* `inventory.csv` — sample inventory data (part number, batch, plant, quantity on hand)
* `reconciliation.sql` — SQL queries used to classify demand
* `full_orders.csv`, `partial_orders.csv`, `unfulfillable_orders.csv` — output of the reconciliation
