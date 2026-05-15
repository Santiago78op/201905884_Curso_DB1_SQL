-- ============================================================
-- C17 · UPDATE: modificar datos existentes
-- Curso: SQL con PostgreSQL — TiendaLatam
-- REGLA DE ORO: siempre usar WHERE en el UPDATE
-- ============================================================

-- Preparar datos de ejemplo
CREATE TABLE IF NOT EXISTS clientes (
    cliente_id INTEGER PRIMARY KEY,
    nombre     TEXT NOT NULL,
    email      VARCHAR(100),
    activo     BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS productos (
    producto_id INTEGER PRIMARY KEY,
    nombre      TEXT NOT NULL,
    precio      NUMERIC(12,2),
    stock       INTEGER,
    categoria_id INTEGER
);

INSERT INTO clientes (cliente_id, nombre, email, activo) VALUES
    (1, 'María González', 'maria@email.cl', TRUE),
    (2, 'Carlos Rodríguez', 'carlos@email.cl', TRUE),
    (3, 'Ana Martínez', 'ana@email.ar', TRUE);

INSERT INTO productos (producto_id, nombre, precio, stock, categoria_id) VALUES
    (1, 'Laptop', 899.99, 5, 1),
    (2, 'Mouse', 25.50, 150, 1),
    (3, 'Teclado', 125.00, 8, 1),
    (4, 'Monitor', 299.99, 3, 1);

-- Ver datos antes del UPDATE
SELECT cliente_id, nombre, email, activo
FROM clientes
WHERE cliente_id = 1;

-- UPDATE básico: modificar una columna
UPDATE clientes
SET activo = FALSE
WHERE cliente_id = 1;

-- Verificar el cambio
SELECT cliente_id, nombre, activo FROM clientes WHERE cliente_id = 1;

-- UPDATE con múltiples columnas
UPDATE clientes
SET nombre  = 'María González Reyes',
    activo  = TRUE
WHERE cliente_id = 1;

-- UPDATE con RETURNING — ver qué cambió
UPDATE productos
SET precio = precio * 1.10
WHERE categoria_id = 1
RETURNING producto_id, nombre, precio;

-- UPDATE con subquery
CREATE TABLE IF NOT EXISTS detalle_pedidos (
    detalle_id INTEGER PRIMARY KEY,
    producto_id INTEGER,
    cantidad INTEGER
);

INSERT INTO detalle_pedidos (detalle_id, producto_id, cantidad) VALUES
    (1, 1, 2),
    (2, 2, 5);

UPDATE productos
SET stock = stock - 1
WHERE producto_id IN (
    SELECT producto_id
    FROM detalle_pedidos
    WHERE detalle_id = 1
);

-- UPDATE con condición calculada
CREATE TABLE IF NOT EXISTS pedidos (
    pedido_id INTEGER PRIMARY KEY,
    cliente_id INTEGER,
    fecha DATE
);

INSERT INTO pedidos (pedido_id, cliente_id, fecha) VALUES
    (1, 1, '2023-01-15'),
    (2, 2, '2020-06-01');

UPDATE clientes
SET activo = FALSE
WHERE cliente_id IN (
    SELECT cliente_id
    FROM pedidos
    GROUP BY cliente_id
    HAVING MAX(fecha) < NOW() - INTERVAL '2 years'
);

-- UPDATE seguro con CTE (forma avanzada)
WITH clientes_a_activar AS (
    SELECT cliente_id FROM clientes WHERE email LIKE '%@email.cl'
)
UPDATE clientes
SET activo = TRUE
WHERE cliente_id IN (SELECT cliente_id FROM clientes_a_activar)
RETURNING cliente_id, nombre, activo;

-- Limpieza
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS productos;
