-- ============================================================
-- C22 · GROUP BY y funciones de agregación
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- COUNT básico: cuántos clientes hay
SELECT COUNT(*) AS total_clientes FROM clientes;

-- COUNT filtrando NULLs
SELECT
    COUNT(*) AS total_clientes,
    COUNT(telefono) AS con_telefono
FROM clientes;

-- GROUP BY básico: pedidos por cliente
SELECT cliente_id, COUNT(*) AS cantidad_pedidos
FROM pedidos
GROUP BY cliente_id
ORDER BY cantidad_pedidos DESC
LIMIT 10;

-- SUM: total de ventas por categoría
SELECT
    c.nombre AS categoria,
    SUM(dp.cantidad * dp.precio_unit) AS total_vendido
FROM detalle_pedidos dp
JOIN productos p  ON dp.producto_id = p.producto_id
JOIN categorias c ON p.categoria_id = c.categoria_id
GROUP BY c.categoria_id, c.nombre
ORDER BY total_vendido DESC;

-- AVG, MAX, MIN: estadísticas de precios
SELECT
    c.nombre AS categoria,
    AVG(p.precio)  AS precio_promedio,
    MAX(p.precio)  AS precio_maximo,
    MIN(p.precio)  AS precio_minimo,
    COUNT(*)       AS cantidad_productos
FROM productos p
JOIN categorias c ON p.categoria_id = c.categoria_id
GROUP BY c.categoria_id, c.nombre
ORDER BY precio_promedio DESC;

-- GROUP BY con fechas: pedidos por mes
SELECT
    EXTRACT(YEAR  FROM fecha) AS anio,
    EXTRACT(MONTH FROM fecha) AS mes,
    COUNT(*) AS pedidos_en_mes
FROM pedidos
GROUP BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)
ORDER BY anio, mes;

-- GROUP BY múltiple: ventas por país y categoría
SELECT
    pa.nombre AS pais,
    ca.nombre AS categoria,
    COUNT(p.pedido_id) AS total_pedidos
FROM pedidos p
JOIN sucursales s   ON p.sucursal_id = s.sucursal_id
JOIN paises pa      ON s.pais_id = pa.pais_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
JOIN productos pr   ON dp.producto_id = pr.producto_id
JOIN categorias ca  ON pr.categoria_id = ca.categoria_id
GROUP BY pa.pais_id, pa.nombre, ca.categoria_id, ca.nombre
ORDER BY pais, total_pedidos DESC;
