-- 07_dml_tcl.sql | MySQL 8.0+
START TRANSACTION;
INSERT INTO customers(customer_id) VALUES(999001);
INSERT INTO orders(order_id,customer_id,restaurant_id,cuisine_id,cost_of_order,day_of_week,rating,food_prep_time,delivery_time)
SELECT 3000001,999001,rc.restaurant_id,rc.cuisine_id,18.50,'Weekday',NULL,22,24
FROM restaurant_cuisine rc JOIN restaurants r ON r.restaurant_id=rc.restaurant_id
WHERE r.restaurant_name='Shake Shack' LIMIT 1;
SAVEPOINT after_first_insert;

CALL sp_place_order(999001,'Shake Shack','American',12.75,'Weekend',20,25,@new_order_id);
SELECT @new_order_id AS new_order_id;
CALL sp_rate_order(@new_order_id,4);

UPDATE orders SET cost_of_order=cost_of_order*1.10 WHERE order_id=3000001;
UPDATE orders SET delivery_time=delivery_time+5
WHERE restaurant_id=(SELECT restaurant_id FROM restaurants WHERE restaurant_name='Shake Shack' LIMIT 1)
AND day_of_week='Weekend' AND rating IS NULL;

-- MySQL equivalent of MERGE is INSERT ... ON DUPLICATE KEY UPDATE.
INSERT INTO customers(customer_id) VALUES(999002) ON DUPLICATE KEY UPDATE customer_id=VALUES(customer_id);
DELETE FROM orders WHERE order_id=3000001;
DELETE FROM customers WHERE customer_id=999002;

SELECT audit_id,order_id,action,old_cost,new_cost,old_rating,new_rating FROM order_audit ORDER BY audit_id;
ROLLBACK TO SAVEPOINT after_first_insert;
SELECT COUNT(*) AS orders_for_test_customer FROM orders WHERE customer_id=999001;
ROLLBACK;
SELECT COUNT(*) AS orders_after_rollback FROM orders;
