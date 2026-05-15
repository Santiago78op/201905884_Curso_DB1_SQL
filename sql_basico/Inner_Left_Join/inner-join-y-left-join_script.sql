-- ============================================================
-- C24 · INNER JOIN y LEFT JOIN
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- INNER JOIN básico: pedidos con nombre de cliente
SELECT
    p.pedido_id,
    c.nombre AS cliente,
    p.fecha
FROM pedidos p
INNER JOIN clientes c ON p.cliente_id = c.cliente_id
ORDER BY p.fecha DESC
LIMIT 10;

-- INNER JOIN múltiple: pedido completo con sucursal y país
SELECT
    p.pedido_id,
    c.nombre        AS cliente,
    s.nombre        AS sucursal,
    pa.nombre       AS pais,
    p.fecha
FROM pedidos p
INNER JOIN clientes c   ON p.cliente_id = c.cliente_id
INNER JOIN sucursales s ON p.sucursal_id = s.sucursal_id
INNER JOIN paises pa    ON s.pais_id = pa.pais_id
ORDER BY p.fecha DESC
LIMIT 10;

-- INNER JOIN con detalle: líneas de un pedido específico
SELECT
    dp.pedido_id,
    pr.nombre       AS producto,
    ca.nombre       AS categoria,
    dp.cantidad,
    dp.precio_unit,
    (dp.cantidad * dp.precio_unit) AS subtotal
FROM detalle_pedidos dp
INNER JOIN productos pr  ON dp.producto_id = pr.producto_id
INNER JOIN categorias ca ON pr.categoria_id = ca.categoria_id
WHERE dp.pedido_id = 1;

-- LEFT JOIN: todos los clientes, hayan comprado o no
SELECT
    c.nombre AS cliente,
    COUNT(p.pedido_id) AS cantidad_pedidos
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
GROUP BY c.cliente_id, c.nombre
ORDER BY cantidad_pedidos DESC;

-- LEFT JOIN: identificar clientes sin pedidos
SELECT
    c.nombre AS cliente,
    c.email
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
WHERE p.pedido_id IS NULL
ORDER BY c.nombre;

-- INNER JOIN con GROUP BY: resumen de ventas por categoría
SELECT
    ca.nombre AS categoria,
    COUNT(DISTINCT p.pedido_id)         AS pedidos,
    SUM(dp.cantidad)                    AS unidades,
    SUM(dp.cantidad * dp.precio_unit)   AS total_ventas
FROM detalle_pedidos dp
INNER JOIN productos pr  ON dp.producto_id = pr.producto_id
INNER JOIN categorias ca ON pr.categoria_id = ca.categoria_id
INNER JOIN pedidos p     ON dp.pedido_id = p.pedido_id
GROUP BY ca.categoria_id, ca.nombre
ORDER BY total_ventas DESC;

-- Alias cortos (práctica común en equipos)
SELECT
    c.nombre     AS cliente,
    s.nombre     AS sucursal,
    pa.nombre    AS pais,
    COUNT(p.pedido_id) AS pedidos
FROM pedidos p
JOIN clientes c   ON p.cliente_id   = c.cliente_id
JOIN sucursales s ON p.sucursal_id  = s.sucursal_id
JOIN paises pa    ON s.pais_id      = pa.pais_id
WHERE c.activo = TRUE
GROUP BY c.cliente_id, c.nombre, s.nombre, pa.nombre
ORDER BY pedidos DESC
LIMIT 10;
