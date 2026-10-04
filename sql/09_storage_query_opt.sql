-- 09_storage_query_opt.sql | MySQL 8.0+
-- Storage, B+tree indexes, hashing concept and query optimization.

-- 1. Physical/storage information.
SELECT table_name, engine, table_rows, data_length, index_length
FROM information_schema.tables WHERE table_schema=DATABASE() ORDER BY data_length DESC;
SHOW TABLE STATUS LIKE 'orders';

-- InnoDB indexes are B+tree-style indexes. MySQL does not expose Oracle ROWID.
SHOW INDEX FROM orders;
SHOW INDEX FROM restaurants;

-- 2. InnoDB primary/secondary indexes.
EXPLAIN SELECT * FROM orders WHERE customer_id=337525;
EXPLAIN SELECT * FROM orders WHERE cost_of_order>34;
EXPLAIN SELECT * FROM restaurants WHERE UPPER(restaurant_name)='SHAKE SHACK';

-- 3. Optimizer statistics.
ANALYZE TABLE orders, restaurants, cuisines;

-- 4. Hashing concept.
-- MySQL InnoDB uses B+tree indexes for normal indexes; it also has an adaptive
-- hash index internally. A manually created Oracle-style HASH CLUSTER is not
-- available in MySQL, so this section demonstrates an equivalent hash lookup
-- concept with a generated hash column and index.
DROP TABLE IF EXISTS orders_hashed;
CREATE TABLE orders_hashed AS
SELECT order_id, customer_id, cost_of_order, day_of_week,
       SHA2(CAST(order_id AS CHAR),256) AS order_hash
FROM orders;
CREATE INDEX idx_orders_hash ON orders_hashed(order_hash);
EXPLAIN SELECT * FROM orders_hashed
WHERE order_hash=SHA2('1477147',256);

-- 5. Full scan vs indexed lookup.
EXPLAIN SELECT * FROM orders WHERE customer_id=337525;
EXPLAIN SELECT * FROM orders IGNORE INDEX(idx_orders_customer) WHERE customer_id=337525;
EXPLAIN SELECT * FROM orders WHERE cost_of_order>34;
EXPLAIN SELECT * FROM orders WHERE day_of_week='Weekend';

-- 6. Heuristic optimization: selection/projection before join.
EXPLAIN
SELECT r.restaurant_name,o.cost_of_order
FROM orders o JOIN restaurants r ON r.restaurant_id=o.restaurant_id
WHERE o.day_of_week='Weekday' AND o.cost_of_order>30;

EXPLAIN
SELECT r.restaurant_name,f.cost_of_order
FROM (SELECT restaurant_id,cost_of_order FROM orders
      WHERE day_of_week='Weekday' AND cost_of_order>30) f
JOIN restaurants r ON r.restaurant_id=f.restaurant_id;

-- MySQL's optimizer chooses join strategies automatically.
EXPLAIN SELECT r.restaurant_name,o.cost_of_order
FROM orders o JOIN restaurants r ON r.restaurant_id=o.restaurant_id;

-- Cleanup optional demo table.
-- DROP TABLE orders_hashed;
