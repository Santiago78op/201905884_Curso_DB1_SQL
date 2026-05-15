-- ============================================================
-- C13 · ALTER TABLE: modificar tablas en producción
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- Tabla de ejemplo
CREATE TABLE empleados_demo (
    empleado_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      TEXT    NOT NULL,
    cargo       TEXT
);

-- ADD COLUMN: agregar una columna nueva
ALTER TABLE empleados_demo
ADD COLUMN email TEXT;

ALTER TABLE empleados_demo
ADD COLUMN fecha_ingreso DATE NOT NULL DEFAULT CURRENT_DATE;

ALTER TABLE empleados_demo
ADD COLUMN activo BOOLEAN NOT NULL DEFAULT TRUE;

-- Verificar resultado
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'empleados_demo'
ORDER BY ordinal_position;

-- ALTER COLUMN ... TYPE: cambiar tipo de dato
-- Nota PG: usa "TYPE" a diferencia de SQL Server
ALTER TABLE empleados_demo
ALTER COLUMN email TYPE VARCHAR(100);

-- SET NOT NULL: agregar restricción a columna existente
ALTER TABLE empleados_demo
ALTER COLUMN email SET NOT NULL;

-- DROP NOT NULL: quitar la restricción
ALTER TABLE empleados_demo
ALTER COLUMN email DROP NOT NULL;

-- RENAME COLUMN: renombrar una columna
ALTER TABLE empleados_demo
RENAME COLUMN cargo TO puesto;

-- ADD CONSTRAINT: agregar una restricción después de crear
ALTER TABLE empleados_demo
ADD CONSTRAINT email_unico UNIQUE (email);

-- DROP CONSTRAINT: eliminar una restricción
ALTER TABLE empleados_demo
DROP CONSTRAINT email_unico;

-- DROP COLUMN: eliminar una columna (¡irreversible!)
ALTER TABLE empleados_demo
DROP COLUMN activo;

-- RENAME TABLE
ALTER TABLE empleados_demo
RENAME TO empleados_v2;

-- Limpiar
DROP TABLE IF EXISTS empleados_v2;
