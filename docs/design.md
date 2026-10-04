# Food Order DBMS Project - MySQL Design Notes

## Overview
This project models a food-ordering system using MySQL 8.0+. The original project was Oracle-based; this edition keeps the relational model and DBMS concepts while translating Oracle-only syntax.

## Main entities
- Customers
- Restaurants
- Cuisines
- Orders
- Restaurant_Cuisine (many-to-many relationship)
- Order_Audit
- STG_FOOD_ORDER (raw staging table)

## Normalization
The staging table contains repeated restaurant and cuisine names. The final design separates those values into master tables and uses foreign keys. The `rating` value `Not given` is converted to SQL `NULL` so its domain is atomic.

## Keys and integrity
Primary keys provide entity integrity. Foreign keys provide referential integrity. `NOT NULL` and `CHECK` constraints provide domain integrity. The composite foreign key on Orders ensures that a restaurant can only receive an order for a cuisine it serves.

## MySQL-specific implementation
MySQL InnoDB uses clustered primary-key storage and B+tree indexes. Secondary indexes support lookups and joins. `information_schema` provides metadata about tables, columns and constraints. `EXPLAIN` is used for query-plan analysis.

## Transactions
InnoDB provides ACID transactions, row-level locking, isolation levels, undo/redo logging and deadlock detection. The project demonstrates these through transactions, savepoints, `FOR UPDATE`, and two-session locking examples.

## Oracle features converted
Oracle sequences are represented with `AUTO_INCREMENT`; PL/SQL is represented by MySQL stored procedures/functions; Oracle `ROWNUM` becomes `LIMIT`; `NVL` becomes `COALESCE`; `MERGE` becomes an upsert; `EXPLAIN PLAN/DBMS_XPLAN` becomes `EXPLAIN`; Oracle data dictionary views become `information_schema` queries.

Some Oracle physical-storage features have no direct MySQL equivalent. The MySQL version therefore demonstrates the corresponding concept using InnoDB metadata, indexes, `EXPLAIN`, and a generated-hash lookup example.
