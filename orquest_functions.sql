-- Una función en MySQL o en Oracle es una rutina almacenada en la BD
-- -- Es muy parecida a una función en Java o en PHP
-- -- Se crea con la orden CREATE FUNCTION
-- -- Se elimina con la orden DROP FUNCTION
-- -- Puede tener ninguno, uno o varios parámetros de entrada
-- -- Puede tener variables locales
-- -- Devuelve un valor con la orden RETURN
-- -- Se invoca desde cualquier orden DML (SELECT, INSERT, DELETE, UPDATE)

-- 1. Función de que devuelve el número de intérpretes
-- del concierto que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS count_performers//
CREATE FUNCTION count_performers(par_concert_id INT(5))
RETURNS INT
BEGIN
	RETURN (
		SELECT COUNT(DISTINCT performer_id)
		FROM con_per
		WHERE concert_id=par_concert_id
	);
END//
DELIMITER ;

-- 2. Probar la función anterior con todos los conciertos

SELECT *, count_performers(concert_id)
FROM concerts;

-- 3. El concierto con más intérpretes

SELECT *, count_performers(concert_id)
FROM concerts
WHERE count_performers(concert_id) >= ALL (
	SELECT count_performers(concert_id)
	FROM concerts
);

-- 4. Función que devuelve el número de conciertos del año
-- que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS count_concerts//
CREATE FUNCTION count_concerts(par_year INT(4))
RETURNS INT
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM concerts
		WHERE YEAR(concert_date)=par_year
	);
END//
DELIMITER ;

-- 5. Para cada año, número de conciertos

SELECT DISTINCT YEAR(concert_date), 
count_concerts(YEAR(concert_date))
FROM concerts;

-- Sin la función es casi más fácil

SELECT YEAR(concert_date), COUNT(*)
FROM concerts
GROUP BY YEAR(concert_date);

-- 6. Función que devuelve la suma de público en el auditorio 
-- que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS sum_people//
CREATE FUNCTION sum_people(par_auditorium VARCHAR(30))
RETURNS INTEGER
BEGIN
	RETURN (
		SELECT SUM(people)
		FROM concerts
		WHERE auditorium=par_auditorium
	);
END//
DELIMITER ;

-- 7. Suma de público en la Casa Colón

SELECT sum_people('Casa Colón');

-- 8. Modifica la función anterior para añadir un parámetro más, el año con cuatro dígitos
-- Así la función devuelve la suma de público en el auditorio y en el año que se pasan como parámetros
-- Hay que evitar que la función devuelva NULL cuando no hay datos

DELIMITER //
DROP FUNCTION IF EXISTS sum_people//
CREATE FUNCTION sum_people(par_auditorium VARCHAR(30),par_year INT(4))
RETURNS INTEGER
BEGIN
	RETURN (
		SELECT IFNULL(SUM(people),0)
		FROM concerts
		WHERE auditorium=par_auditorium
		AND YEAR(concert_date)=par_year
	);
END//
DELIMITER ;

-- 9. Suma de público en el Gran Teatro en el año 2019

SELECT sum_people('Casa Colón',2019);

-- 10. Función booleana que recibe dos parámetros:
-- -- Identificador de intérprete
-- -- Identificador de pieza musical
-- Devuelve TRUE si el intérprete ha tocado alguna vez la pieza

DELIMITER //
DROP FUNCTION IF EXISTS played//
CREATE FUNCTION played(par_performer_id INT(5),par_piece_id INT(5))
RETURNS BOOLEAN
BEGIN
	RETURN par_performer_id IN (
		SELECT performer_id
		FROM con_per
		WHERE concert_id IN (
			SELECT concert_id
			FROM con_pie
			WHERE piece_id=par_piece_id
		)
	);
END//
DELIMITER ;

-- De otra forma

DELIMITER //
DROP FUNCTION IF EXISTS played//
CREATE FUNCTION played(par_performer_id INT(5),par_piece_id INT(5))
RETURNS BOOLEAN
BEGIN
	RETURN (
		SELECT performer_id
		FROM con_per
		WHERE performer_id=par_performer_id AND concert_id IN (
			SELECT concert_id
			FROM con_pie
			WHERE piece_id=par_piece_id
		) 
	) IS NOT NULL;
END//
DELIMITER ;

-- 11. Todos los datos de los intérpretes que han tocado la pieza 2

SELECT *
FROM performers
WHERE played(performer_id,2);

-- 12. Todos los datos de intérpretes que han tocado la pieza 2
-- pero no han tocado la pieza 3

SELECT *
FROM performers
WHERE played(performer_id,2) AND NOT played(performer_id,3);

-- 13. ¿Ha tocado el intérprete 3 la pieza 5?

SELECT played(3,5);

-- 14. Todos los datos de piezas que ha tocado  el intérprete 3

SELECT *
FROM pieces
WHERE played(3,piece_id);

-- 15. Función que devuelve verdadero si un intérprete sabe tocar
-- un instrumento, falso en caso contrario. El identificador del
-- intérprete y el nombre del instrumento se pasan como parámetros

DELIMITER //
DROP FUNCTION IF EXISTS plays//
CREATE FUNCTION plays(par_performer_id INT(5),par_instrument VARCHAR(30))
RETURNS BOOLEAN
BEGIN
	RETURN par_performer_id IN (
		SELECT performer_id
		FROM con_per
		WHERE instrument=par_instrument
	);
END//
DELIMITER ;

-- 16. Todos los datos de los músicos que tocan el violín pero no 
-- la flauta

SELECT *
FROM performers
WHERE plays(performer_id,'Violin') AND NOT plays(performer_id,'Flute');

-- 17. Función booleana que recibe dos parámetros:
-- -- Identificador de intérprete
-- -- Identificador de compositor
-- Devuelve TRUE si el intérprete ha tocado alguna vez alguna pieza
-- de ese compositor

DELIMITER //
DROP FUNCTION IF EXISTS played_com//
CREATE FUNCTION played_com(par_performer_id INT(5),par_composer_id INT(5))
RETURNS BOOLEAN
BEGIN
	RETURN par_performer_id IN (
		SELECT performer_id
		FROM con_per
		WHERE concert_id IN (
			SELECT concert_id
			FROM con_pie
			WHERE piece_id IN (
				SELECT piece_id
				FROM pieces
				WHERE composer_id=par_composer_id			
			)
		)
	);
END//
DELIMITER ;

-- 18. Intérpretes que no han tocado piezas de Mozart

SELECT *
FROM performers
WHERE NOT played_com(performer_id,2);

-- 19. Cuando se borra una fila en una tabla y se produce un hueco
-- en la clave primaria, esta clave puede ser asignada de nuevo
-- para insertar otra fila.
-- Crea una función sin parámetros que devuelva la siguiente clave
-- a insertar en la tabla performers.

DELIMITER //
DROP FUNCTION IF EXISTS next_performer_id//
CREATE FUNCTION next_performer_id()
RETURNS INT
BEGIN
	RETURN (
		SELECT MIN(performer_id+1)
		FROM performers
		WHERE performer_id+1 NOT IN (
			SELECT performer_id
			FROM performers
		)
	);
END//
DELIMITER ;

-- 20. Inserta un nuevo intérprete generando su identificador
-- con la función anterior

INSERT INTO performers (performer_id, name, birth_date)
VALUES (next_performer_id(), 'García, Sara', '1999-02-17');
