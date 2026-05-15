-- ============================================================
-- C18 · DELETE físico vs borrado lógico
-- Curso: SQL con PostgreSQL — TiendaLatam
-- ============================================================

-- Preparar datos de ejemplo
CREATE TABLE IF NOT EXISTS clientes (
    cliente_id INTEGER PRIMARY KEY,
    nombre     TEXT NOT NULL,
    email      VARCHAR(100),
    activo     BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS pedidos (
    pedido_id INTEGER PRIMARY KEY,
    cliente_id INTEGER,
    fecha DATE
);

CREATE TABLE IF NOT EXISTS detalle_pedidos (
    detalle_id INTEGER PRIMARY KEY,
    pedido_id INTEGER,
    cantidad INTEGER
);

INSERT INTO clientes (cliente_id, nombre, email, activo) VALUES
    (1, 'María González', 'maria@email.cl', TRUE),
    (2, 'Carlos Rodríguez', 'carlos@email.cl', TRUE),
    (3, 'Ana Martínez', 'ana@email.ar', TRUE),
    (4, 'Luis Vargas', 'luis@email.co', TRUE),
    (5, 'Eva López', 'eva@email.cl', TRUE),
    (99, 'Temporal', 'temporal@email.cl', TRUE);

INSERT INTO pedidos (pedido_id, cliente_id, fecha) VALUES
    (1, 1, '2024-01-15'),
    (2, 2, '2024-02-10'),
    (100, 99, '2019-12-01');

INSERT INTO detalle_pedidos (detalle_id, pedido_id, cantidad) VALUES
    (1, 1, 2),
    (2, 1, 3),
    (3, 100, 1);

-- ===== DELETE FÍSICO =====

-- DELETE básico (siempre con WHERE)
DELETE FROM clientes
WHERE cliente_id = 99;

-- Verificar que se borró
SELECT COUNT(*) as total FROM clientes WHERE cliente_id = 99;

-- DELETE con RETURNING — ver qué se borró
DELETE FROM detalle_pedidos
WHERE pedido_id = 100
RETURNING *;

-- DELETE con subquery
DELETE FROM detalle_pedidos
WHERE pedido_id IN (
    SELECT pedido_id FROM pedidos
    WHERE fecha < '2020-01-01'
);

-- TRUNCATE: vaciar tabla completamente (más rápido que DELETE sin WHERE)
-- TRUNCATE TABLE tabla_temporal;  -- úsalo solo en tablas de staging/temp

-- ===== BORRADO LÓGICO =====

-- Dar de baja un cliente (borrado lógico)
UPDATE clientes
SET activo = FALSE
WHERE cliente_id = 5;

-- Consultar solo clientes activos (filtro estándar con borrado lógico)
SELECT nombre, email, activo
FROM clientes
WHERE activo = TRUE
LIMIT 10;

-- Consultar clientes inactivos (para auditoría)
SELECT nombre, email, activo
FROM clientes
WHERE activo = FALSE;

-- Reactivar un cliente
UPDATE clientes
SET activo = TRUE
WHERE cliente_id = 5
RETURNING cliente_id, nombre, activo;

-- ===== COMPARACIÓN =====
/*
DELETE FÍSICO:
  ✓ Libera espacio en disco
  ✓ Queries más simples (no filtrar activo)
  ✗ Irreversible — no hay marcha atrás
  ✗ Pierde historial para auditoría
  ✗ Puede romper FK si no usas CASCADE

BORRADO LÓGICO (activo = FALSE):
  ✓ Reversible — podés reactivar
  ✓ Mantiene historial completo
  ✓ Auditaría: saber quién tenía qué
  ✗ La tabla crece sin límite
  ✗ Todos los SELECT necesitan WHERE activo = TRUE
  → Solución: usar vistas (Curso 2)
*/

-- Limpieza
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS clientes;
