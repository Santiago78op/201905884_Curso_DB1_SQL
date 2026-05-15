-- ============================================================
-- C16 · SELECT básico — consultar los datos
-- Curso: SQL con PostgreSQL — TiendaLatam
-- (Asume que los CSVs ya están importados en tiendalatam)
-- ============================================================

-- Preparar datos de ejemplo
CREATE TABLE IF NOT EXISTS paises (
    pais_id INTEGER PRIMARY KEY,
    nombre  TEXT NOT NULL,
    codigo  VARCHAR(3) NOT NULL
);

CREATE TABLE IF NOT EXISTS clientes (
    cliente_id INTEGER PRIMARY KEY,
    nombre     TEXT NOT NULL,
    email      VARCHAR(100),
    activo     BOOLEAN,
    telefono   VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS productos (
    producto_id INTEGER PRIMARY KEY,
    nombre      TEXT NOT NULL,
    precio      NUMERIC(12,2),
    stock       INTEGER
);

-- Insertar datos de ejemplo
INSERT INTO paises (pais_id, nombre, codigo) VALUES
    (1, 'Chile', 'CHL'),
    (2, 'Argentina', 'ARG'),
    (3, 'Colombia', 'COL');

INSERT INTO clientes (cliente_id, nombre, email, activo, telefono) VALUES
    (1, 'María González', 'maria@gmail.com', TRUE, '9123456789'),
    (2, 'Carlos Rodríguez', 'carlos@hotmail.com', TRUE, NULL),
    (3, 'Ana Martínez', 'ana@empresa.com', FALSE, '9187654321'),
    (4, 'Luis Vargas', 'luis@gmail.com', TRUE, '9156789123');

INSERT INTO productos (producto_id, nombre, precio, stock) VALUES
    (1, 'Laptop Dell', 899.99, 5),
    (2, 'Mouse Logitech', 25.50, 150),
    (3, 'Teclado Mecánico', 125.00, 8),
    (4, 'Monitor Samsung', 299.99, 3);

-- SELECT básico: todas las columnas
SELECT * FROM clientes LIMIT 10;

-- SELECT con columnas específicas
SELECT nombre, email, activo
FROM clientes
LIMIT 10;

-- WHERE: filtrar por condición simple
SELECT nombre, email
FROM clientes
WHERE activo = TRUE;

-- WHERE con comparadores numéricos
SELECT nombre, precio
FROM productos
WHERE precio > 100;

-- WHERE con rango: BETWEEN
SELECT nombre, precio
FROM productos
WHERE precio BETWEEN 50 AND 200;

-- WHERE con lista: IN
SELECT nombre, codigo
FROM paises
WHERE codigo IN ('CHL', 'ARG', 'COL');

-- WHERE con texto: LIKE (% = cualquier secuencia, _ = un carácter)
SELECT nombre, email
FROM clientes
WHERE nombre LIKE 'Mar%';

SELECT nombre
FROM clientes
WHERE email LIKE '%@gmail.com';

-- IS NULL / IS NOT NULL
SELECT nombre, telefono
FROM clientes
WHERE telefono IS NULL;

-- AND / OR: combinar condiciones
SELECT nombre, precio, stock
FROM productos
WHERE precio > 50 AND stock > 0;

SELECT nombre, codigo
FROM paises
WHERE codigo = 'CHL' OR codigo = 'ARG';

-- NOT
SELECT nombre, activo
FROM clientes
WHERE NOT activo = FALSE;

-- ORDER BY: ordenar resultados
SELECT nombre, precio
FROM productos
ORDER BY precio DESC
LIMIT 10;

-- Alias con AS
SELECT nombre AS cliente,
       email  AS correo,
       activo AS esta_activo
FROM clientes
LIMIT 5;

-- Limpieza
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS paises;
