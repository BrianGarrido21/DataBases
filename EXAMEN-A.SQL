-- Examen de consultas SQL, 1º DAW,	2ª Evaluación 		21/03/23

-- Apellidos, nombre: 


-- 1. Para cada ingrediente (que salgan todos), todos sus datos junto con el
-- número de recetas en las que aparece y el promedio de cantidad (sin valores
-- nulos que se sustituyen por ceros).

SELECT i,*, COUNT(it.ingredient_id),IFNULL(AVG(quantity),2)
FROM ingredient i LEFT JOIN item it
ON i.ingredient_id=it.ingredient_id
GROUP BY i.ingredient_id, i.description, i.price, i.calories, i.stock;

-- 2. De los ingredientes del gazpacho, su descripción, cantidad en gramos,
-- calorías por 100 gramos y calorías totales.

SELECT i.description, it.quantity, i.calories, i.quantity/100*i.calories
FROM ingredient i, item it
WHERE i.ingredient_id=it.ingredient_id
AND it.recipe_id=(
    SELECT recipe_id
    FROM recipe
    WHERE description='Gazpacho'
);

-- 3. Suma de importe de una ración de gazpacho. Ojo que la cantidad está en 
-- gramos y el precio en euros por kilo.


SELECT SUM(it.quantity*i.price/1000)
FROM ingredient i, item it
WHERE i.ingredient_id=it.ingredient_id
AND it.recipe_id=(
    SELECT recipe_id
    FROM recipe
    WHERE description='Gazpacho'
);

-- 4. De la receta con identificador 5, porcentaje de calorías que aporta el 
-- ingrediente de identificador 17. 
SELECT @x:=SUM(i.calories*it.quantity/100)
FROM ingredient i, item it
WHERE i.ingredient_id=it.ingredient_id
AND it.recipe_id= 5;


SELECT @y:=i.calories*it.quantity
FROM ingredient i, item it
WHERE i.ingredient_id=it.ingredient_id
AND it.recipe_id= 5 AND i.ingredient_id=17;

SELECT @x/@y *100;

-- 5. Todos los datos de los ingredientes comunes a la paella y al gazpacho. 
-- Es decir, ingredientes que aparecen tanto en una como en otra receta.

SELECT *
FROM ingredient
WHERE ingredient_id IN(
    SELECT ingredient_id
    FROM item
    WHERE recipe_id=(
        SELECT recipe_id
        FROM recipe
        WHERE description="Paella"
    )
)
AND IN(
     SELECT ingredient_id
    FROM item
    WHERE recipe_id=(
        SELECT recipe_id
        FROM recipe
        WHERE description="Gazpacho"
    )
);