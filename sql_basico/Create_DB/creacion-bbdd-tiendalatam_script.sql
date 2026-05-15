-- ============================================================
-- C10 · Creación de la Base de Datos TiendaLatam
-- Curso: SQL con PostgreSQL — TiendaLatam
-- IMPORTANTE: ejecutar conectado a la BD "postgres" (la default)
-- ============================================================

-- Crear la base de datos del curso
-- Convención PostgreSQL: nombres en minúsculas con guiones_bajos
CREATE DATABASE tiendalatam;

-- ============================================================
-- Después de ejecutar el CREATE DATABASE:
-- 1. En pgAdmin, hacer clic derecho en "Databases" → Refresh
-- 2. Doble clic en "tiendalatam" para conectarse
-- 3. Abrir Query Tool desde tiendalatam
-- 4. Verificar que la barra muestre "tiendalatam / postgres"
-- ============================================================

-- Verificar que estamos en la BD correcta
SELECT current_database();
-- Debe retornar: tiendalatam

-- Ver cuándo fue creada
SELECT datname,
       pg_catalog.pg_get_userbyid(datdba) AS propietario
FROM pg_catalog.pg_database
WHERE datname = 'tiendalatam';
