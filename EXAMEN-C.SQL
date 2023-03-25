-- Active: 1679570069688@@127.0.0.1@3306@cooking
-- Examen de consultas SQL,	1º DAW,	2ª Evaluación 		21/03/23

-- Apellidos, nombre:

-- 1. Todos los datos de las recetas que no llevan huevos ni aceite de girasol.


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
        WHERE description='Sunflower oil'
    )
);

-- 2. Para cada ingrediente, todos sus datos junto con una columna que tome los
-- siguientes valores en función del precio:
-- - very cheap: menor que 1€
-- - cheap: menor que 2€
-- - normal; menor que 3€
-- - expensive: menor que 4€
-- - very expensive: de 4€ en adelante

SELECT *,
IF(price<1,'Very cheap',
    IF(price<2,'cheap',
        IF(price<3,'Norrmal',
            IF(price<4,'Expensive','Very expensive')
        )
    )
)AS price_level
FROM ingredient;

-- 3. Para cada año, suma de importe de las comandas. Ojo que la cantidad está en
-- gramos y el precio en euros por kilo.

SELECT YEAR(c.command_date), SUM(i.price*it.quantity/1000*c.rations)
FROM ingredient i, item it, command c
WHERE i.ingredient_id= it.ingredient_id
and it.recipe_id=c.recipe_id
GROUP BY YEAR(c.command_date);

-- 4. Para cada receta, su identificador y todos los datos del ítem con mayor cantidad.

SELECT *
FROM item i1
WHERE quantity=(
    SELECT MAX(quantity)
    FROM item i2
    WHERE i1.recipe_id=i2.recipe_id --Corre
);
-- 5. Identificadores de ingredientes que aparecen en más de la mitad de las recetas.

SELECT @x:=COUNT(*)*0,5
FROM recipe;

SELECT ingredient_id, COUNT(*)
FROM item
GROUP BY ingredient_id
HAVING COUNT(*)>=@x;