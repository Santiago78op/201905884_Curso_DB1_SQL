-- ============================================================
-- C11 · CREATE TABLE: claves primarias y restricciones
-- Curso: SQL con PostgreSQL — TiendaLatam
-- Ejecutar en: tiendalatam > public
-- ============================================================

-- Forma 1: SERIAL (clásica, muy usada)
CREATE TABLE ejemplo_serial (
    id      SERIAL PRIMARY KEY,
    nombre  TEXT NOT NULL
);

-- Forma 2: GENERATED ALWAYS AS IDENTITY (estándar moderno — recomendado)
CREATE TABLE ejemplo_identity (
    id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  TEXT NOT NULL
);

-- Tabla completa: clientes de TiendaLatam
CREATE TABLE clientes (
    cliente_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          TEXT        NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    telefono        VARCHAR(20),
    fecha_registro  DATE        NOT NULL DEFAULT CURRENT_DATE,
    activo          BOOLEAN     NOT NULL DEFAULT TRUE,
    tipo_cliente_id INTEGER     NOT NULL
);

-- Tabla: categorias
CREATE TABLE categorias (
    categoria_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        TEXT NOT NULL UNIQUE,
    descripcion   TEXT
);

-- Tabla: productos
CREATE TABLE productos (
    producto_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre       TEXT           NOT NULL,
    descripcion  TEXT,
    precio       NUMERIC(10,2)  NOT NULL,
    stock        INTEGER        NOT NULL DEFAULT 0,
    categoria_id INTEGER        NOT NULL
);

-- Verificar tablas creadas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Ver estructura de una tabla
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'clientes'
ORDER BY ordinal_position;

-- Limpiar para próximos ejemplos (en orden por FK)
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS ejemplo_serial;
DROP TABLE IF EXISTS ejemplo_identity;
