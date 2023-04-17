-- Rutinas almacenadas en la Base de Datos 
-- Se escriben en un lenguaje llamado PL-SQL
-- Procedimental Language Structured Query Language
-- En PLSQL se programan tres tipos de objetos o rutinas:
-- -- Funciones: Tienen una lista de argumentos de entrada
-- -- y devuelven un valor. La ejecucion de una funcion es READONLY
-- -- Procedimientos: Tienen una lista de argumentos de entrada
-- -- y de salida y no devuelven ningún valor. La ejecucion de un
-- -- procedimiento no es READONLY, y se producen INSERT, DELETE UPDATE.
-- -- Disparadores: No tienen lista de argumentos, no devuelven
-- -- ningún valor y se disparan automáticamente cuando se
-- -- ejecuta alguna operación DML (INSERT, DELETE, UPDATE)

-- 1. Función que recibe como argumento el identificador 
-- de una receta y devuelve el número de ingredientes

SET DELIMITER //
DROP FUNCTION IF EXISTS number_of_ingreds//
CREATE FUNCTION number_of_ingreds(par_recipe_id INTEGER)
RETURNS INTEGER
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM item
		WHERE recipe_id=par_recipe_id
	);
END//
SET DELIMITER ;

-- 2. Para cada receta, todos sus datos y número de ingredientes

SELECT *, number_of_ingreds(recipe_id)
FROM recipe;

-- Sin usar la función sería

SELECT r.*, COUNT(i.recipe_id) AS number_of ingreds
FROM recipe r LEFT JOIN item i
ON r.recipe_id=i.recipe_id
GROUP BY r.recipe_id, r.description, r.diff_level;

-- 3. Número de ingredientes de la receta 5

SELECT number_of_ingreds(5);

-- 4. Todos los datos de la receta con más ingredientes

SELECT *, number_of_ingreds(recipe_id)
FROM recipe
WHERE number_of_ingreds(recipe_id) >= ALL (
	SELECT number_of_ingreds(recipe_id)
	FROM recipe
);

-- 5. Función que recibe como parámetro el identificador de
-- una receta y devuelve la suma de sus calorías por ración

SET DELIMITER //
DROP FUNCTION IF EXISTS total_calories//
CREATE FUNCTION total_calories(par_recipe_id INTEGER)
RETURNS INTEGER
BEGIN
	RETURN (
		SELECT SUM(it.quantity*i.calories/100)
		FROM ingredient i, item it
		WHERE i.ingredient_id=it.ingredient_id
		AND it.recipe_id=par_recipe_id
	);
END//
SET DELIMITER ;

-- 6. Para cada receta, todos sus datos y suma de calorías

SELECT *, total_calories(recipe_id)
FROM recipe;

-- 7. La receta más ligera

SELECT *, total_calories(recipe_id)
FROM recipe
WHERE total_calories(recipe_id) >= ALL (
	SELECT IFNULL(total_calories(recipe_id),0)
	FROM recipe
);

-- Usando MAX

SELECT *, total_calories(recipe_id)
FROM recipe
WHERE total_calories(recipe_id) = (
	SELECT MAX(total_calories(recipe_id))
	FROM recipe
);

-- 8. Función booleana que devuelve verdadero si un ingrediente
-- se ha usado en una fecha determinada. Recibe dos parámetros:
-- -- Identificador del ingrediente
-- -- Fecha

DELIMITER //
DROP FUNCTION IF EXISTS is_used//
CREATE FUNCTION is_used(par_ingredient_id INT, par_date DATE)
RETURNS BOOLEAN
BEGIN
	RETURN (
		SELECT COUNT(*) > 0
		FROM command
		WHERE command_date=par_date
		AND recipe_id IN (
			SELECT recipe_id
			FROM item
			WHERE ingredient_id=par_ingredient_id
		)
	);
END//
DELIMITER ;


-- 9. Probar la función anterior para saber si se usó bacon el
-- día 6 de abril de 2021.

SELECT is_used(20,'2021-04-06');

-- Podemos buscar el valor 20 mediante una subconsulta

SELECT is_used((
	SELECT ingredient_id
	FROM ingredient
	WHERE description='Bacon'
),'2021-04-06');

-- 10. Función booleana que devuelve verdadero si existe suficiente 
-- stock de ingredientes para una receta. Recibe dos parámetros:
-- -- Identificador de la receta
-- -- Número de raciones

DELIMITER //
DROP FUNCTION IF EXISTS enough_stock//
CREATE FUNCTION enough_stock(par_recipe_id INT, par_n INT)
RETURNS BOOLEAN
BEGIN
	RETURN 1 = ALL (
		SELECT it.quantity*par_n <= i.stock
		FROM item it, ingredient i
		WHERE it.ingredient_id=i.ingredient_id
		AND it.recipe_id=par_recipe_id
	);
END//
DELIMITER ;

-- de otra forma

DELIMITER //
DROP FUNCTION IF EXISTS enough_stock//
CREATE FUNCTION enough_stock(par_recipe_id INT, par_n INT)
RETURNS BOOLEAN
BEGIN
	RETURN 0 <= ALL (
		SELECT i.stock - it.quantity*par_n
		FROM item it, ingredient i
		WHERE it.ingredient_id=i.ingredient_id
		AND it.recipe_id=par_recipe_id
	);
END//
DELIMITER ;

-- 11. Probar la función para saber si hay stock para 45 raciones
-- de Grilled tuna (2)

SELECT enough_stock(2,45);

-- 12. ¿De qué recetas podemos preparar 25 raciones?

SELECT *
FROM recipe
WHERE enough_stock(recipe_id,25);

-- 13. Función que devuelve la clasificación energética de la receta
-- cuyo identificador se pasa como parámetro, según la siguiente tabla:
-- -- hasta 300 calorías 'Low'
-- -- más de 300 y hasta 500 'Medium'
-- -- más de 500 y hasta 700 'High'
-- -- más de 700 'Very high'

SET DELIMITER //
DROP FUNCTION IF EXISTS energy_class//
CREATE FUNCTION energy_class(par_recipe_id INT)
RETURNS VARCHAR(20)
BEGIN
	RETURN (
		SELECT 
			IF(total_calories(par_recipe_id)<=300,'Low',
				IF(total_calories(par_recipe_id)<=500,'Medium',
					IF(total_calories(par_recipe_id)<=700,'High','Very high')
			)
		)
	);
END//
SET DELIMITER ;

-- Si la orden SELECT que está dentro de RETURN no usa la clausula FROM
-- entonces mejor se quita

SET DELIMITER //
DROP FUNCTION IF EXISTS energy_class//
CREATE FUNCTION energy_class(par_recipe_id INT)
RETURNS VARCHAR(20)
BEGIN
	RETURN IF(total_calories(par_recipe_id)<=300,'Low',
				IF(total_calories(par_recipe_id)<=500,'Medium',
					IF(total_calories(par_recipe_id)<=700,'High','Very high')
			)
		);
END//
SET DELIMITER ;

-- Usar una variable para guardar lo que devuelve total_calories(par_recipe_id)

SET DELIMITER //
DROP FUNCTION IF EXISTS energy_class//
CREATE FUNCTION energy_class(par_recipe_id INT)
RETURNS VARCHAR(20)
BEGIN
	DECLARE x INT;
	SET x=total_calories(par_recipe_id);
	RETURN IF(x<=300,'Low',
				IF(x<=500,'Medium',
					IF(x<=700,'High','Very high')
			)
		);
END//
SET DELIMITER ;

-- Usando la sentecia IF-THEN-ELSE en lugar de la función IF

SET DELIMITER //
DROP FUNCTION IF EXISTS energy_class//
CREATE FUNCTION energy_class(par_recipe_id INT)
RETURNS VARCHAR(20)
BEGIN
	DECLARE x INT;
	SET x=total_calories(par_recipe_id);
	IF x<=300 THEN 
		RETURN 'Low';
	ELSE
		IF x<=500 THEN
			RETURN 'Medium';
		ELSE
			IF x<=700 THEN
				RETURN 'High';
			ELSE
				RETURN 'Very high';
			END IF;
		END IF;
	END IF;
END//
SET DELIMITER ;

-- 14. Probar la función anterior para visulizar la clasificación
-- energética de los ingredientes del desayuno inglés

SELECT energy_class(3);

-- 15. Clasificación energética de todas las recetas

SELECT *, energy_class(recipe_id)
FROM recipes;

-- 16. Función que devuelve verdadero si con cierta cantidad euros
-- tenemos suficiente dinero para un número de raciones de una receta.
-- Recibe como parámetros:
-- -- Cantidad de euros
-- -- Identificador de la receta
-- -- Número de raciones

DELIMITER //
DROP FUNCTION IF EXISTS enough_money//
CREATE FUNCTION enough_money(par_eu FLOAT, par_recipe_id INT, par_n INT)
RETURNS BOOLEAN
BEGIN
	DECLARE x FLOAT;
	SET x=(
		SELECT SUM(i.price/1000*it.quantity)*par_n
		FROM ingredient i, item it
		WHERE i.ingredient_id=it.ingredient_id
		AND it.recipe_id=par_recipe_id
	);
	IF x > par_eu THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
END//
DELIMITER ;

-- Una solución más corta sin variables y sin IF-THEN-ELSE

DELIMITER //
DROP FUNCTION IF EXISTS enough_money//
CREATE FUNCTION enough_money(par_eu FLOAT, par_recipe_id INT, par_n INT)
RETURNS BOOLEAN
BEGIN
	RETURN par_eu >= (
		SELECT SUM(i.price/1000*it.quantity)*par_n
		FROM ingredient i, item it
		WHERE i.ingredient_id=it.ingredient_id
		AND it.recipe_id=par_recipe_id
	);
END//
DELIMITER ;

-- 17. Para todas las recetas, comprobueba qué devuelve la función
-- con 10 euros y 9 raciones

SELECT *, enough_money(10,recipe_id,9)
FROM recipe;
 
-- 18. Función que devuelve el coste de una ración de una receta que
-- se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS cost//
CREATE FUNCTION cost(par_recipe_id INT)
RETURNS FLOAT
BEGIN
	RETURN (
		SELECT SUM(i.price/1000*it.quantity)
		FROM ingredient i, item it
		WHERE i.ingredient_id=it.ingredient_id
		AND it.recipe_id=par_recipe_id
	);
END//
DELIMITER ;

-- 19. El coste de todas las recetas

SELECT *, cost(recipe_id)
FROM recipe;

-- 20. Utiliza la función del ejercicio 18 para simplificar la función
-- del ejercicio 16

DELIMITER //
DROP FUNCTION IF EXISTS enough_money//
CREATE FUNCTION enough_money(par_eu FLOAT, par_recipe_id INT, par_n INT)
RETURNS BOOLEAN
BEGIN
	RETURN par_eu >= cost(par_recipe_id)*par_n;
END//