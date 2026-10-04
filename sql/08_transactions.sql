-- 08_transactions.sql | MySQL 8.0+
-- Transaction, ACID, isolation, locking and recovery demonstrations.

-- 1. Atomicity: both updates are undone together.
START TRANSACTION;
UPDATE orders SET delivery_time=delivery_time+2 WHERE order_id=1477147;
UPDATE orders SET delivery_time=delivery_time+2 WHERE order_id=99999999;
ROLLBACK;
SELECT delivery_time FROM orders WHERE order_id=1477147;

-- 2. Consistency: this should fail because of CHECK (cost_of_order > 0).
-- UPDATE orders SET cost_of_order=-1 WHERE order_id=1477147;

-- 3. Isolation levels supported by MySQL/InnoDB.
SELECT @@transaction_isolation;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT * FROM orders WHERE order_id=1477147 FOR UPDATE;
ROLLBACK;

-- 4. Two-session locking demo.
-- Session 1:
-- START TRANSACTION;
-- UPDATE orders SET delivery_time=delivery_time+1 WHERE order_id=1477147;
-- Keep the transaction open.
-- Session 2:
-- START TRANSACTION;
-- UPDATE orders SET delivery_time=delivery_time+1 WHERE order_id=1477147;
-- Session 2 waits for Session 1's lock (or times out).
-- Then COMMIT in Session 1.

-- 5. Deadlock demo (use two sessions, different row order).
-- Session 1: START TRANSACTION; UPDATE orders SET delivery_time=delivery_time+1 WHERE order_id=1477147;
-- Session 2: START TRANSACTION; UPDATE orders SET delivery_time=delivery_time+1 WHERE order_id=1477148;
-- Session 1: UPDATE orders SET delivery_time=delivery_time+1 WHERE order_id=1477148;
-- Session 2: UPDATE orders SET delivery_time=delivery_time+1 WHERE order_id=1477147;
-- InnoDB detects the deadlock and rolls one transaction back.

-- 6. Lock inspection (MySQL 8.0+).
SELECT * FROM performance_schema.data_locks LIMIT 20;
SELECT * FROM performance_schema.data_lock_waits LIMIT 20;

-- 7. Recovery / durability notes: InnoDB uses redo logs and undo information.
-- Test transaction durability manually by COMMIT, then reconnect and verify the row.
