-- Examen de consultas SQL, 1º DAW,	2ª Evaluación 		21/03/23

-- Apellidos, nombre: 

-- 1. Descripción de los ingredientes de la paella, con su cantidad, precio e 
-- importe en euros. Ojo: la cantidad está en gramos y el precio en € por kilo.

SELECT i.*, it.quantity, it.quantity*i.price/100
FROM ingredient i,item it
WHERE i.ingredient_id=it.ingredient_id
AND it.recipe_id = (
    SELECT recipe_id
    FROM recipe
    WHERE description = "Paella"
);

-- 2. Todos los datos del ítem de mayor cantidad de cada receta

SELECT *
FROM item i1
WHERE quantity=(
    SELECT MAX(quantity)
    FROM item i2
    WHERE i1.recipe_id=i2.recipe_id --Correlacionales
);

-- 3. Identificadores de ingredientes que aparecen en más del 75% de las recetas

SELECT @x=COUNT(*)*0,75
FROM recipe;
SELECT ingredient_id, COUNT(*)
FROM item 
GROUP BY ingredient_id
HAVING COUNT(*)=@x;

-- 4. Todos los datos de las recetas que no llevan huevos pero sí tomate.

SELECT *
FROM recipe
WHERE recipe_id NOT IN (
    SELECT recipe_id
    FROM item 
    WHERE ingredient_id in(
        SELECT ingredient_id
        from ingredient
        WHERE description='Eggs'
    )
)
AND recipe_id IN(
     SELECT recipe_id
    FROM item 
    WHERE ingredient_id in(
        SELECT ingredient_id
        from ingredient
        WHERE description='Tomato'
    )
);

-- 5. Para cada ingrediente, todos sus datos junto con una columna que tome los
-- siguientes valores en función de las calorías:
-- - very high: mayor que 400
-- - high: mayor que 300
-- - normal: mayor que 200
-- - low: mayor que 100
-- - very low: 100 o menos

SELECT *,
IF(calories>400, 'Very high',
    IF(calories>300, 'High',
        IF(calories200,'Normal'
            IF(calories>100,'Low', 'Very low')
            )
        )
    );
AS cal_level
FROM ingredient;