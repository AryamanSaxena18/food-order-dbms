-- 04_plsql.sql | MySQL 8.0+
-- MySQL equivalent of the Oracle PL/SQL section: variables, control flow,
-- stored functions/procedures, cursors and exceptions/signals.

DELIMITER $$

DROP FUNCTION IF EXISTS fn_customer_total$$
CREATE FUNCTION fn_customer_total(p_customer_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(12,2);
  SELECT COALESCE(SUM(cost_of_order),0) INTO v_total FROM orders WHERE customer_id=p_customer_id;
  RETURN v_total;
END$$

DROP FUNCTION IF EXISTS fn_customer_tier$$
CREATE FUNCTION fn_customer_tier(p_customer_id INT)
RETURNS VARCHAR(10)
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(12,2);
  SET v_total=fn_customer_total(p_customer_id);
  IF v_total>=60 THEN RETURN 'GOLD';
  ELSEIF v_total>=30 THEN RETURN 'SILVER';
  ELSE RETURN 'BRONZE'; END IF;
END$$

DROP FUNCTION IF EXISTS fn_delivery_speed$$
CREATE FUNCTION fn_delivery_speed(p_prep INT,p_delivery INT)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
  DECLARE v_total INT DEFAULT p_prep+p_delivery;
  IF v_total<=45 THEN RETURN 'FAST';
  ELSEIF v_total<=55 THEN RETURN 'NORMAL';
  ELSE RETURN 'SLOW'; END IF;
END$$

DROP PROCEDURE IF EXISTS sp_place_order$$
CREATE PROCEDURE sp_place_order(
 IN p_customer_id INT, IN p_restaurant_name VARCHAR(100), IN p_cuisine_name VARCHAR(30),
 IN p_cost DECIMAL(6,2), IN p_day_of_week VARCHAR(7), IN p_prep_time INT,
 IN p_delivery_time INT, OUT p_order_id INT)
BEGIN
  DECLARE v_rest_id INT; DECLARE v_cuis_id INT; DECLARE v_cnt INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK TO before_order; RESIGNAL; END;
  SAVEPOINT before_order;
  IF p_cost IS NULL OR p_cost<=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cost must be a positive number'; END IF;
  SELECT restaurant_id INTO v_rest_id FROM restaurants WHERE restaurant_name=p_restaurant_name LIMIT 1;
  SELECT cuisine_id INTO v_cuis_id FROM cuisines WHERE cuisine_name=p_cuisine_name LIMIT 1;
  IF v_rest_id IS NULL OR v_cuis_id IS NULL THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unknown restaurant or cuisine'; END IF;
  SELECT COUNT(*) INTO v_cnt FROM restaurant_cuisine WHERE restaurant_id=v_rest_id AND cuisine_id=v_cuis_id;
  IF v_cnt=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Restaurant does not serve this cuisine'; END IF;
  INSERT IGNORE INTO customers(customer_id) VALUES(p_customer_id);
  INSERT INTO orders(customer_id,restaurant_id,cuisine_id,cost_of_order,day_of_week,rating,food_prep_time,delivery_time)
  VALUES(p_customer_id,v_rest_id,v_cuis_id,p_cost,p_day_of_week,NULL,p_prep_time,p_delivery_time);
  SET p_order_id=LAST_INSERT_ID();
END$$

DROP PROCEDURE IF EXISTS sp_rate_order$$
CREATE PROCEDURE sp_rate_order(IN p_order_id INT, IN p_rating INT)
BEGIN
  UPDATE orders SET rating=p_rating WHERE order_id=p_order_id;
  IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Order not found'; END IF;
END$$

DROP PROCEDURE IF EXISTS sp_set_restaurant_status$$
CREATE PROCEDURE sp_set_restaurant_status(IN p_name VARCHAR(100), IN p_active CHAR(1))
BEGIN
  UPDATE restaurants SET is_active=p_active WHERE restaurant_name=p_name;
  IF ROW_COUNT()=0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Restaurant not found'; END IF;
END$$

DROP PROCEDURE IF EXISTS sp_restaurant_report$$
CREATE PROCEDURE sp_restaurant_report(IN p_cuisine VARCHAR(30))
BEGIN
  SELECT r.restaurant_name, COUNT(*) AS orders, ROUND(AVG(o.cost_of_order),2) AS avg_cost
  FROM orders o JOIN restaurants r ON r.restaurant_id=o.restaurant_id
  JOIN cuisines c ON c.cuisine_id=o.cuisine_id
  WHERE c.cuisine_name=p_cuisine
  GROUP BY r.restaurant_name ORDER BY orders DESC LIMIT 5;
END$$

DROP PROCEDURE IF EXISTS sp_top_customers$$
CREATE PROCEDURE sp_top_customers(IN p_n INT)
BEGIN
  SELECT customer_id,order_count,total_spent,tier FROM v_customer_summary
  ORDER BY total_spent DESC LIMIT p_n;
END$$

DROP PROCEDURE IF EXISTS sp_cuisine_report$$
CREATE PROCEDURE sp_cuisine_report()
BEGIN
  SELECT c.cuisine_name,COUNT(*) AS order_count,ROUND(AVG(o.cost_of_order),2) AS avg_cost,ROUND(AVG(o.rating),2) AS avg_rating
  FROM orders o JOIN cuisines c ON c.cuisine_id=o.cuisine_id
  GROUP BY c.cuisine_name ORDER BY order_count DESC;
END$$

DELIMITER ;

SELECT customer_id,fn_customer_total(customer_id) total,fn_customer_tier(customer_id) tier FROM customers LIMIT 5;
SELECT order_id,fn_delivery_speed(food_prep_time,delivery_time) speed FROM orders LIMIT 5;
CALL sp_restaurant_report('Italian');
CALL sp_top_customers(5);
CALL sp_cuisine_report();
