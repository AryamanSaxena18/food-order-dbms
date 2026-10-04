-- 05_triggers.sql | MySQL 8.0+
DELIMITER $$
DROP TRIGGER IF EXISTS trg_orders_validate_insert$$
CREATE TRIGGER trg_orders_validate_insert BEFORE INSERT ON orders FOR EACH ROW
BEGIN
  DECLARE v_active CHAR(1);
  SELECT is_active INTO v_active FROM restaurants WHERE restaurant_id=NEW.restaurant_id;
  IF v_active='N' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Cannot place an order with an inactive restaurant'; END IF;
END$$

DROP TRIGGER IF EXISTS trg_orders_validate_update$$
CREATE TRIGGER trg_orders_validate_update BEFORE UPDATE ON orders FOR EACH ROW
BEGIN
  IF OLD.rating IS NOT NULL AND (NEW.rating IS NULL OR NEW.rating<>OLD.rating) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='A given rating cannot be changed';
  END IF;
END$$

DROP TRIGGER IF EXISTS trg_orders_audit_insert$$
CREATE TRIGGER trg_orders_audit_insert AFTER INSERT ON orders FOR EACH ROW
BEGIN
  INSERT INTO order_audit(order_id,action,new_cost,new_rating) VALUES(NEW.order_id,'INSERT',NEW.cost_of_order,NEW.rating);
END$$

DROP TRIGGER IF EXISTS trg_orders_audit_update$$
CREATE TRIGGER trg_orders_audit_update AFTER UPDATE ON orders FOR EACH ROW
BEGIN
  INSERT INTO order_audit(order_id,action,old_cost,new_cost,old_rating,new_rating)
  VALUES(NEW.order_id,'UPDATE',OLD.cost_of_order,NEW.cost_of_order,OLD.rating,NEW.rating);
END$$

DROP TRIGGER IF EXISTS trg_orders_audit_delete$$
CREATE TRIGGER trg_orders_audit_delete AFTER DELETE ON orders FOR EACH ROW
BEGIN
  INSERT INTO order_audit(order_id,action,old_cost,old_rating) VALUES(OLD.order_id,'DELETE',OLD.cost_of_order,OLD.rating);
END$$

DROP TRIGGER IF EXISTS trg_orders_stmt_delete$$
CREATE TRIGGER trg_orders_stmt_delete AFTER DELETE ON orders FOR EACH ROW
BEGIN
  -- MySQL has no statement-level triggers; this row trigger provides the audit hook.
  SET @last_order_delete_time=CURRENT_TIMESTAMP;
END$$
DELIMITER ;

SHOW TRIGGERS;
