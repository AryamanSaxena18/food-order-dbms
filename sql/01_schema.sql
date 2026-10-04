-- 01_schema.sql | Food Order Database (MySQL 8.0+)
-- Converted from the original Oracle project.
-- Run this file first in MySQL Workbench.

DROP TRIGGER IF EXISTS trg_orders_bi_id;
DROP TRIGGER IF EXISTS trg_orders_validate_insert;
DROP TRIGGER IF EXISTS trg_orders_validate_update;
DROP TRIGGER IF EXISTS trg_orders_audit_insert;
DROP TRIGGER IF EXISTS trg_orders_audit_update;
DROP TRIGGER IF EXISTS trg_orders_audit_delete;
DROP TRIGGER IF EXISTS trg_orders_stmt_delete;

DROP VIEW IF EXISTS v_order_details, v_restaurant_stats, v_customer_summary, v_weekend_orders, v_cuisine_summary;
DROP TABLE IF EXISTS order_audit, orders, restaurant_cuisine, customers, restaurants, cuisines, stg_food_order;

CREATE TABLE stg_food_order (
  order_id INT,
  customer_id INT,
  restaurant_name VARCHAR(100),
  cuisine_type VARCHAR(30),
  cost_of_the_order DECIMAL(6,2),
  day_of_the_week VARCHAR(10),
  rating VARCHAR(10),
  food_preparation_time INT,
  delivery_time INT
);

CREATE TABLE cuisines (
  cuisine_id INT PRIMARY KEY AUTO_INCREMENT,
  cuisine_name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE restaurants (
  restaurant_id INT PRIMARY KEY AUTO_INCREMENT,
  restaurant_name VARCHAR(100) NOT NULL UNIQUE,
  is_active CHAR(1) NOT NULL DEFAULT 'Y',
  CONSTRAINT ck_rest_active CHECK (is_active IN ('Y','N'))
);

CREATE TABLE customers (
  customer_id INT PRIMARY KEY
);

CREATE TABLE restaurant_cuisine (
  restaurant_id INT NOT NULL,
  cuisine_id INT NOT NULL,
  PRIMARY KEY (restaurant_id, cuisine_id),
  CONSTRAINT fk_rc_rest FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
  CONSTRAINT fk_rc_cuis FOREIGN KEY (cuisine_id) REFERENCES cuisines(cuisine_id)
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT NOT NULL,
  restaurant_id INT NOT NULL,
  cuisine_id INT NOT NULL,
  cost_of_order DECIMAL(6,2) NOT NULL CHECK (cost_of_order > 0),
  day_of_week VARCHAR(7) NOT NULL CHECK (day_of_week IN ('Weekday','Weekend')),
  rating TINYINT NULL CHECK (rating BETWEEN 1 AND 5),
  food_prep_time INT CHECK (food_prep_time > 0),
  delivery_time INT CHECK (delivery_time > 0),
  CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_ord_rest_cuis FOREIGN KEY (restaurant_id, cuisine_id)
    REFERENCES restaurant_cuisine(restaurant_id, cuisine_id)
);

ALTER TABLE orders AUTO_INCREMENT = 2000000;

CREATE TABLE order_audit (
  audit_id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  action VARCHAR(6) NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  old_cost DECIMAL(6,2),
  new_cost DECIMAL(6,2),
  old_rating TINYINT,
  new_rating TINYINT,
  changed_by VARCHAR(100) DEFAULT (CURRENT_USER()),
  changed_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE order_audit AUTO_INCREMENT = 1;

-- MySQL uses AUTO_INCREMENT instead of Oracle sequences.
-- Constraint disable/enable and constraint renaming are not portable MySQL syntax;
-- the constraints above are created directly in their final form.
