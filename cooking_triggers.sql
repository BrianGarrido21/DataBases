-- Los valores de los campos de la fila afectada por la operación DML
-- están disponibles con los prefijos old y new:
-- -- INSERT sólo new
-- -- DELETE sólo old
-- -- UPDATE old y new

-- 1. Disparador para auditar actualizaciones en la tabla ingredients. 
-- Se inserta en la tabla audit la fecha-tiempo de la operación,el identificador del ítem
-- y el porcentaje de incremento (positivo o negativo) del precio del ingrediente. 
-- Pero si el porcentaje es cero (el precio no cambia), entonces no se inserta nada.

CREATE TABLE audit_price (
    audit_id INT(6) PRIMARY KEY AUTO_INCREMENT,
    audit_datetime DATETIME,
    ingredient_id INT(6),
    incre DECIMAL(6,2)
);

DELIMITER //
DROP TRIGGER IF EXISTS audit_ingred//
CREATE TRIGGER audit_ingred
BEFORE UPDATE ON ingredient
FOR EACH ROW
BEGIN
	DECLARE x DECIMAL(6,2);
	SET x=(new.price-old.price)/old.price*100;
	IF x != 0 THEN
		INSERT INTO audit_price (audit_datetime,ingredient_id,incre)
		VALUES (CURRENT_TIMESTAMP,new.ingredient_id,x);
	END IF;
END//
DELIMITER ;

-- 2. Disparador que impide que se puedan borrar filas de la tabla
-- command con más de 30 días de antigüedad

DELIMITER //
DROP TRIGGER IF EXISTS no_delete_menu//
CREATE TRIGGER no_delete_menu
BEFORE DELETE ON command
FOR EACH ROW
BEGIN
	IF TIMESTAMPDIFF(DAY,old.command_date,CURRENT_DATE)>30 THEN
		SIGNAL SQLSTATE '20001' 
		SET message_text='Error more than 30 days old';
	END IF;
END//
DELIMITER ;

-- 3. Disparador que impide que se puedan insertar filas de la tabla
-- command si existen más de cinco comandas con igual fecha que la
-- fecha del que se está insertando

DELIMITER //
DROP TRIGGER IF EXISTS no_insert_command//
CREATE TRIGGER no_insert_command
BEFORE INSERT ON command
FOR EACH ROW
BEGIN
	IF ( SELECT COUNT(*)
		 FROM command 
		 WHERE command_date=new.command_date) > 5 THEN
		SIGNAL SQLSTATE '20002' 
		SET message_text='Error more than 5 commands this day';
	END IF;
END//
DELIMITER ;

-- 4. Modificar el disparador de la auditoría de incrementos de 
-- precios de ingredientes para que se guarde el nombre del usuario
-- que realiza la actualización.

DROP TABLE IF EXISTS audit_price;
CREATE TABLE audit_price (
    audit_id INT(6) PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(30),
    audit_datetime DATETIME,
    ingredient_id INT(6),
    incre DECIMAL(6,2)
);

-- La función USER() devuelve el usuario conectado en la sesión actualizaciones
-- de la forma usuario@host

DELIMITER //
DROP TRIGGER IF EXISTS audit_ingred//
CREATE TRIGGER audit_ingred
BEFORE UPDATE ON ingredient
FOR EACH ROW
BEGIN
	DECLARE x DECIMAL(6,2);
	SET x=(new.price-old.price)/old.price*100;
	IF x != 0 THEN
		INSERT INTO audit_price (username,audit_datetime,ingredient_id,incre)
		VALUES (USER(),CURRENT_TIMESTAMP,new.ingredient_id,x);
	END IF;
END//
DELIMITER ;

-- 5. Disparador que impide que se inserte una comanda si no hay
-- stock suficiente de algún ingrediente.

DELIMITER //
DROP TRIGGER IF EXISTS check_insert_command//
CREATE TRIGGER check_insert_command
BEFORE INSERT ON command
FOR EACH ROW
BEGIN
	IF NOT enough_stock(new.recipe_id,new.rations) THEN
		SIGNAL SQLSTATE '20003' 
		SET message_text='Error not enough stock';
	END IF;
END//
DELIMITER ;

-- 6. Modificar el disparador anterior para que además se actualice
-- el stock de los ingredientes que se han gastado



