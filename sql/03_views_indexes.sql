-- 03_views_indexes.sql | MySQL 8.0+
CREATE OR REPLACE VIEW v_order_details AS
SELECT o.order_id, o.customer_id, r.restaurant_name, c.cuisine_name,
       o.cost_of_order, o.day_of_week, o.rating, o.food_prep_time, o.delivery_time,
       o.food_prep_time + o.delivery_time AS total_time
FROM orders o JOIN restaurants r ON r.restaurant_id=o.restaurant_id
JOIN cuisines c ON c.cuisine_id=o.cuisine_id;

CREATE OR REPLACE VIEW v_restaurant_stats AS
SELECT r.restaurant_id, r.restaurant_name, r.is_active,
       COUNT(o.order_id) AS total_orders,
       ROUND(COALESCE(SUM(o.cost_of_order),0),2) AS revenue,
       ROUND(AVG(o.cost_of_order),2) AS avg_order_value,
       ROUND(AVG(o.rating),2) AS avg_rating,
       ROUND(AVG(o.food_prep_time + o.delivery_time),1) AS avg_total_time
FROM restaurants r LEFT JOIN orders o ON o.restaurant_id=r.restaurant_id
GROUP BY r.restaurant_id,r.restaurant_name,r.is_active;

CREATE OR REPLACE VIEW v_customer_summary AS
SELECT customer_id, COUNT(*) order_count, ROUND(SUM(cost_of_order),2) total_spent,
       CASE WHEN SUM(cost_of_order)>=60 THEN 'GOLD'
            WHEN SUM(cost_of_order)>=30 THEN 'SILVER' ELSE 'BRONZE' END tier
FROM orders GROUP BY customer_id;

CREATE OR REPLACE VIEW v_weekend_orders AS
SELECT order_id,customer_id,restaurant_id,cuisine_id,cost_of_order,day_of_week,rating,food_prep_time,delivery_time
FROM orders WHERE day_of_week='Weekend';

CREATE OR REPLACE VIEW v_cuisine_summary AS
SELECT c.cuisine_name, COUNT(*) orders, ROUND(AVG(o.cost_of_order),2) avg_cost
FROM orders o JOIN cuisines c ON c.cuisine_id=o.cuisine_id GROUP BY c.cuisine_name;

-- MySQL does not support Oracle SYNONYM objects; use views or table aliases instead.
CREATE OR REPLACE VIEW ord AS SELECT * FROM orders;
CREATE OR REPLACE VIEW rest AS SELECT * FROM restaurants;

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_rest_cuis ON orders(restaurant_id,cuisine_id);
CREATE INDEX idx_orders_day_rating ON orders(day_of_week,rating);
CREATE INDEX idx_orders_cost ON orders(cost_of_order);
CREATE INDEX idx_rest_name_upper ON restaurants((UPPER(restaurant_name)));

-- MySQL data dictionary equivalents:
SELECT table_name, table_rows FROM information_schema.tables
WHERE table_schema = DATABASE() ORDER BY table_name;
SELECT table_name,column_name,data_type,character_maximum_length,is_nullable
FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='orders' ORDER BY ordinal_position;
SELECT constraint_name,constraint_type,table_name
FROM information_schema.table_constraints WHERE table_schema=DATABASE()
AND table_name IN ('orders','restaurant_cuisine') ORDER BY table_name;
SELECT index_name,index_type,non_unique,table_name FROM information_schema.statistics
WHERE table_schema=DATABASE() ORDER BY table_name,index_name;
SELECT table_name AS view_name FROM information_schema.views WHERE table_schema=DATABASE();
