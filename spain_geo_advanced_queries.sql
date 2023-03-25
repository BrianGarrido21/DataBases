-- 1. Suma de población de Andalucía

SELECT SUM(population)
FROM provinces
WHERE aut_region_id = (
	SELECT aut_region_id
	FROM aut_regions
	WHERE name='Andalucía'
);

-- 2. Provincias costeras de Andalucía

SELECT *
FROM provinces
WHERE aut_region_id = (
	SELECT aut_region_id
	FROM aut_regions
	WHERE name='Andalucía'
) 
AND coast;

-- 3. Provincias andaluzas con población comprendida
-- entre 500000 y 600000 habitantes

SELECT *
FROM provinces
WHERE aut_region_id = (
	SELECT aut_region_id
	FROM aut_regions
	WHERE name='Andalucía'
) 
AND population BETWEEN 50000 AND 600000;

-- 4. Número de provincias por las que atraviesa el Ebro

SELECT COUNT(*)
FROM pro_riv
WHERE river_id = (
	SELECT river_id
	FROM rivers
	WHERE name='Ebro'
);

-- 5. Todos los datos de provincias por las que atraviesa el Ebro

SELECT *
FROM provinces
WHERE province_id IN (
	SELECT province_id
	FROM pro_riv
	WHERE river_id = (
		SELECT river_id
		FROM rivers
		WHERE name='Ebro'
	)
);

-- 6. Ríos que no pasan por Andalucía

SELECT *
FROM rivers
WHERE river_id NOT IN (
	SELECT river_id
	FROM pro_riv
	WHERE province_id IN (
		SELECT province_id
		FROM provinces
		WHERE aut_region_id IN (
			SELECT aut_region_id
			FROM aut_regions
			WHERE name='Andalucía'
		)
	)
);

-- 7. Número de provincias y de comunidades por las que atraviesa el Ebro

SELECT COUNT(*) AS num_provinces,
COUNT(DISTINCT aut_region_id) AS num_regions
FROM provinces
WHERE province_id IN (
	SELECT province_id
	FROM pro_riv
	WHERE river_id = (
		SELECT river_id
		FROM rivers
		WHERE name='Ebro'
	)
);

-- 8. Ríos más largos que el Guadalquivir

SELECT *
FROM rivers
WHERE river_length > (
	SELECT river_length
	FROM rivers
	WHERE name='Guadalquivir'
);

-- 9. Provincias con menos población que Huelva

SELECT *
FROM provinces
WHERE population > (
	SELECT population
	FROM provinces
	WHERE name='Huelva'
);

-- 10. Autonomías con más población que Galicia

SELECT a.*, SUM(p.population)
FROM aut_regions a, provinces p
WHERE a.aut_region_id=p.aut_region_id
GROUP BY a.aut_region_id, a.name
HAVING SUM(p.population) > (
	SELECT SUM(population)
	FROM provinces p
	WHERE aut_region_id=(
		SELECT aut_region_id
		FROM aut_regions
		WHERE name='Galicia'
	)
);

-- 11. Ríos aragoneses que desemboquen en el Mediterráneo

SELECT *
FROM rivers
WHERE sea='Mediterráneo'
AND river_id IN (
	SELECT river_id
	FROM pro_riv
	WHERE province_id IN (
		SELECT province_id
		FROM provinces
		WHERE aut_region_id = (
			SELECT aut_region_id
			FROM aut_regions
			WHERE name='Aragón'
		)
	)
);

-- 12. Ríos que nacen en Jaén y desembocan en el Atlántico

SELECT *
FROM rivers
WHERE sea='Atlántico'
AND river_id IN (
	SELECT river_id
	FROM pro_riv
	WHERE river_order=1 AND province_id = (
		SELECT province_id
		FROM provinces
		WHERE name='Jaén'
	)
);

-- 13. Número de ríos que nacen en Jaén

SELECT COUNT(DISTINCT river_id)
FROM pro_riv
WHERE river_order=1 AND province_id = (
	SELECT province_id
	FROM provinces
	WHERE name='Jaén'
);

-- 14. Densidad de población de Cataluña

SELECT SUM(population)/SUM(surface)
FROM provinces
WHERE aut_region_id=(
	SELECT aut_region_id
	FROM aut_regions
	WHERE name='Cataluña'
);

-- 15. Número de ríos en Andalucía

SELECT COUNT(DISTINCT river_id)
FROM pro_riv
WHERE province_id IN (
	SELECT province_id
	FROM provinces
	WHERE aut_region_id IN (
		SELECT aut_region_id
		FROM aut_regions
		WHERE name='Andalucía'
	)
);

-- 16. Todos los datos de los ríos de Andalucía

SELECT *
FROM rivers
WHERE river_id IN (
	SELECT river_id
	FROM pro_riv
	WHERE province_id IN (
		SELECT province_id
		FROM provinces
		WHERE aut_region_id IN (
			SELECT aut_region_id
			FROM aut_regions
			WHERE name='Andalucía'
		)
	)
);

-- 17. Todos los datos de la región más grande

SELECT a.*, SUM(surface)
FROM aut_regions a, provinces p
WHERE a.aut_region_id=p.aut_region_id
GROUP BY a.aut_region_id, a.name
HAVING SUM(surface) >= ALL (
	SELECT SUM(surface)
	FROM provinces
	GROUP BY aut_region_id
);

-- 18. Todos los datos de la región con más ríos

SELECT a.*, COUNT(DISTINCT pr.river_id)
FROM aut_regions a, provinces p, pro_riv pr
WHERE a.aut_region_id=p.aut_region_id
AND p.province_id=pr.province_id
GROUP BY a.aut_region_id, a.name
HAVING COUNT(DISTINCT pr.river_id) >= ALL (
	SELECT COUNT(DISTINCT pr.river_id)
	FROM provinces p, pro_riv pr
	WHERE p.province_id=pr.province_id
	GROUP BY p.aut_region_id
);

-- 19. Para cada mar, el río más largo

SELECT * 
FROM rivers r1
WHERE river_length >= ALL (
	SELECT river_length
	FROM rivers r2
	WHERE r1.sea=r2.sea -- Subconsulta correlacionada
);

-- 20. Para cada identificador de región, el río más largo

SELECT DISTINCT p1.aut_region_id, r1.* 
FROM rivers r1, pro_riv pr1, provinces p1
WHERE r1.river_id=pr1.river_id AND pr1.province_id=p1.province_id 
AND r1.river_length >= ALL (
	SELECT r2.river_length
	FROM rivers r2, pro_riv pr2, provinces p2
	WHERE r2.river_id=pr2.river_id AND pr2.province_id=p2.province_id 
	AND p1.aut_region_id=p2.aut_region_id -- Subconsulta correlacionada
)
ORDER BY 1;

-- 21. Añadir a lo anterior el nombre de la región

SELECT DISTINCT p1.aut_region_id, a1.name, r1.* 
FROM rivers r1, pro_riv pr1, provinces p1, aut_regions a1
WHERE r1.river_id=pr1.river_id AND pr1.province_id=p1.province_id
AND p1.aut_region_id=a1.aut_region_id 
AND r1.river_length >= ALL (
	SELECT r2.river_length
	FROM rivers r2, pro_riv pr2, provinces p2
	WHERE r2.river_id=pr2.river_id AND pr2.province_id=p2.province_id 
	AND p1.aut_region_id=p2.aut_region_id -- Subconsulta correlacionada
)
ORDER BY 1;

-- 22. Para cada identificador de región, la 
-- provincia más poblada

SELECT *
FROM provinces p1
WHERE population >= ALL (
	SELECT population
	FROM provinces p2
	WHERE p1.aut_region_id=p2.aut_region_id -- Correlacionada
);

-- 23. Añadir a lo anterior el nombre de la región

SELECT a1.name, p1.*
FROM aut_regions a1, provinces p1
WHERE a1.aut_region_id=p1.aut_region_id
AND population >= ALL (
	SELECT population
	FROM provinces p2
	WHERE p1.aut_region_id=p2.aut_region_id -- Correlacionada
);

-- 24. Porcentaje de población de Huelva respecto a España
-- Subconsulta en SELECT

SELECT population/(
	SELECT SUM(population)
	FROM provinces
) * 100
FROM provinces
WHERE name='Huelva';

-- 25. Porcentaje de población de Huelva respecto a Andalucía

SELECT population/(
	SELECT SUM(population)
	FROM provinces
	WHERE aut_region_id = (
		SELECT aut_region_id
		FROM aut_regions
		WHERE name='Andalucía'
	)
) * 100
FROM provinces
WHERE name='Huelva';

-- 26. Porcentaje de población de Andalucía respecto a España

-- SELECT (<población Andalucía>) / (<población España>) * 100;

SELECT SUM(population)
FROM provinces
WHERE aut_region_id = (
	SELECT aut_region_id
	FROM aut_regions
	WHERE name='Andalucía'
);

-- Resultado 8384686

SELECT SUM(population)
FROM provinces;

-- Resultado 45210755

SELECT 8384686/45210755*100;

-- Todo junto en una consulta con dos subconsultas en SELECT

SELECT (
	SELECT SUM(population)
	FROM provinces
	WHERE aut_region_id = (
		SELECT aut_region_id
		FROM aut_regions
		WHERE name='Andalucía'
	)
)
/
(
	SELECT SUM(population)
	FROM provinces
) * 100;

-- 27. Para cada región, todos sus datos y el porcentaje de
-- superficie respecto a España

SELECT a.*, SUM(surface) / (
	SELECT SUM(surface)
	FROM provinces
) *100
FROM aut_regions a, provinces p
WHERE a.aut_region_id=p.aut_region_id
GROUP BY a.aut_region_id, a.name;

-- 28. Para cada provincia (que salgan todas), todos sus
-- datos y número de ríos

SELECT p.*, COUNT(pr.river_id)
FROM provinces p LEFT JOIN pro_riv pr
ON p.province_id=pr.province_id
GROUP BY p.province_id, p.name, p.capital, p.surface, p.population

-- 29. Para cada región  (que salgan todas), todos sus
-- datos, número de provincias y número de ríos

SELECT a.*, 
COUNT(DISTINCT p.province_id) AS num_provinces,
COUNT(DISTINCT pr.river_id) AS num_rivers
FROM aut_regions a 
LEFT JOIN provinces p
ON a.aut_region_id=p.aut_region_id
LEFT JOIN pro_riv pr
ON p.province_id=pr.province_id
GROUP BY a.aut_region_id, a.name;