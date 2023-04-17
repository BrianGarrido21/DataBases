-- Active: 1679570069688@@127.0.0.1@3306@cooking
-- 1. Procedimiento que inserta o modifica un ingrediente.
-- Recibe como parámetros:
-- -- Descripción del ingrediente
-- -- Precio
-- -- Calorías
-- -- Stock
-- Si el ingrediente ya existía, se actualizan el precio, las calorías y el stock.
-- Si el ingrediente es nuevo, se inserta una fila con todos los datos

DELIMITER //
DROP PROCEDURE IF EXISTS upserts_ingredient//
CREATE PROCEDURE upsets_ingredient(par_des VARCHAR(40),par_pri DECIMAL(6,2),par_cal INT(6), par_sto INT(6))
BEGIN
    IF par_des IN (SELECT description FROM ingredient) THEN
    UPDATE ingredient 
    SET price=par_pri, calories=par_cal,stock=stock+par_sto
    WHERE description=par_des;
    ELSE
        INSERT INTO ingredient 
        VALUES (NULL,par_des,par_pri,par_cal,par_sto);
        END IF;
END//

--2. Prueba con un ingrediente que ya existe
CALL upserts_ingredient('Honey',8.25,310,5500);

--3. Prueba con un ingrediente nuevo
CALL upserts_ingredient('Coconut Oil',5.43,862,20000);

-- 4. Procedimiento que inserta o modifica un ítem.
-- Recibe como parámetros:
-- -- Identificador de la receta
-- -- Identificador del ingrediente
-- -- Cantidad
-- Si el ítem ya existía, se actualiza la cantidad.
-- Si el ítem es nuevo, se inserta una fila con todos los datos.
-- Ojo: la tabla ítem tiene una clave primaria compuesta.

DELIMITER //
DROP PROCEDURE IF EXISTS upserts_item//
CREATE PROCEDURE upserts_item(par_rec INT(6),par_ing INT(6), par_qua INT(6))
BEGIN
    DECLARE x BOOLEAN;
    SELECT 1 INTO x
    from item
    WHERE recipe_id=par_rec AND ingredient_id=par_ing;
    IF x THEN
        UPDATE item
        SET recipe_id=par_rec,ingredient_id=par_ing,quantity=par_qua
        WHERE recipe_id=par_rec;
    ELSE
        INSERT INTO item
        VALUES (par_rec,par_ing.par_qua);
        END IF;
END//



-- 5. Prueba con un item que existe.
CALL upsets_item(1,5,40)



-- 6.ADD Lo mismo pero no esiste
CALL upsets_item(1,3,60)




--10 Procedimiento que inserta una nueva comanda.
-- Los parametros de entrada: numero de raciones, identificador de la receta
-- Si hay suficiente stock de ingredientes para la comanda