-- 1. Procedimiento que incrementa o decrementa el precio
-- de un producto. 
-- Los parámetros de entrada son:
-- -- Identificador del producto
-- -- Porcentaje de incremento/decremento
-- Un parámetro de salida devuelve el nuevo precio si se
-- ha podido calcular, o NULL en caso contrario.

DELIMITER //
DROP PROCEDURE IF EXISTS increase_price//
CREATE PROCEDURE increase_price(
	IN par_product_id INT(5),
	IN perc FLOAT,
	OUT par_price DECIMAL(6,2)
)
BEGIN
	SET par_price=(
		SELECT price+price*perc/100
		FROM product
		WHERE product_id=par_product_id
	);
	IF par_price IS NOT NULL THEN
		UPDATE product
		SET price=par_price
		WHERE product_id=par_product_id;
	END IF;
END//
DELIMITER ;

-- 2. Incrementa el precio de un producto un 10%

CALL increase_price(1,10,@x);
SELECT @x;

-- 3. Decrementa el precio de un producto un 1.5%

CALL increase_price(11,-1.5,@x);
SELECT @x;

-- 4. Lo mismo con un producto que no existe

CALL increase_price(12,-1.5,@x);
SELECT @x;

-- 5. Procedimiento que inserta una nueva factura.
-- Los parámetros de entrada son:
-- -- Fecha
-- -- Identificador del cliente
-- -- Identificador del vehículo
-- Un parámetro de salida devuelve el identificador
-- de la factura si se ha podido insertar, o NULL en caso 
-- contrario (cliente o vehículo inexistentes).

DELIMITER //
DROP PROCEDURE IF EXISTS insert_invoice//
CREATE PROCEDURE insert_invoice(
	IN par_date DATE,
	IN par_client_id INT(5),
	IN par_vehicle_id VARCHAR(8),
	OUT par_status INT(8)
)
BEGIN
	SET par_status=next_invoice_id(YEAR(par_date));
	INSERT INTO invoice(invoice_id,invoice_date,client_id,vehicle_id)
	VALUES(par_status,par_date,par_client_id,par_vehicle_id);
	IF ROW_COUNT()=0 THEN
		SET par_status=NULL;
	END IF;
END//
DELIMITER ;

-- 6. Inserta una factura con fecha 13-11-2019 del cliente 4
-- y el vehículo 9090GRR

CALL insert_invoice('2019-11-13',4,'9090GRR',@x);
SELECT @x;

-- 7. Inserta una factura con fecha 23-12-2020 del cliente 12
-- y el vehículo 9090GRR

CALL insert_invoice('2020-12-23',12,'9090GRR',@x);
SELECT @x;

-- 8. Procedimiento que inserta un ítem de productos.
-- Recibe como parámetros el identificador de la factura,
-- el identificador del producto y las unidades.
-- Mediante un parámetro de salida se devuelve el resultado
-- de la operación: 
-- -- 1 OK
-- -- 2 Error factura no existe
-- -- 3 Error producto no existe
-- -- 4 Error stock insuficiente

DELIMITER //
DROP PROCEDURE IF EXISTS insert_item_product//
CREATE PROCEDURE insert_item_product(
	par_invoice_id INT(8),
	par_product_id INT(5),
	par_units INT(5),
	OUT par_status INT(1)
)
BEGIN
	DECLARE x DECIMAL(6,2); 
	IF par_invoice_id NOT IN (SELECT invoice_id FROM invoice) THEN
		SET par_status=2;
	ELSE
		IF par_product_id NOT IN (SELECT product_id FROM product) THEN
			SET par_status=3;
		ELSE 
			IF par_units > (SELECT stock FROM product WHERE product_id=par_product_id) THEN
				SET par_status=4;
			ELSE
				SET x=(SELECT price FROM product WHERE product_id=par_product_id);
				INSERT INTO item_product(invoice_id,product_id,units,price)
				VALUES (par_invoice_id,par_product_id,par_units,x);
				SET par_status=1;
			END IF;
		END IF;
	END IF;
END//
DELIMITER ;

-- 9. Obtener el resultado: 1 OK

CALL insert_item_product(20190001,2,7,@x);
SELECT @x;

-- 10. Obtener el resultado: 2 Error factura no existe

CALL insert_item_product(20190031,2,7,@x);
SELECT @x;

-- 11. Obtener el resultado: 3 Error producto no existe

CALL insert_item_product(20190001,22,7,@x);
SELECT @x; 

-- 12. Obtener el resultado: 4 Error stock insuficiente

CALL insert_item_product(20190001,3,11,@x);
SELECT @x; 

-- 13. Modifica el procedimiento anterior para que en el caso 1 OK
-- se actualice el stock en la tabla de productos, restando las
-- unidades vendidas

DELIMITER //
DROP PROCEDURE IF EXISTS insert_item_product//
CREATE PROCEDURE insert_item_product(
	par_invoice_id INT(8),
	par_product_id INT(5),
	par_units INT(5),
	OUT par_status INT(1)
)
BEGIN
	DECLARE x DECIMAL(6,2); 
	IF par_invoice_id NOT IN (SELECT invoice_id FROM invoice) THEN
		SET par_status=2;
	ELSEIF par_product_id NOT IN (SELECT product_id FROM product) THEN
		SET par_status=3;
	ELSEIF par_units > (SELECT stock FROM product WHERE product_id=par_product_id) THEN
		SET par_status=4;
	ELSE
		SET x=(SELECT price FROM product WHERE product_id=par_product_id);
		INSERT INTO item_product(invoice_id,product_id,units,price)
		VALUES (par_invoice_id,par_product_id,par_units,x);
		UPDATE product
		SET stock=stock-par_units
		WHERE product_id=par_product_id;
		SET par_status=1;
	END IF;
END//
DELIMITER ;

-- 14. Prueba con un producto que existe y que tiene suficiente stock,
-- se actualiza restando las unidades vendidas

CALL insert_item_product(20200001,7,5,@x);
SELECT @x;

-- 15. Procedimiento que inserta aleatoriamente facturas, items
-- de mano de obra e items de productos. Los parámetros son:
-- -- Fecha de inicio
-- -- Número de facturas
-- -- Máximo de facturas por día (el mínimo el cero)
-- -- Máximo de ítems de productos por factura (el mínimo el cero)
-- -- Máximo de ítems de trabajos por factura (el mínimo el cero)

