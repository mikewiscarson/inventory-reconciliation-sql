# Inventory Reconciliation SQL Project

## Problem
Parts consumed under a consignment program have to be reconciled against inventory the system shows as on hand. The complication is that inventory is not one pooled quantity per part number. It is held at the part number, batch, and plant level, and each of those combinations is a separate bucket that has to be consumed on its own terms. A batch is a unique receipt of material from the manufacturer, and the same batch can be split across more than one physical warehouse.

Demand comes in at the line level. A single shipment reference can carry multiple part numbers, and the same part number can appear more than once on the same reference with a different quantity and delivery date. Each line has to be reconciled individually, because the line is what gets entered downstream for billing.

Two things make this harder than a totals comparison. A single demand line can draw from several batch and plant buckets when no one bucket covers it. And inventory consumed by an earlier line is no longer available to a later one, so demand for the same part number has to be worked in sequence.

## Approach
Demand and inventory were loaded into SQLite as two tables and reconciled with a running total allocation.

Both sides are given a cumulative position per part number, which turns every row into a numeric interval. A demand line occupying positions 100 through 250 and an inventory bucket occupying positions 180 through 400 overlap between 180 and 250, and that overlap is the quantity allocated from that bucket to that line. Because the positions are cumulative, inventory already consumed by earlier lines sits below the current line's interval and cannot be allocated twice.

The allocation produces one row per demand line per bucket consumed, showing the shipment reference, part number, delivery date, batch, plant, and quantity taken. Line status is then derived from the allocation rather than assumed up front:

* **Full**: allocated quantity equals the quantity needed
* **Partial**: some quantity was allocated but not all of it
* **Unfulfillable**: no inventory was available to allocate

## Result
1,217 demand lines were reconciled against 896 inventory buckets, producing 1,424 allocation records. 775 lines were fully covered, 125 were partially covered, and 317 had no inventory available at all. 340 lines required more than one batch and plant combination to fill.

The allocation table is the working output. It is traceable line by line, so any single order can be tied back to the exact buckets it consumed, which is what makes the result usable for order entry rather than just a summary count.

## Files
* `demand.csv` — sample demand data (line ID, shipment reference, part number, quantity needed, delivery date)
* `inventory.csv` — sample inventory data (part number, batch, plant, quantity on hand)
* `reconciliation.sql` — allocation and classification queries
* `allocation.csv` — one row per demand line per bucket consumed
* `full_orders.csv`, `partial_orders.csv`, `unfulfillable_orders.csv` — line status by outcome

## Note
All data in this repository is synthetic. No employer data is used.
