-- ============================================================
-- C12 · Claves foráneas e integridad referencial
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- Primero las tablas PADRE (sin FK)
CREATE TABLE paises (
    pais_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre   TEXT NOT NULL UNIQUE,
    codigo   VARCHAR(3) NOT NULL UNIQUE
);

CREATE TABLE categorias (
    categoria_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       TEXT NOT NULL UNIQUE
);

CREATE TABLE tipos_cliente (
    tipo_cliente_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          TEXT NOT NULL UNIQUE
);

-- Luego las tablas HIJA (con FK)
CREATE TABLE sucursales (
    sucursal_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      TEXT    NOT NULL,
    ciudad      TEXT    NOT NULL,
    pais_id     INTEGER NOT NULL REFERENCES paises(pais_id)
);

CREATE TABLE clientes (
    cliente_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          TEXT        NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    activo          BOOLEAN     NOT NULL DEFAULT TRUE,
    tipo_cliente_id INTEGER     NOT NULL REFERENCES tipos_cliente(tipo_cliente_id)
);

CREATE TABLE productos (
    producto_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       TEXT          NOT NULL,
    precio       NUMERIC(10,2) NOT NULL,
    categoria_id INTEGER       NOT NULL REFERENCES categorias(categoria_id)
);

CREATE TABLE empleados (
    empleado_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      TEXT    NOT NULL,
    cargo       TEXT,
    sucursal_id INTEGER NOT NULL REFERENCES sucursales(sucursal_id)
);

-- Tabla con múltiples FK
CREATE TABLE pedidos (
    pedido_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha       DATE    NOT NULL DEFAULT CURRENT_DATE,
    cliente_id  INTEGER NOT NULL REFERENCES clientes(cliente_id),
    sucursal_id INTEGER NOT NULL REFERENCES sucursales(sucursal_id),
    empleado_id INTEGER REFERENCES empleados(empleado_id)
);

-- Tabla intermedia N:M con FK compuesta
CREATE TABLE detalle_pedidos (
    detalle_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pedido_id   INTEGER       NOT NULL REFERENCES pedidos(pedido_id),
    producto_id INTEGER       NOT NULL REFERENCES productos(producto_id),
    cantidad    INTEGER       NOT NULL DEFAULT 1,
    precio_unit NUMERIC(10,2) NOT NULL
);

-- Ver todas las FK definidas en el schema
SELECT
    tc.table_name         AS tabla,
    kcu.column_name       AS columna,
    ccu.table_name        AS tabla_referenciada,
    ccu.column_name       AS columna_referenciada
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name;

-- Limpieza
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS empleados;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS sucursales;
DROP TABLE IF EXISTS tipos_cliente;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS paises;
