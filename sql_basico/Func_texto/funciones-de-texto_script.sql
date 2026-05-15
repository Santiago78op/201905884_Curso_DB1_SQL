-- ============================================================
-- C21 · Funciones de texto, fecha y número
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- ===== FUNCIONES DE TEXTO =====

-- UPPER / LOWER / TRIM
SELECT UPPER('hola mundo')      AS mayusculas;
SELECT LOWER('HOLA MUNDO')      AS minusculas;
SELECT TRIM('  espacios  ')     AS sin_espacios;
SELECT LTRIM('  izquierda')     AS sin_espacio_izq;
SELECT RTRIM('derecha  ')       AS sin_espacio_der;

-- LENGTH (equivale a LEN de SQL Server)
SELECT nombre, LENGTH(nombre) AS largo_nombre
FROM clientes
LIMIT 5;

-- CONCAT y operador ||
SELECT nombre || ' — ' || email AS info_cliente
FROM clientes
LIMIT 5;

-- SUBSTRING
SELECT SUBSTRING('PostgreSQL' FROM 1 FOR 8) AS parte;   -- 'Postgre'
SELECT LEFT('PostgreSQL', 4)  AS primeros;               -- 'Post'
SELECT RIGHT('PostgreSQL', 3) AS ultimos;                -- 'SQL'

-- REPLACE
SELECT REPLACE(email, '@', ' [arroba] ') AS email_seguro
FROM clientes
LIMIT 3;

-- ===== FUNCIONES DE FECHA =====

-- Fecha y hora actual
SELECT NOW()          AS ahora;
SELECT CURRENT_DATE   AS solo_fecha;
SELECT CURRENT_TIME   AS solo_hora;

-- EXTRACT: obtener partes de una fecha (equivale a YEAR/MONTH/DAY de SQL Server)
SELECT fecha,
       EXTRACT(YEAR  FROM fecha) AS anio,
       EXTRACT(MONTH FROM fecha) AS mes,
       EXTRACT(DAY   FROM fecha) AS dia
FROM pedidos
LIMIT 5;

-- Aritmética de fechas con INTERVAL (más natural que DATEADD)
SELECT CURRENT_DATE + INTERVAL '30 days'  AS en_un_mes;
SELECT CURRENT_DATE - INTERVAL '1 year'   AS hace_un_anio;
SELECT NOW() + INTERVAL '2 hours'         AS en_dos_horas;

-- Diferencia entre fechas (directa, sin función — equivale a DATEDIFF)
SELECT NOW()::DATE - fecha::DATE AS dias_desde_pedido
FROM pedidos
LIMIT 5;

-- TO_CHAR: formatear fecha (equivale a FORMAT de SQL Server)
SELECT TO_CHAR(fecha, 'DD/MM/YYYY')          AS fecha_formato_cl
FROM pedidos LIMIT 3;

SELECT TO_CHAR(NOW(), 'DD "de" Month YYYY')  AS fecha_larga;
SELECT TO_CHAR(NOW(), 'HH24:MI:SS')          AS hora_formato;

-- ===== FUNCIONES DE NÚMERO =====

-- Redondeo
SELECT ROUND(1234.5678, 2)  AS redondeado;    -- 1234.57
SELECT CEIL(4.1)            AS hacia_arriba;  -- 5
SELECT FLOOR(4.9)           AS hacia_abajo;   -- 4
SELECT ABS(-42)             AS absoluto;      -- 42

-- TO_CHAR para formato monetario
SELECT TO_CHAR(precio, 'FM$999,999.00') AS precio_formato
FROM productos
LIMIT 5;

-- ===== COALESCE — manejar NULLs =====
-- Equivale a ISNULL(x, y) de SQL Server

SELECT nombre,
       COALESCE(telefono, 'Sin teléfono') AS contacto
FROM clientes
LIMIT 10;

-- COALESCE con múltiples alternativas
SELECT nombre,
       COALESCE(telefono, email, 'Sin contacto') AS contacto_preferido
FROM clientes
LIMIT 10;

-- Aplicación práctica: resumen de pedido con formato
SELECT
    p.pedido_id,
    TO_CHAR(p.fecha, 'DD/MM/YYYY') AS fecha_formato,
    c.nombre AS cliente,
    TO_CHAR(SUM(dp.cantidad * dp.precio_unit), 'FM$999,999.00') AS total
FROM pedidos p
JOIN clientes c     ON p.cliente_id = c.cliente_id
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
GROUP BY p.pedido_id, p.fecha, c.nombre
ORDER BY p.fecha DESC
LIMIT 5;
