-- 1. Función que devuelve verdadero si un vehículo está estacionado 
-- actualmente en el parking y falso en caso contrario. 
-- El parámetro de entrada es la matrícula del vehículo.
-- La función devuelve un valor booleano (verdadaro/falso, true/false, 1/0)

DELIMITER //
DROP FUNCTION IF EXISTS parked//
CREATE FUNCTION parked(par_vehicle_id VARCHAR(8))
RETURNS BOOLEAN
BEGIN
	RETURN par_vehicle_id IN (
		SELECT vehicle_id
		FROM stay
		WHERE out_date IS NULL
	);
END//
DELIMITER ;

-- 2. Probar la función con la matrícula '9919-CFH'

SELECT parked('9919-CFH');

-- 3. Probar la función con todas las matrículas de la tabla vehicle_id

SELECT *, parked(vehicle_id)
FROM vehicle;

-- 4. Función que devuelve el precio por día vigente en la fecha que se pasa como parámetro
-- Ojo: la función devuelve un valor decimal de 8 dígitos (3 después de la coma)

DELIMITER //
DROP FUNCTION IF EXISTS get_price_day//
CREATE FUNCTION get_price_day(par_date DATE)
RETURNS DECIMAL(5,3)
BEGIN
	RETURN (
		SELECT price_day
		FROM price
		WHERE par_date BETWEEN from_date AND IFNULL(until_date,CURRENT_DATE)
	);
END//
DELIMITER ;

-- 5. Función que devuelve el precio por minuto vigente en la fecha que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS get_price_minute//
CREATE FUNCTION get_price_minute(par_date DATE)
RETURNS DECIMAL(5,3)
BEGIN
	RETURN (
		SELECT price_minute
		FROM price
		WHERE par_date BETWEEN from_date AND IFNULL(until_date,CURRENT_DATE)
	);
END//
DELIMITER ;

-- 6. Para cada estancia, el precio por día y por minuto

SELECT *, get_price_day(in_date), get_price_minute(in_date)
FROM stay;

-- 7. Función que recibe como parámetros la fecha-hora de entrada y de salida
-- y devuelve el importe de la estancia

DELIMITER //
DROP FUNCTION IF EXISTS stay_imp//
CREATE FUNCTION stay_imp(dt1 DATETIME, dt2 DATETIME)
RETURNS DECIMAL(7,2)
BEGIN
	DECLARE pd, pm DECIMAL(5,3);
	SET pd=get_price_day(dt1);
	SET pm=get_price_minute(dt1);
	RETURN ROUND(
	TIMESTAMPDIFF(DAY,dt1,IFNULL(dt2,CURRENT_TIMESTAMP))
	* pd +
	IF(
	TIMESTAMPDIFF(MINUTE,dt1, IFNULL(dt2,CURRENT_TIMESTAMP))
	% 1440 * pm > pd, pd,
	TIMESTAMPDIFF(MINUTE,dt1,IFNULL(dt2,CURRENT_TIMESTAMP))
	% 1440 * pm)
	,2);
END//
DELIMITER ;

-- 8. Probarlo con sólo minutos

SELECT stay_imp('2023-05-04 09:00','2023-05-04 09:30');

-- 9. Días y minutos 

SELECT stay_imp('2023-05-03 09:00','2023-05-04 09:30');

-- 10. Minutos que se cobran como día entero

SELECT stay_imp('2023-05-03 09:00','2023-05-04 23:30');

-- 11. Importe y el IVA (21%) de cada estancia

SELECT *, stay_imp(in_date,out_date) AS import,
ROUND(stay_imp(in_date,out_date)*0.21,2) AS iva
FROM stay;

-- 12. Función que devuelve el número de vehículos que entraron
-- en la fecha que se pasa como parámetro.

-- 13. Número de vehículos que entraron hoy

-- 14. Número de vehículos que entraron cada día (sin duplicados)

-- 15. Función que recibe como parámetro una fecha y devuelve
-- los minutos de ocupación en esa fecha

-- 16. Minutos de ocupación el día 02-10-2018
