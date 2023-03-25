-- 1. Todos los datos de los vehículos blancos o grises que
-- entraron el día 01-10-2018

SELECT *
FROM vehicle
WHERE vehicle_id IN (
	SELECT vehicle_id
	FROM stay
	WHERE in_date='2018-10-01'
)
AND color IN ('Blanco, Gris');

-- No sale ninguno porque el campo in_date es DATETIME
-- La función DATE() devuelve la fecha de un DATETIME

SELECT *
FROM vehicle
WHERE vehicle_id IN (
	SELECT vehicle_id
	FROM stay
	WHERE DATE(in_date)='2018-10-01'
)
AND color IN ('Blanco', 'Gris');

-- 2. Para cada marca, número de vehículos

SELECT mark, COUNT(*)
FROM vehicle
GROUP BY mark;

-- 3. Para cada marca y modelo, número de vehículos

SELECT mark, model, COUNT(*)
FROM vehicle
GROUP BY mark, model;

-- 4. Para cada matrícula, número de entradas y número de salidas

SELECT vehicle_id, COUNT(in_date) AS num_in, COUNT(out_date) AS num_out
FROM stay
GROUP BY vehicle_id;

-- 5. La matrícula del vehículo que más veces ha entrado

SELECT vehicle_id, COUNT(in_date) AS num_in
FROM stay
GROUP BY vehicle_id
HAVING COUNT(in_date) >= ALL (
	SELECT COUNT(in_date)
	FROM stay
	GROUP BY vehicle_id
);

-- 6. Todos los datos de los vehículos que están actualmente estacionados

SELECT *
FROM vehicle
WHERE vehicle_id IN (
	SELECT vehicle_id
	FROM stay
	WHERE out_date IS NULL
);

-- 7. Para cada día y cada planta, número de entradas

SELECT DATE(s.in_date), p.place_floor, COUNT(in_date)
FROM place p, stay s
WHERE p.place_id=s.place_id
GROUP BY DATE(s.in_date), p.place_floor;

-- 8. Todos los datos de las estancias y los precios por día y minuto

SELECT *
FROM stay s, price p
WHERE s.in_date BETWEEN p.from_date AND p.until_date;

-- 9. Todos los datos de las estancias junto con su duración en minutos

SELECT *, TIMESTAMPDIFF(MINUTE, in_date, out_date)
FROM stay;

-- En estancias con fecha de salida nula, usar CURRENT_TIMESTAMP

SELECT *, 
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
FROM stay;

-- 10. Teniendo en cuenta que un día tiene 1440 minutos, calcula
-- el número de días y de minutos de cada estancia
-- La función MOD y el operador % calculan el resto de la división

SELECT *, 
TIMESTAMPDIFF(DAY, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
AS num_days,
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
% 1440
AS num_minutes
FROM stay;

-- 11. Calcula el importe de cada estancia

SELECT *,
ROUND(
TIMESTAMPDIFF(DAY, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
* price_day +
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
% 1440 * price_minute ,2)
AS import
FROM stay s, price p
WHERE s.in_date BETWEEN p.from_date AND p.until_date;

-- La función IF tiene tres parámetros:
-- -- la condición que se va a evaluar
-- -- el valor devuelto si la condición es verdadera
-- -- el valor devuelto si la condición es falsa

-- 12. Para cada estancia, calcula la columna 'Duration' con el siguiente valor:
-- "long" en estancias de más de 100 minutos
-- "short" en estancias menores o iguales a 100 minutos

SELECT *,
IF(
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP)) > 100,
'Long', 'Short') AS duration
FROM stay;

-- 13. Repite la consulta anterior pero con el valor "medium" para estancias
-- comprendidas entre 80 y 100 minutos, ambos valores incluídos

SELECT *,
IF(
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP)) > 100,
'Long',
	IF(
	TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP)) >= 80,
	'Medium','Short')
) 
AS duration
FROM stay;

-- 14. Repite la consulta anterior usando sólo el operador < (less than)

SELECT *,
IF(
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP)) < 80,
'Short',
	IF(
	TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP)) <= 100,
	'Medium','Long')
) 
AS duration
FROM stay;

-- 15. Todos los datos de la tabla vehículos junto con una columna
-- que muestre si el vehículo es alemán o del resto del mundo

SELECT *,
IF(mark='Opel' OR mark='Mercedes' OR mark='Audi','German','ROTW')
AS origin
FROM vehicle;

-- Mejor con el operador IN

SELECT *,
IF(mark IN ('Opel','Mercedes','Audi'),'German','ROTW')
AS origin
FROM vehicle;

-- 16. Recalcula el importe de las estancias teniendo en cuenta que
-- no se puede cobrar por minutos más que el precio de un día

SELECT *,
ROUND(
TIMESTAMPDIFF(DAY, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
* price_day +
IF(
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
% 1440 * price_minute > price_day, price_day,
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
% 1440 * price_minute )
,2)
AS import
FROM stay s, price p
WHERE s.in_date BETWEEN p.from_date AND p.until_date;

-- 17. Vehículos para los que no hay ninguna estancia

SELECT *
FROM vehicle
WHERE vehicle_id NOT IN (
	SELECT vehicle_id
	FROM stay
);

-- 18. Para cada vehículo, número de estancias
-- Que aparezcan todos los vehículos

SELECT v.*, COUNT(s.vehicle_id)
FROM vehicle v LEFT JOIN stay s ON v.vehicle_id=s.vehicle_id
GROUP BY v.vehicle_id, v.mark, v.model, v.color;

-- 19. Para cada plaza, número de estancias
-- Que aparezcan todas las plazas

SELECT p.*, COUNT(s.place_id) AS num_stays
FROM place p LEFT JOIN stay s ON p.place_id=s.place_id
GROUP BY p.place_id, p.place_floor;

-- 20. Tiempo en minutos que estuvo ocupada cada plaza
-- Que no aparezcan nulos

SELECT p.*, COUNT(s.place_id) AS num_stays,
IFNULL(SUM(TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))),0) AS sum_minutes
FROM place p LEFT JOIN stay s ON p.place_id=s.place_id
GROUP BY p.place_id, p.place_floor;

-- Para sustituir valores nulos por otra cosa,
-- se utiliza la función IFNULL, que tiene dos parámetros:
--   * la expresión que se evalúa
--   * el valor devuelto si la expresión es nula
-- En caso de que la expresión no sea nula, devuelve la expresión

-- 21. Para cada estancia, su duración en minutos suponiendo que 
-- que ahora son las 18:00 del 4 de noviembre de 2018

SELECT *,
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date,'2018-11-04'))
AS duration
FROM stay;

-- 22. Minutos de ocupación el día 3 de octubre de 2018

SELECT TIMESTAMPDIFF(MINUTE, 
	IF(in_date<'2018-10-03','2018-10-03',in_date), 
	IF(out_date>'2018-10-04','2018-10-04',out_date)
)
FROM stay
WHERE in_date<'2018-10-04' AND out_date>='2018-10-03'; 

-- 23. Suma de minutos de ocupación el día 3 de octubre de 2018

SELECT SUM(TIMESTAMPDIFF(MINUTE, 
	IF(in_date<'2018-10-03','2018-10-03',in_date), 
	IF(out_date>'2018-10-04','2018-10-04',out_date)
))
FROM stay
WHERE in_date<'2018-10-04' AND out_date>='2018-10-03'; 

-- 24. Porcentaje de ocupación el día 3 de octubre de 2018

SELECT SUM(TIMESTAMPDIFF(MINUTE, 
	IF(in_date<'2018-10-03','2018-10-03',in_date), 
	IF(out_date>'2018-10-04','2018-10-04',out_date)
)) / (1440 * 8) * 100
FROM stay
WHERE in_date<'2018-10-04' AND out_date>='2018-10-03'; 

-- Vamos a hacer una subconsulta para contar las plazas

SELECT SUM(TIMESTAMPDIFF(MINUTE, 
	IF(in_date<'2018-10-03','2018-10-03',in_date), 
	IF(out_date>'2018-10-04','2018-10-04',out_date)
)) / (1440 * (
	SELECT COUNT(*)
	FROM place
)) * 100
FROM stay
WHERE in_date<'2018-10-04' AND out_date>='2018-10-03'; 

-- 25. En la consulta anterior, el número de plazas es 8
-- Podemos obtener este valor mediante una consulta
-- y guardarlo en una variable para su uso posterior

SELECT @x:=COUNT(*)
FROM place;

SELECT SUM(TIMESTAMPDIFF(MINUTE, 
	IF(in_date<'2018-10-03','2018-10-03',in_date), 
	IF(out_date>'2018-10-04','2018-10-04',out_date)
)) / (1440 * @x) * 100
FROM stay
WHERE in_date<'2018-10-04' AND out_date>='2018-10-03'; 

-- 26. Para cada marca con más de 4 vehículos, número de vehículos

SELECT mark, COUNT(*)
FROM vehicle
GROUP BY mark
HAVING COUNT(*)>4;

-- 27. Estado actual de las todas las plazas de aparcamiento
-- Para cada plaza, matrícula del vehículo que la ocupa
-- Si la plaza está vacía, que aparezca la palabra "empty"

SELECT p.place_id, 
IF(in_date IS NULL OR out_date IS NOT NULL,'Empty',vehicle_id)
AS status
FROM place p LEFT JOIN stay s1
ON p.place_id=s1.place_id
WHERE in_date>= ALL (
	SELECT in_date
	FROM stay s2
	WHERE s1.place_id=s2.place_id -- Correlacionada
);

-- 28. Plazas en las que haya estacionado alguna vez un Opel Astra.

SELECT DISTINCT place_id
FROM stay
WHERE vehicle_id IN (
	SELECT vehicle_id
	FROM vehicle
	WHERE mark='Opel' AND model='Astra'
);

-- 29. Vehículos que nunca hayan estacionado en la primera planta.

SELECT *
FROM vehicle
WHERE vehicle_id NOT IN (
	SELECT vehicle_id
	FROM stay
	WHERE place_id IN (
		SELECT place_id
		FROM place
		WHERE place_floor=1
	)
);

-- 30. Estancias más cortas que la media. Supongamos que hoy es 10/10/2018

SELECT *
FROM stay
WHERE TIMESTAMPDIFF(MINUTE,in_date,IFNULL(out_date,'2018-10-10')) < (
	SELECT AVG(TIMESTAMPDIFF(MINUTE,in_date,IFNULL(out_date,'2018-10-10')))
	FROM stay
);

-- 31. Vehículo con mayor número de minutos.

SELECT vehicle_id, SUM(TIMESTAMPDIFF(MINUTE,in_date,IFNULL(out_date,'2018-10-10')))
FROM stay
GROUP BY vehicle_id
HAVING SUM(TIMESTAMPDIFF(MINUTE,in_date,IFNULL(out_date,'2018-10-10'))) >= ALL (
	SELECT SUM(TIMESTAMPDIFF(MINUTE,in_date,IFNULL(out_date,'2018-10-10')))
	FROM stay
	GROUP BY vehicle_id
);

-- 32. Día con mayor número de entradas.

SELECT DATE(in_date), COUNT(*)
FROM stay
GROUP BY DATE(in_date)
HAVING COUNT(*) >= ALL (
	SELECT COUNT(*)
	FROM stay
	GROUP BY DATE(in_date)
);

-- 33. Las estancias 9 y 24 son del mismo vehículo. Minutos que estuvo fuera.
-- Solución con variables

SELECT @x:=out_date
FROM stay 
WHERE stay_id=9;

SELECT @y:=in_date
FROM stay
WHERE stay_id=24;

SELECT TIMESTAMPDIFF(MINUTE,@x,@y);

-- 34. Lo mismo pero con subconsultas

SELECT TIMESTAMPDIFF(MINUTE,(
	SELECT out_date
	FROM stay 
	WHERE stay_id=9
),(
	SELECT in_date
	FROM stay
	WHERE stay_id=24
));

-- 35. Incremento en % de precio del día desde el 01/02/2017 hasta 01/02/2018.

-- Solución con variables

SELECT @x:=price_day
FROM price
WHERE '2017-02-01' BETWEEN from_date AND until_date;

SELECT @y:=price_day
FROM price
WHERE '2018-02-01' BETWEEN from_date AND until_date;

SELECT (@y-@x) *100 / @x;

-- Solución con subconsultas

SELECT ((
	SELECT price_day
	FROM price
	WHERE '2018-02-01' BETWEEN from_date AND until_date
)-(
	SELECT price_day
	FROM price
	WHERE '2017-02-01' BETWEEN from_date AND until_date
)) *100 / (
	SELECT price_day
	FROM price
	WHERE '2017-02-01' BETWEEN from_date AND until_date
);

-- 36. Facturación diaria (suma de importes cobrados a la salida)

SELECT DATE(out_date), COUNT(*) AS num_outs,
SUM(ROUND(
TIMESTAMPDIFF(DAY, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
* price_day +
IF(
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
% 1440 * price_minute > price_day, price_day,
TIMESTAMPDIFF(MINUTE, in_date, IFNULL(out_date, CURRENT_TIMESTAMP))
% 1440 * price_minute )
,2)) AS sum_import
FROM stay s, price p
WHERE s.in_date BETWEEN p.from_date AND p.until_date
GROUP BY DATE(out_date);

-- 37. El vehículo '0987-BSR' aparca en la primera plaza libre

-- La clave primaria

SELECT @x:=MAX(stay_id)+1
FROM stay;

-- La primera plaza libre

SELECT @y:=MIN(place_id)
FROM place
WHERE place_id NOT IN (
	SELECT place_id
	FROM stay
	WHERE out_date IS NULL
);

INSERT INTO stay VALUES
(@x,CURRENT_TIMESTAMP,NULL,'0987-BSR',@y);

-- 38. Los precios suben a partir de hoy un 4.5%
-- 1º Modificar el último registro de precios
-- 2º Insertar un nuevo registro de precios

SELECT @my_price_day:=price_day*1.045, 
@my_price_minute:=price_minute*1.045
FROM price
WHERE until_date IS NULL;

SELECT @x:=MAX(price_id)+1
FROM price;

UPDATE price 
SET until_date=CURRENT_DATE-1
WHERE until_date IS NULL;

INSERT INTO price VALUES
(@x,CURRENT_DATE,NULL,@my_price_day,@my_price_minute);

-- 39. Modificar la horas de entrada, incrementándolas en 5 minutos
-- para el vehículo '0987-BSR'

UPDATE stay
SET in_date=ADDTIME(in_date,300)
WHERE vehicle_id='0987-BSR';

---------------------
--- Transacciones ---
---------------------

-- Una transacción es un conjunto de operaciones DML
-- (Data Manipulation Language): INSERT, UPDATE y DELETE
-- que pueden ser confirmadas o canceladas

-- 40. Ver el valor de la variable del sistema AUTOCOMMIT

SELECT @@AUTOCOMMIT;

-- El valor 1 (verdadero) indica que cada orden DML se confirma
-- automáticamente y no se puede volver atrás

-- 41. Poner AUTOCOMMIT a falso para que las transacciones no se 
-- confirmen hasta que ejecutemos la orden COMMIT

SET AUTOCOMMIT=FALSE;

-- La orden START TRANSACTION inicia la transacción y establece
-- un punto al que volver en caso de hacer ROLLBACK

-- 42. Inicio de la transacción

START TRANSACTION;

-- 43. Me olvido de poner el WHERE en el DELETE FROM

DELETE FROM stay;
-- WHERE vehicle_id=''

-- 44. Volvemos hasta el inicio de la transacción deshaciendo cambios

ROLLBACK;

-- 45. Para terminar la transacción confirmando los cambios

COMMIT;

-- 46. Crear una vista llamada stay_plus donde aparezcan todos los campos de la
-- tabla stay junto con dos campos nuevos: los días y los minutos de duración

DROP VIEW IF EXISTS stay_plus;
CREATE VIEW stay_plus
AS SELECT *, TIMESTAMPDIFF(DAY, in_date, out_date) AS days,
TIMESTAMPDIFF(MINUTE, in_date, out_date) % 1440 AS minutes
FROM stay;

-- 47. Usa la vista anterior para simplificar la consulta 16

-- 48. Crea una vista llamada stay_plus_plus con todos los campos
-- de la vista stay_plus y un campo nuevo: el importe de la estancia

-- 49. Usando la vista stay_plus_plus, para cada vehículo, número
-- de entradas, suma de minutos y suma de importe

-- 50. De la consulta anterior, obtener el vehículo con el máximo
-- importe

-- 51. Para cada precio, número de días que estuvo vigente y número 
-- de minutos a partir de los cuales se cobra el día entero
