-- Un procedimiento almacenado es parecido a una función almacenada
-- Tiene parámetros de entrada igual que la función
-- Pero además puede tener parámetros de salida
-- No devuelve un valor como las funciones
-- Realizan operaciones INSERT, DELETE o UPDATE
-- Para ejecutar el procedimiento se usa la orden CALL

-- 1. Procedimiento que cambia los precios vigentes en nuestro parking a partir de mañana
-- Recibe como parámetros el nuevo precio por día y por minuto
-- Tiene que ejecutar un UPDATE en la fila que tenga until_date a nulo
-- Tiene que ejecutar un INSERT con el nuevo precio
-- Tenemos que generar el nuevo identificador porque no es AUTO_INCREMENT

DELIMITER //
DROP PROCEDURE IF EXISTS new_price//
CREATE PROCEDURE new_price(par_pd DECIMAL(5,3), par_pm DECIMAL(5,3))
BEGIN
	DECLARE id INT(5);
	SET id=(SELECT MAX(price_id+1) FROM price);
	UPDATE price
	SET until_date=CURRENT_DATE
	WHERE until_date IS NULL;
	INSERT INTO price (price_id,from_date,price_day,price_minute)
	VALUES (id,CURRENT_DATE+1,par_pd,par_pm);
END//
DELIMITER ;

-- 2. Probamos el procedimiento con los nuevos precios 12.470 y 0.015

CALL new_price(12.470,0.015);

-- 3. Procedimiento que se ejecutará a la entrada de un coche del parking
-- Recibe como parámetros el identificador del vehículo y el identificador de la plaza
-- Se supone que los datos del vehículo ya están en la BD y la plaza está libre

DELIMITER //
DROP PROCEDURE IF EXISTS input_vehicle//
CREATE PROCEDURE input_vehicle(par_vehicle_id VARCHAR(8),par_place_id INT(11))
BEGIN
	DECLARE id INT(11);
	SET id=(SELECT MAX(stay_id+1) FROM stay);
	INSERT INTO stay (stay_id,in_date,vehicle_id,place_id)
	VALUES (id,CURRENT_TIMESTAMP,par_vehicle_id,par_place_id);
END//
DELIMITER ;

-- 4. Prueba el resultado con algún vehículo en una plaza libre

CALL input_vehicle('5432-GGS',5);

-- 5. El procedimiento anterior podría no funcionar en algunos casos, así
-- que añadimos un parámetro de salida que tomará los siguientes valores:
-- -- 1 OK
-- -- 2 Error vehículo no existe
-- -- 3 Error el vehículo ya está aparcado
-- -- 4 Error la plaza no existe
-- -- 5 Error la plaza está ocupada

-- 6. Realizamos una prueba para cada caso

-- 7. Procedimiento que se ejecutará a la salida de un coche del parking
-- Recibe como parámetro el identificador del vehículo
-- Se supone que el vehículo estaba estacionado dentro del parking

-- 8. Prueba el resultado con algún vehículo que esté estacionado

-- 9. El procedimiento anterior podría no funcionar en algunos casos, así
-- que añadimos un parámetro de salida que tomará los siguientes valores:
-- -- 1 OK
-- -- 2 Error vehículo no existe
-- -- 3 Error el vehículo no está aparcado

-- 10. Realizamos una prueba para cada caso
