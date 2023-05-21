-- 1. Función que devuelve el número de facturas del cliente que se 
-- pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS count_invoices//
CREATE FUNCTION count_invoices(par_client_id INT(5))
RETURNS INT
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM invoice
		WHERE client_id=par_client_id
	);
END//
DELIMITER ;

-- 2. Probar la función anterior con todos los clientes

SELECT *, count_invoices(client_id)
FROM client;

-- 3. Todos los datos del cliente con más facturas

SELECT *, count_invoices(client_id)
FROM client
WHERE count_invoices(client_id) >= ALL (
	SELECT count_invoices(client_id)
	FROM client
);

-- 4. Función que devuelve la suma de importe de las facturas
-- del cliente que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS sum_imp_cli//
CREATE FUNCTION sum_imp_cli(par_client_id INT(5))
RETURNS DECIMAL(8,2)
BEGIN
	RETURN (
		SELECT IFNULL(SUM(iw.hours*i.price_hour),0)
		FROM item_work iw, invoice i
		WHERE iw.invoice_id=i.invoice_id
		AND i.client_id=par_client_id
	) + (
		SELECT IFNULL(SUM(ip.units*ip.price),0)
		FROM item_product ip, invoice i
		WHERE ip.invoice_id=i.invoice_id
		AND i.client_id=par_client_id
	);
END//
DELIMITER ;

-- 5. Probar la función anterior con todos los clientes

SELECT *, count_invoices(client_id) AS count_inv,
sum_imp_cli(client_id) AS sum_imp
FROM client;

-- 6. Todos los datos de clientes con más importe que la media

SELECT *, count_invoices(client_id) AS count_inv,
sum_imp_cli(client_id) AS sum_imp
FROM client
WHERE sum_imp_cli(client_id) > (
	SELECT AVG(sum_imp_cli(client_id))
	FROM client
);

-- 7. Función que devuelve el importe de una factura que
-- se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS sum_imp_inv//
CREATE FUNCTION sum_imp_inv(par_invoice_id INT(8))
RETURNS DECIMAL(8,2)
BEGIN
RETURN (
		SELECT IFNULL(SUM(iw.hours*i.price_hour),0)
		FROM item_work iw, invoice i
		WHERE iw.invoice_id=i.invoice_id
		AND i.invoice_id=par_invoice_id
	) + (
		SELECT IFNULL(SUM(units*price),0)
		FROM item_product
		WHERE invoice_id=par_invoice_id
	);
END//
DELIMITER ;

-- 8. Probar la función anterior con todas las facturas

SELECT *, sum_imp_inv(invoice_id) AS import
FROM invoice;

-- 9. La factura con el importe máximo

SELECT *, sum_imp_inv(invoice_id) AS import
FROM invoice
WHERE sum_imp_inv(invoice_id) >= ALL (
	SELECT sum_imp_inv(invoice_id)
	FROM invoice
);

-- 10. Función que devuelve la suma de unidades vendidas
-- del producto que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS sum_uni_pro//
CREATE FUNCTION sum_uni_pro(par_product_id INT(5))
RETURNS INT
BEGIN
	RETURN (
		SELECT IFNULL(SUM(units),0)
		FROM item_product
		WHERE product_id=par_product_id
	);
END//
DELIMITER ;

-- 11. Probar la función anterior con todos los productos

SELECT *, sum_uni_pro(product_id)
FROM product;

-- 12. El producto más vendido

SELECT *, sum_uni_pro(product_id)
FROM product
WHERE sum_uni_pro(product_id) >= ALL (
	SELECT sum_uni_pro(product_id)
	FROM product
);

-- 13. Función que devuelve la suma de importe facturado
-- en la fecha que se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS sum_inv_dat//
CREATE FUNCTION sum_inv_dat(par_date DATE)
RETURNS DECIMAL(8,2)
BEGIN
	RETURN (
		SELECT SUM(sum_imp_inv(invoice_id))
		FROM invoice
		WHERE invoice_date=par_date
	);
END//
DELIMITER ;

-- 14. Probar el funcionamiento con todas las fechas 
-- (sin duplicados) en las que haya facturas

SELECT DISTINCT invoice_date, sum_inv_dat(invoice_date)
FROM invoice;

-- 15. Función que devuelve la suma de importe facturado
-- del vehículo cuya matrícula se pasa como parámetro

DELIMITER //
DROP FUNCTION IF EXISTS sum_inv_veh//
CREATE FUNCTION sum_inv_veh(par_vehicle_id VARCHAR(7))
RETURNS DECIMAL(8,2)
BEGIN
	RETURN (
		SELECT IFNULL(SUM(sum_imp_inv(invoice_id)),0)
		FROM invoice
		WHERE vehicle_id=par_vehicle_id
	);
END//

-- 16. Suma de importe e iva facturado a cada vehículo

SELECT *, sum_inv_veh(vehicle_id) AS import,
ROUND(sum_inv_veh(vehicle_id)*0.21,2) AS iva
FROM vehicle;

-- 17. Función que recibe como parámetro los cuatro dígitos
-- de un año y devuelve el número siguiente de la última 
-- factura de ese año

DELIMITER //
DROP FUNCTION IF EXISTS next_invoice_id//
CREATE FUNCTION next_invoice_id(par_year INT(4))
RETURNS INT(8)
BEGIN
	RETURN (
		SELECT IFNULL(MAX(invoice_id)+1, par_year*10000+1)
		FROM invoice
		WHERE YEAR(invoice_date)=par_year
	);
END//

-- 18. Siguiente factura de los años 2019, 2020, 2021 y 2022.

SELECT next_invoice_id(2019); --> 20190009
SELECT next_invoice_id(2020); --> 20200007
SELECT next_invoice_id(2021); --> 20210003
SELECT next_invoice_id(2022); --> 20220001

-- 19. Función que devuelve el identificador del
-- producto cuya descripción se pasa como parámetro. 
-- Si el producto no se encuentra devuelve nulo.

DELIMITER //
DROP FUNCTION IF EXISTS find_product//
CREATE FUNCTION find_product(par_des VARCHAR(30))
RETURNS INT(5)
BEGIN
	RETURN (
		SELECT product_id
		FROM product
		WHERE description=par_des
	);
END//

-- 20. Identificador del producto "Oil 30W50 5 liter"

SELECT find_product('Oil 30W50 5 liter');
