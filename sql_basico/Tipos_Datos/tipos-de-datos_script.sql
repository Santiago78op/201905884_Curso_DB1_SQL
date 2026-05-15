-- ============================================================
-- C7 · Tipos de datos en PostgreSQL
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- Ejemplos de tipos de datos aplicados a TiendaLatam

-- INTEGER: identificadores, cantidades enteras
-- sucursal_id INTEGER, cliente_id INTEGER, cantidad INTEGER

-- NUMERIC(p,s): valores monetarios y decimales exactos
SELECT CAST(1500.75 AS NUMERIC(10,2)) AS precio_ejemplo;
SELECT CAST(0.15 AS NUMERIC(5,4))     AS descuento_ejemplo;

-- TEXT / VARCHAR(n): nombres, descripciones
-- nombre_cliente TEXT, email VARCHAR(100), telefono VARCHAR(20)

-- BOOLEAN: estados activo/inactivo
SELECT TRUE  AS cliente_activo;
SELECT FALSE AS sucursal_cerrada;

-- DATE: fechas sin hora
SELECT CURRENT_DATE AS fecha_hoy;
SELECT '2024-03-15'::DATE AS fecha_pedido_ejemplo;

-- TIMESTAMP: fecha y hora de eventos
SELECT NOW() AS momento_actual;
SELECT '2024-03-15 10:30:00'::TIMESTAMP AS timestamp_ejemplo;

-- Demostración: tabla ficticia mostrando todos los tipos
CREATE TABLE demo_tipos (
    id            INTEGER,
    nombre        TEXT,
    precio        NUMERIC(10,2),
    activo        BOOLEAN,
    fecha_ingreso DATE,
    creado_en     TIMESTAMP
);

-- Insertar fila de ejemplo
INSERT INTO demo_tipos VALUES (
    1,
    'Producto Demo',
    29.99,
    TRUE,
    '2024-01-01',
    NOW()
);

SELECT * FROM demo_tipos;

-- Limpiar tabla de demo
DROP TABLE IF EXISTS demo_tipos;
