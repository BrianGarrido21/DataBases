-- 1. Procedimiento que inserta o modifica un ingrediente.
-- Recibe como parámetros:
-- -- Descripción del ingrediente
-- -- Precio
-- -- Calorías
-- -- Stock
-- Si el ingrediente ya existía, se actualizan el precio, las calorías y el stock.
-- Si el ingrediente es nuevo, se inserta una fila con todos los datos

DELIMITER //
DROP PROCEDURE IF EXISTS upsert_ingredient//
CREATE PROCEDURE upsert_ingredient(
	par_des VARCHAR(40),
	par_pri DECIMAL(6,2),
	par_cal INT(6),
	par_sto INT(6)
)
BEGIN
	IF par_des IN (SELECT description FROM ingredient) THEN
		UPDATE ingredient 
		SET price=par_pri, calories=par_cal, stock=stock+par_sto
		WHERE description=par_des;
	ELSE
		INSERT INTO ingredient 
		VALUES (NULL, par_des, par_pri, par_cal, par_sto);
	END IF;
END//
DELIMITER ;

-- 2. Prueba con un ingrediente que ya existe

CALL upsert_ingredient('Honey',8.25,310,5500);

-- 3. Prueba con un ingrediente nuevo

CALL upsert_ingredient('Coconut oil',5.43,862,20000);

-- 4. Procedimiento que inserta o modifica un ítem.
-- Recibe como parámetros:
-- -- Identificador de la receta
-- -- Identificador del ingrediente
-- -- Cantidad
-- Si el ítem ya existía, se actualiza la cantidad (sumando).
-- Si el ítem es nuevo, se inserta una fila con todos los datos.
-- Ojo: la tabla ítem tiene una clave primaria compuesta.

DELIMITER //
DROP PROCEDURE IF EXISTS upsert_item//
CREATE PROCEDURE upsert_item(
	par_rec_id INT(6),
	par_ing_id INT(6),
	par_qua INT(6)
)
BEGIN
	DECLARE x BOOLEAN;
	SELECT 1 INTO x
	FROM item
	WHERE recipe_id=par_rec_id AND ingredient_id=par_ing_id;
	IF x THEN
		UPDATE item 
		SET quantity=quantity+par_qua
		WHERE recipe_id=par_rec_id AND ingredient_id=par_ing_id;
	ELSE
		INSERT INTO item
		VALUES (par_rec_id,	par_ing_id,	par_qua);
	END IF;
END//
DELIMITER ;

-- 5. Prueba con un item que existe

CALL upsert_item(1,5,5);

-- 6. Prueba con un item que no existe

CALL upsert_item(1,3,60);

-- 7. Añadir al procedimiento anterior un parámetro de salida
-- de tipo entero que tomará el siguiente valor:
-- -- 1 si se modifica el item
-- -- 2 si se inserta el item

DELIMITER //
DROP PROCEDURE IF EXISTS upsert_item//
CREATE PROCEDURE upsert_item(
	IN par_rec_id INT(6),
	IN par_ing_id INT(6),
	IN par_qua INT(6),
	OUT par_out INT(1)
)
BEGIN
	DECLARE x BOOLEAN;
	SELECT 1 INTO x
	FROM item
	WHERE recipe_id=par_rec_id AND ingredient_id=par_ing_id;
	IF x THEN
		UPDATE item 
		SET quantity=quantity+par_qua
		WHERE recipe_id=par_rec_id AND ingredient_id=par_ing_id;
		SET par_out=1;
	ELSE
		INSERT INTO item
		VALUES (par_rec_id,	par_ing_id,	par_qua);
		SET par_out=2;
	END IF;
END//
DELIMITER ;

-- 8. Prueba con un item que existe

CALL upsert_item(1,5,5,@x);
SELECT @x;

-- 9. Prueba con un item que no existe

CALL upsert_item(1,17,75,@x);
SELECT @x;

-- 10. Procedimiento que inserta una nueva comanda.
-- Los parámetros de entrada son dos:
-- -- número de raciones
-- -- identificador de la receta
-- Si hay suficiente stock de ingredientes para la comanda,
-- entonces se inserta la comanda con la fecha del sistema y
-- se actualizan (restando) los stocks de ingredientes.
-- Si no hay suficiente stock entonces no se hace nada.
-- Mediente un parámetro de salida se devuelve un 0 si no hay 
-- suficiente stock y un 1 en caso contrario.

DELIMITER //
DROP PROCEDURE IF EXISTS new_command//
CREATE PROCEDURE new_command(
	IN par_n INT(6),
	IN par_rec INT(6),
	OUT par_eno BOOLEAN
)
BEGIN
	IF enough_stock(par_rec,par_n) THEN
		INSERT INTO command 
		VALUES (NULL,CURRENT_DATE,par_n,par_rec);
		UPDATE ingredient i1
		SET stock=stock-(
			SELECT quantity*par_n
			FROM item i2
			WHERE recipe_id=par_rec
			AND i1.ingredient_id=i2.ingredient_id
		)
		WHERE ingredient_id IN (
			SELECT ingredient_id
			FROM item
			WHERE recipe_id=par_rec
		);
		SET par_eno=TRUE;
	ELSE
		SET par_eno=FALSE;
	END IF;
END//
DELIMITER ;

-- Puede hacerse un poco más corto sin ELSE

DELIMITER //
DROP PROCEDURE IF EXISTS new_command//
CREATE PROCEDURE new_command(
	IN par_n INT(6),
	IN par_rec INT(6),
	OUT par_eno BOOLEAN
)
BEGIN
	SET par_eno=enough_stock(par_rec,par_n);
	IF par_eno THEN
		INSERT INTO command 
		VALUES (NULL,CURRENT_DATE,par_n,par_rec);
		UPDATE ingredient i1
		SET stock=stock-(
			SELECT quantity*par_n
			FROM item i2
			WHERE recipe_id=par_rec
			AND i1.ingredient_id=i2.ingredient_id
		)
		WHERE ingredient_id IN (
			SELECT ingredient_id
			FROM item
			WHERE recipe_id=par_rec
		);
	END IF;
END//
DELIMITER ;

-- 11. Tratamos de crear una nueva comanda de 100 raciones
-- de paella (5)

CALL new_command(100,5,@x);
SELECT @x;