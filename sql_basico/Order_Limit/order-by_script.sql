-- ============================================================
-- C20 · ORDER BY, LIMIT y paginación
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- ORDER BY básico: ascendente (por defecto)
SELECT nombre, precio
FROM productos
ORDER BY precio;

-- ORDER BY descendente
SELECT nombre, precio
FROM productos
ORDER BY precio DESC;

-- ORDER BY múltiples columnas
SELECT nombre, categoria_id, precio
FROM productos
ORDER BY categoria_id ASC, precio DESC;

-- LIMIT: los primeros N resultados
-- Equivale a TOP N de SQL Server, pero va al FINAL de la query
SELECT nombre, precio
FROM productos
ORDER BY precio DESC
LIMIT 5;

-- Los 3 pedidos más recientes
SELECT pedido_id, cliente_id, fecha
FROM pedidos
ORDER BY fecha DESC
LIMIT 3;

-- LIMIT + OFFSET: paginación
-- Página 1: filas 1 a 10
SELECT nombre, precio
FROM productos
ORDER BY nombre
LIMIT 10 OFFSET 0;

-- Página 2: filas 11 a 20
SELECT nombre, precio
FROM productos
ORDER BY nombre
LIMIT 10 OFFSET 10;

-- Página 3: filas 21 a 30
SELECT nombre, precio
FROM productos
ORDER BY nombre
LIMIT 10 OFFSET 20;

-- Fórmula general: OFFSET = (pagina - 1) * tamaño_pagina

-- ORDER BY con NULLs
-- Por defecto en PG: NULLs van al FINAL en ASC, al INICIO en DESC
SELECT nombre, telefono
FROM clientes
ORDER BY telefono ASC NULLS LAST;

SELECT nombre, telefono
FROM clientes
ORDER BY telefono DESC NULLS LAST;

-- Combinación práctica: top 10 productos más vendidos
SELECT
    pr.nombre,
    SUM(dp.cantidad) AS total_vendido
FROM productos pr
JOIN detalle_pedidos dp ON pr.producto_id = dp.producto_id
GROUP BY pr.producto_id, pr.nombre
ORDER BY total_vendido DESC
LIMIT 10;
