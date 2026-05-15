-- ============================================================
-- C23 · HAVING: filtrar grupos
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- HAVING básico: categorías con más de 5 productos
SELECT
    c.nombre AS categoria,
    COUNT(*) AS cantidad_productos
FROM productos p
JOIN categorias c ON p.categoria_id = c.categoria_id
GROUP BY c.categoria_id, c.nombre
HAVING COUNT(*) > 5
ORDER BY cantidad_productos DESC;

-- HAVING con SUM: países con más de $50,000 en ventas
SELECT
    pa.nombre AS pais,
    SUM(dp.cantidad * dp.precio_unit) AS total_ventas
FROM pedidos p
JOIN sucursales s       ON p.sucursal_id = s.sucursal_id
JOIN paises pa          ON s.pais_id = pa.pais_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
GROUP BY pa.pais_id, pa.nombre
HAVING SUM(dp.cantidad * dp.precio_unit) > 50000
ORDER BY total_ventas DESC;

-- HAVING con AVG: clientes con ticket promedio alto
SELECT
    c.nombre AS cliente,
    COUNT(p.pedido_id) AS pedidos,
    AVG(dp.cantidad * dp.precio_unit) AS ticket_promedio
FROM clientes c
JOIN pedidos p          ON c.cliente_id = p.cliente_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
GROUP BY c.cliente_id, c.nombre
HAVING AVG(dp.cantidad * dp.precio_unit) > 100
ORDER BY ticket_promedio DESC;

-- WHERE + HAVING: solo pedidos de 2024, grupos con más de 3 pedidos
SELECT
    cliente_id,
    COUNT(*) AS pedidos_2024
FROM pedidos
WHERE EXTRACT(YEAR FROM fecha) = 2024
GROUP BY cliente_id
HAVING COUNT(*) > 3
ORDER BY pedidos_2024 DESC;

-- Sin HAVING (para comparar)
SELECT
    c.nombre AS categoria,
    COUNT(*) AS total_productos
FROM productos p
JOIN categorias c ON p.categoria_id = c.categoria_id
GROUP BY c.categoria_id, c.nombre
ORDER BY total_productos DESC;

-- Con HAVING (filtrar solo los que tienen más de 3)
SELECT
    c.nombre AS categoria,
    COUNT(*) AS total_productos
FROM productos p
JOIN categorias c ON p.categoria_id = c.categoria_id
GROUP BY c.categoria_id, c.nombre
HAVING COUNT(*) > 3
ORDER BY total_productos DESC;
