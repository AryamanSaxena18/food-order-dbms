-- =====================================================================
-- 06_queries.sql
-- Topics: SELECT, restricting/sorting, single-row & conversion functions,
--         conditional expressions, group functions, joins, subqueries,
--         set operators, NULL handling, relational division
-- =====================================================================

-- ===== A. Basic SELECT, restricting and sorting =====
SELECT * FROM orders LIMIT 5;
SELECT DISTINCT day_of_week FROM orders;
SELECT order_id, cost_of_order FROM orders
WHERE cost_of_order BETWEEN 20 AND 30 AND day_of_week = 'Weekend'
ORDER BY cost_of_order DESC, order_id;
SELECT restaurant_name FROM restaurants WHERE restaurant_name LIKE 'Blue%' OR restaurant_name LIKE '%Sushi%';
SELECT cuisine_name FROM cuisines WHERE cuisine_name IN ('Thai','Korean','French');
SELECT order_id FROM orders WHERE rating IS NULL LIMIT 5;          -- NULL test

-- ===== B. Single-row functions =====
SELECT UPPER(restaurant_name) up, LOWER(restaurant_name) low, CONCAT(UCASE(LEFT(restaurant_name,1)),LCASE(SUBSTRING(restaurant_name,2))) init,
       LENGTH(restaurant_name) len, SUBSTR(restaurant_name, 1, 5) first5,
       INSTR(restaurant_name, ' ') first_space
FROM restaurants LIMIT 5;
SELECT order_id, cost_of_order, ROUND(cost_of_order) r, TRUNCATE(cost_of_order,0) t,
       CEIL(cost_of_order) c, FLOOR(cost_of_order) f, MOD(order_id, 7) m
FROM orders LIMIT 5;
SELECT LPAD(CAST(customer_id AS CHAR), 8, '0') padded_id, REPLACE(restaurant_name, ' ', '_') underscored
FROM (SELECT DISTINCT customer_id, restaurant_name FROM orders o JOIN restaurants r USING (restaurant_id))
LIMIT 5;

-- ===== C. Conversion functions & conditional expressions =====
SELECT order_id, CONCAT('$', FORMAT(cost_of_order,2)) AS price_text,
       CAST('12.50' AS DECIMAL(6,2)) AS num_from_text, DATE_FORMAT(CURRENT_DATE, '%d-%b-%Y') AS today
FROM orders LIMIT 3;
SELECT order_id, rating,
       COALESCE(rating, 0)                           AS rating_or_zero,
       IF(rating IS NOT NULL, 'Rated', 'Not rated')       AS rated_status,
       COALESCE(rating, NULL, -1)               AS coalesced,
       NULLIF(day_of_week, 'Weekday')           AS null_if_weekday,
       CASE day_of_week WHEN 'Weekend' THEN 'WE' WHEN 'Weekday' THEN 'WD' ELSE '?' END AS day_code,
       CASE WHEN cost_of_order > 25 THEN 'High' WHEN cost_of_order > 12 THEN 'Medium' ELSE 'Low' END AS price_band
FROM orders LIMIT 10;

-- ===== D. Group functions, GROUP BY, HAVING =====
SELECT COUNT(*) total_orders, COUNT(rating) rated_orders, COUNT(*) - COUNT(rating) unrated,
       ROUND(AVG(rating),2) avg_rating, SUM(cost_of_order) revenue,
       MIN(cost_of_order) min_cost, MAX(cost_of_order) max_cost FROM orders;        -- AVG/COUNT(col) ignore NULLs
SELECT day_of_week, COUNT(*) orders, ROUND(AVG(cost_of_order),2) avg_cost
FROM orders GROUP BY day_of_week;
SELECT cuisine_name, COUNT(*) orders, ROUND(AVG(food_prep_time),1) avg_prep, ROUND(AVG(delivery_time),1) avg_delivery
FROM orders JOIN cuisines USING (cuisine_id)
GROUP BY cuisine_name HAVING COUNT(*) > 50 ORDER BY orders DESC;
SELECT restaurant_name, COUNT(*) orders
FROM orders JOIN restaurants USING (restaurant_id)
GROUP BY restaurant_name HAVING COUNT(*) >= 50 ORDER BY orders DESC;
SELECT customer_id, COUNT(*) orders FROM orders GROUP BY customer_id HAVING COUNT(*) >= 8 ORDER BY orders DESC, customer_id;

-- ===== E. Joins =====
-- Equi-join / inner join (ANSI)
SELECT o.order_id, r.restaurant_name, c.cuisine_name, o.cost_of_order
FROM orders o
JOIN restaurants r ON r.restaurant_id = o.restaurant_id
JOIN cuisines    c ON c.cuisine_id    = o.cuisine_id
LIMIT 10;
-- Oracle-style (WHERE) join
SELECT o.order_id, r.restaurant_name FROM orders o, restaurants r
WHERE o.restaurant_id = r.restaurant_id LIMIT 5;
-- Outer joins: restaurants with no orders appear with 0
SELECT r.restaurant_name, COUNT(o.order_id) orders
FROM restaurants r LEFT OUTER JOIN orders o ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name ORDER BY orders, r.restaurant_name;
-- RIGHT OUTER is supported; MySQL has no FULL OUTER JOIN, so the original full-join demo uses a LEFT JOIN.
SELECT c.cuisine_name, COUNT(o.order_id) orders
FROM orders o RIGHT OUTER JOIN cuisines c ON c.cuisine_id = o.cuisine_id GROUP BY c.cuisine_name;
SELECT COALESCE(r.restaurant_name,'(none)') r, COALESCE(CAST(o.order_id AS CHAR),'(none)') o
FROM restaurants r LEFT JOIN orders o ON o.restaurant_id = r.restaurant_id LIMIT 5;
-- Self join: pairs of different customers who ordered from the same restaurant at same cost
SELECT a.customer_id c1, b.customer_id c2, a.restaurant_id, a.cost_of_order
FROM orders a JOIN orders b ON a.restaurant_id = b.restaurant_id AND a.cost_of_order = b.cost_of_order
                           AND a.customer_id < b.customer_id
LIMIT 10;
-- Natural join, USING, cross join, non-equi join
SELECT * FROM restaurant_cuisine NATURAL JOIN cuisines LIMIT 5;
SELECT COUNT(*) FROM cuisines CROSS JOIN (SELECT DISTINCT day_of_week FROM orders);
SELECT o.order_id, o.cost_of_order, b.band
FROM orders o JOIN (SELECT 'Low' band, 0 lo, 12 hi  UNION ALL
                    SELECT 'Mid', 12.01, 25  UNION ALL
                    SELECT 'High', 25.01, 999 ) b
  ON o.cost_of_order BETWEEN b.lo AND b.hi
LIMIT 5;

-- ===== F. Subqueries =====
-- Single-row subquery: orders costing more than the average
SELECT order_id, cost_of_order FROM orders WHERE cost_of_order > (SELECT AVG(cost_of_order) FROM orders) LIMIT 10;
-- Multi-row: IN / ANY / ALL
SELECT restaurant_name FROM restaurants
WHERE restaurant_id IN (SELECT restaurant_id FROM orders WHERE rating = 5 GROUP BY restaurant_id HAVING COUNT(*) >= 10);
SELECT order_id, cost_of_order FROM orders
WHERE cost_of_order > ALL (SELECT cost_of_order FROM orders WHERE day_of_week = 'Weekday' AND cost_of_order < 30) LIMIT 5;
-- Correlated subquery: orders costing more than that restaurant's own average
SELECT o.order_id, o.restaurant_id, o.cost_of_order
FROM orders o
WHERE o.cost_of_order > (SELECT AVG(i.cost_of_order) FROM orders i WHERE i.restaurant_id = o.restaurant_id)
  LIMIT 10;
-- EXISTS / NOT EXISTS: customers who never gave a rating
SELECT c.customer_id FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id AND o.rating IS NOT NULL)
  LIMIT 10;
-- Inline view (subquery in FROM): top 5 restaurants by revenue
SELECT * FROM (SELECT restaurant_name, revenue FROM v_restaurant_stats ORDER BY revenue DESC) LIMIT 5;
-- Scalar subquery in SELECT
SELECT c.cuisine_name, (SELECT COUNT(*) FROM orders o WHERE o.cuisine_id = c.cuisine_id) AS orders FROM cuisines c;
-- Nested subquery (2 levels): restaurants serving the most-ordered cuisine
SELECT r.restaurant_name FROM restaurants r WHERE r.restaurant_id IN (SELECT rc.restaurant_id FROM restaurant_cuisine rc WHERE rc.cuisine_id=(SELECT cuisine_id FROM orders GROUP BY cuisine_id ORDER BY COUNT(*) DESC LIMIT 1));

-- ===== G. Set operators =====
SELECT customer_id FROM orders WHERE day_of_week = 'Weekday'
UNION
SELECT customer_id FROM orders WHERE day_of_week = 'Weekend';                  -- distinct union
SELECT restaurant_id FROM orders WHERE cuisine_id = (SELECT cuisine_id FROM cuisines WHERE cuisine_name='Italian')
UNION ALL
SELECT restaurant_id FROM orders WHERE cuisine_id = (SELECT cuisine_id FROM cuisines WHERE cuisine_name='American');
SELECT customer_id FROM orders WHERE day_of_week = 'Weekday'
INTERSECT
SELECT customer_id FROM orders WHERE day_of_week = 'Weekend';                  -- ordered on both
SELECT customer_id FROM orders WHERE day_of_week = 'Weekday'
EXCEPT
SELECT customer_id FROM orders WHERE day_of_week = 'Weekend';                  -- weekday-only customers

-- ===== H. Relational division: customers who ordered ALL of American, Japanese and Italian =====
SELECT c.customer_id FROM customers c
WHERE NOT EXISTS (
  SELECT cu.cuisine_id FROM cuisines cu WHERE cu.cuisine_name IN ('American','Japanese','Italian')
  AND NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id AND o.cuisine_id = cu.cuisine_id));
-- same using GROUP BY / counting
SELECT o.customer_id FROM orders o JOIN cuisines cu ON cu.cuisine_id = o.cuisine_id
WHERE cu.cuisine_name IN ('American','Japanese','Italian')
GROUP BY o.customer_id HAVING COUNT(DISTINCT cu.cuisine_id) = 3;

-- ===== I. Business questions =====
-- Slowest restaurants (min 10 orders)
SELECT restaurant_name, total_orders, avg_total_time FROM v_restaurant_stats
WHERE total_orders >= 10 ORDER BY avg_total_time DESC LIMIT 5;
-- Weekend vs weekday satisfaction
SELECT day_of_week, ROUND(AVG(rating),2) avg_rating, ROUND(100*COUNT(rating)/COUNT(*),1) pct_rated
FROM orders GROUP BY day_of_week;
-- Tier distribution
SELECT tier, COUNT(*) customers, ROUND(SUM(total_spent),2) revenue FROM v_customer_summary GROUP BY tier ORDER BY revenue DESC;
