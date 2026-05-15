# Análisis didáctico de `ddl_v2.sql`

> **Curso:** Diseño de Bases de Datos Relacionales — Nivel Avanzado
> **Tema:** DDL de nivel producción en SQL Server
> **Caso de estudio:** Esquema `TiendaLatam`
> **Audiencia:** Estudiantes con dominio de SQL básico (DDL, DML, JOINs) que avanzan hacia ingeniería de datos profesional.

---

## Tabla de contenidos

1. [Objetivos de aprendizaje](#1-objetivos-de-aprendizaje)
2. [Marco conceptual: ¿qué es un DDL "de producción"?](#2-marco-conceptual-qué-es-un-ddl-de-producción)
3. [Configuración de la base de datos (§0)](#3-configuración-de-la-base-de-datos-0)
4. [Schemas y separación por dominio (§1)](#4-schemas-y-separación-por-dominio-1)
5. [Idempotencia: el principio de despliegue repetible](#5-idempotencia-el-principio-de-despliegue-repetible)
6. [Tipos de datos: decisiones que el principiante subestima (§2-§3)](#6-tipos-de-datos-decisiones-que-el-principiante-subestima-2-3)
7. [Restricciones (constraints) como contratos de integridad](#7-restricciones-constraints-como-contratos-de-integridad)
8. [Auditoría y trazabilidad: `ROWVERSION`, fechas y usuarios](#8-auditoría-y-trazabilidad-rowversion-fechas-y-usuarios)
9. [Tablas temporales (system-versioned tables)](#9-tablas-temporales-system-versioned-tables)
10. [Columnas calculadas persistidas](#10-columnas-calculadas-persistidas)
11. [Inventario por movimientos: del estado al evento (§4)](#11-inventario-por-movimientos-del-estado-al-evento-4)
12. [Vistas indexadas (§5)](#12-vistas-indexadas-5)
13. [Triggers de auditoría (§6)](#13-triggers-de-auditoría-6)
14. [Table-Valued Parameters y procedimientos atómicos (§7)](#14-table-valued-parameters-y-procedimientos-atómicos-7)
15. [`MERGE` para seeds idempotentes (§8)](#15-merge-para-seeds-idempotentes-8)
16. [Documentación viva con Extended Properties (§9)](#16-documentación-viva-con-extended-properties-9)
17. [Estrategia de indexación: filtrados, `INCLUDE`, descendentes](#17-estrategia-de-indexación-filtrados-include-descendentes)
18. [Anti-patrones evitados, con su contraparte](#18-anti-patrones-evitados-con-su-contraparte)
19. [Ejercicios propuestos](#19-ejercicios-propuestos)
20. [Lecturas recomendadas](#20-lecturas-recomendadas)

---

## 1. Objetivos de aprendizaje

Al terminar el análisis de este script, el estudiante deberá ser capaz de:

- **Justificar** cada decisión de diseño en términos de integridad, rendimiento, mantenibilidad o auditoría.
- **Distinguir** un DDL "que funciona" de un DDL "que sobrevive en producción".
- **Aplicar** patrones avanzados (tablas temporales, vistas indexadas, TVP, columnas calculadas) en escenarios reales.
- **Identificar** anti-patrones comunes (estado escalar, defaults sin nombre, magia silenciosa de defaults) y proponer alternativas.

---

## 2. Marco conceptual: ¿qué es un DDL "de producción"?

Un DDL universitario suele optimizar **una sola cosa**: que las tablas existan y carguen datos. Un DDL de producción optimiza **cinco** dimensiones simultáneamente:

| Dimensión | Pregunta que responde | Manifestación en el script |
|-----------|----------------------|----------------------------|
| **Integridad** | ¿Puede el modelo aceptar datos inválidos? | `CHECK`, `FK`, `UNIQUE`, `NOT NULL` |
| **Auditoría** | ¿Quién hizo qué y cuándo? | `FechaCreacion`, `UsuarioCreacion`, tablas temporales |
| **Rendimiento** | ¿Las consultas escalan a millones de filas? | Índices filtrados, `INCLUDE`, vistas indexadas, compresión |
| **Mantenibilidad** | ¿Puedo desplegar la misma versión dos veces sin romper nada? | Idempotencia, constraints nombrados |
| **Concurrencia** | ¿Qué pasa con dos usuarios escribiendo al mismo tiempo? | `ROWVERSION`, RCSI, SP atómico |

> **Idea central del curso:** el DDL no describe sólo "qué guardar"; codifica las **reglas del negocio** y el **comportamiento esperado del sistema**. Un buen DDL impide que el código de aplicación corrompa los datos, *aun cuando contiene bugs*.

---

## 3. Configuración de la base de datos (§0)

```sql
ALTER DATABASE TiendaLatam SET RECOVERY FULL;
ALTER DATABASE TiendaLatam SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
ALTER DATABASE TiendaLatam SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE TiendaLatam SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE TiendaLatam SET QUERY_STORE = ON;
```

### 3.1 Recovery model
- **`FULL`** registra todas las operaciones en el log. Habilita restauraciones *point-in-time* (PITR). Costo: el log crece y debe respaldarse.
- **`SIMPLE`** trunca el log automáticamente. Adecuado para desarrollo, no para producción donde se exige RPO bajo.

### 3.2 Read Committed Snapshot Isolation (RCSI)
SQL Server usa por defecto bloqueos pesimistas: un lector bloquea a un escritor (y viceversa). RCSI cambia el nivel `READ COMMITTED` para usar **versionado de filas** (MVCC, como PostgreSQL u Oracle). Resultado:

> Lectores nunca bloquean escritores. Escritores nunca bloquean lectores.

Costo: cada `UPDATE`/`DELETE` versionado se almacena temporalmente en `tempdb`.

### 3.3 Query Store
Es el "vuelo negro" de la base de datos: persiste planes de ejecución, estadísticas de tiempo y regresiones de rendimiento. **Habilítalo siempre en producción** — su costo es marginal y su valor diagnóstico es enorme.

---

## 4. Schemas y separación por dominio (§1)

```sql
IF SCHEMA_ID(N'geo')        IS NULL EXEC(N'CREATE SCHEMA geo        AUTHORIZATION dbo');
IF SCHEMA_ID(N'catalogo')   IS NULL EXEC(N'CREATE SCHEMA catalogo   AUTHORIZATION dbo');
-- ...
```

### ¿Por qué no todo en `dbo`?

Un *schema* en SQL Server es **un namespace + una frontera de permisos**. Separar por dominio cumple tres objetivos:

1. **Cognitivo**: al leer `ventas.Pedidos`, el lector ubica inmediatamente la responsabilidad del objeto.
2. **Seguridad**: puedes otorgar `SELECT` sobre `catalogo` a un rol y prohibirlo en `rrhh`.
3. **Refactorización**: si mañana el equipo de RRHH se separa a su propia base de datos, los objetos ya están agrupados.

> **Analogía:** un schema es a SQL lo que un *package* es a Java o un *module* a Python.

---

## 5. Idempotencia: el principio de despliegue repetible

Cada bloque del script comienza con una **guarda de existencia**:

```sql
IF OBJECT_ID(N'geo.Paises', N'U') IS NULL
BEGIN
    CREATE TABLE geo.Paises (...);
END
```

### El criterio

Un script DDL idempotente puede ejecutarse **N veces** sin cambiar el resultado tras la primera ejecución. Esto es indispensable para:

- **CI/CD** (la pipeline aplica el DDL en cada deploy).
- **Recuperación** ante errores parciales.
- **Replicación** entre entornos (dev → QA → prod) sin maquetar diffs manuales.

### ¿Por qué no `DROP IF EXISTS` y vuelvo a crear?

Porque eso **borraría los datos**. La idempotencia debe ser *aditiva*: lo que ya existe se respeta; sólo se crea lo que falta. Para cambios de estructura sobre tablas existentes, se usan **migraciones versionadas** (Flyway, Liquibase, DbUp), que es un paso adicional al DDL inicial.

---

## 6. Tipos de datos: decisiones que el principiante subestima (§2-§3)

### 6.1 `DATETIME2(3)` vs `DATETIME`

| Aspecto | `DATETIME` (legacy) | `DATETIME2(3)` (recomendado) |
|--------|---------------------|------------------------------|
| Precisión | 3.33 ms (no exacta) | 1 ms exacta |
| Rango | 1753-9999 | 0001-9999 |
| Bytes | 8 | 7 (con precisión 3) |
| Estándar SQL | No | Sí (ANSI) |

**Lección:** `DATETIME` se mantiene sólo por compatibilidad. Microsoft lo desaconseja desde SQL Server 2008. Usa `DATETIME2(n)` donde `n` es la precisión necesaria.

### 6.2 `SYSUTCDATETIME()` vs `GETDATE()`

`GETDATE()` devuelve hora **local del servidor**. Si el servidor está en GT-6 y replicas a uno en GT-5, los timestamps mienten. **Almacena siempre en UTC** y convierte en la capa de presentación.

### 6.3 `CHAR(2)` vs `NVARCHAR(2)` para códigos ISO

```sql
CodigoISO2 CHAR(2) NOT NULL,
CONSTRAINT CK_Paises_ISO2_Fmt CHECK (CodigoISO2 LIKE '[A-Z][A-Z]')
```

Cuando el campo tiene **longitud fija conocida** (códigos ISO de país, moneda, divisa), `CHAR(n)` es más compacto y comunica intención. Además, el `CHECK` con patrón impide cargar `'gt'` (minúsculas) o `'G7'` (no es letra).

### 6.4 `NVARCHAR(254)` para emails

El RFC 5321 limita a 254 caracteres. `NVARCHAR(200)` corta correos válidos. `NVARCHAR(MAX)` desperdicia espacio. La elección de tamaño no es cosmética: afecta índices, joins y memoria.

### 6.5 `DECIMAL(12,4)` para precios

Cuatro decimales soportan precios en monedas con sub-centavo (cripto, futuros, FX). `DECIMAL(10,2)` impide modelar tipos de cambio del tipo `7.85342 GTQ/USD`.

> **Regla:** el tipo debe acomodar **el rango real**, no el caso común.

---

## 7. Restricciones (constraints) como contratos de integridad

### 7.1 Constraints nombrados

```sql
CONSTRAINT DF_Paises_FechaCreacion DEFAULT (SYSUTCDATETIME())
```

vs el anti-patrón:

```sql
FechaCreacion DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME()
```

Sin nombre explícito, SQL Server genera uno aleatorio: `DF__Paises__FechaCre__1A14E395`. Cuando una migración necesite *eliminar o reemplazar* ese default, deberá hacer **SQL dinámico** para descubrir el nombre. **Siempre nombra los constraints**.

### 7.2 `CHECK` que codifican reglas de negocio

```sql
CONSTRAINT CK_DetallePedidos_Descuento CHECK (Descuento >= 0 AND Descuento <= 1),
CONSTRAINT CK_Empleados_Fechas CHECK (FechaBaja IS NULL OR FechaBaja >= FechaIngreso)
```

Estos `CHECK` evitan que **un bug de la aplicación** (descuento de 150%, baja antes del ingreso) corrompa los datos. La base de datos es la **última línea de defensa**.

### 7.3 `FK` con política explícita

```sql
CONSTRAINT FK_DetallePedidos_Pedidos FOREIGN KEY (PedidoID)
    REFERENCES ventas.Pedidos (PedidoID)
    ON DELETE CASCADE
```

`ON DELETE CASCADE` modela **composición**: el detalle no existe sin el pedido (igual que una factura sin renglones). Para relaciones de **asociación** (un pedido referencia un cliente, pero el cliente sobrevive al pedido), el default `NO ACTION` es correcto.

> **Regla pedagógica:** la política de `ON DELETE` no debe ser un default silencioso. **Decide y documenta.**

---

## 8. Auditoría y trazabilidad: `ROWVERSION`, fechas y usuarios

```sql
FechaCreacion    DATETIME2(3) NOT NULL CONSTRAINT DF_..._FechaCreacion DEFAULT (SYSUTCDATETIME()),
UsuarioCreacion  SYSNAME      NOT NULL CONSTRAINT DF_..._UsuarioCreacion DEFAULT (SUSER_SNAME()),
FechaModif       DATETIME2(3) NULL,
UsuarioModif     SYSNAME      NULL,
RowVersion       ROWVERSION   NOT NULL
```

### 8.1 Las "cuatro auditorías mínimas"
1. **Cuándo se creó** la fila (`FechaCreacion`).
2. **Quién la creó** (`UsuarioCreacion`).
3. **Cuándo se modificó** por última vez (`FechaModif`).
4. **Quién la modificó** (`UsuarioModif`).

Estos cuatro campos son **innegociables** en sistemas que cumplen normativa (SOX, GDPR, Basel III).

### 8.2 `ROWVERSION` (anteriormente `TIMESTAMP`)
Tipo especial que se **incrementa automáticamente** en cada update de la fila. Se usa para **concurrencia optimista**:

```sql
UPDATE ventas.Clientes
SET ...
WHERE ClienteID = @id
  AND RowVersion = @ultimoRowVersionQueLeyoLaApp;

IF @@ROWCOUNT = 0  -- alguien más actualizó la fila entre lectura y escritura
    THROW 50000, N'Conflicto de concurrencia, recargue el registro.', 1;
```

**Ventaja sobre los locks pesimistas:** no bloqueas a otros usuarios; sólo rechazas tu propio update si alguien te ganó la carrera.

---

## 9. Tablas temporales (system-versioned tables)

```sql
CREATE TABLE catalogo.Productos (
    ...
    ValidoDesde DATETIME2(3) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL,
    ValidoHasta DATETIME2(3) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidoDesde, ValidoHasta),
    ...
) WITH (
    SYSTEM_VERSIONING = ON (HISTORY_TABLE = historia.ProductosHist, DATA_CONSISTENCY_CHECK = ON)
);
```

### 9.1 ¿Qué hacen?

SQL Server mantiene **automáticamente** una segunda tabla (`historia.ProductosHist`) con una copia de cada versión previa de cada fila. La tabla principal contiene el **estado actual**; la histórica contiene **toda la genealogía**.

### 9.2 Consultas "as-of"

```sql
-- ¿Cómo lucía el producto 42 el 1 de marzo de 2026?
SELECT * FROM catalogo.Productos
FOR SYSTEM_TIME AS OF '2026-03-01T10:00:00'
WHERE ProductoID = 42;

-- Línea de tiempo completa del producto
SELECT * FROM catalogo.Productos
FOR SYSTEM_TIME ALL
WHERE ProductoID = 42
ORDER BY ValidoDesde;
```

### 9.3 ¿Cuándo usarlas?

- **Sí**: cuando el dominio exige auditoría regulatoria, análisis temporal, capacidad de "ver como estaba".
- **No** (o con cuidado): tablas con altísima frecuencia de update; el costo de almacenamiento se dispara.

### 9.4 ¿Trigger o tabla temporal?

| | Trigger histórico manual | Tabla temporal |
|---|--------------------------|----------------|
| Mantenimiento | Tú escribes y mantienes el trigger | Motor lo gestiona |
| Performance | Overhead de trigger | Optimizado a bajo nivel |
| Consultas | Manual (`JOIN` con tabla histórica) | Sintaxis estándar `FOR SYSTEM_TIME` |

**Conclusión pedagógica:** desde SQL Server 2016, prefiere tablas temporales sobre triggers de historia.

---

## 10. Columnas calculadas persistidas

```sql
NombreCompleto AS (CONCAT(Nombre, N' ', Apellido)) PERSISTED,
Subtotal       AS (CAST(Cantidad * PrecioUnitario * (1 - Descuento) AS DECIMAL(14, 4))) PERSISTED,
NumeroPedido   AS (CONCAT(N'P-', RIGHT(N'00000000' + CAST(PedidoID AS NVARCHAR(8)), 8))) PERSISTED
```

### 10.1 Lo conceptual

Una columna calculada es una **función determinista de otras columnas** que vive con la tabla. Con `PERSISTED`:
- Se **materializa físicamente** (no se recalcula en cada lectura).
- Puede **indexarse**.
- Garantiza consistencia: imposible que `Subtotal` quede desincronizado con `Cantidad * PrecioUnitario`.

### 10.2 Ventaja frente a calcular en la aplicación

Si tres equipos (web, móvil, BI) calculan `Subtotal` en su propio código y uno olvida aplicar el descuento, los reportes divergen. Centralizar la fórmula en la BD **fuerza una única verdad**.

---

## 11. Inventario por movimientos: del estado al evento (§4)

### 11.1 Anti-patrón: `Stock INT` en `Productos`

El DDL original tenía:
```sql
Productos.Stock INT NOT NULL DEFAULT 0
```

Problemas:
1. **Race conditions**: dos pedidos simultáneos pueden ambos leer `Stock = 5` y descontar 3, dejando `Stock = 2` cuando debería ser `-1`.
2. **Pérdida de información**: no sabes cuándo, por qué ni quién cambió el stock.
3. **Imposible auditar**.

### 11.2 Patrón correcto: tabla de eventos

```sql
inventario.Movimientos (
    MovimientoID BIGINT PK,
    ProductoID, SucursalID, TipoMovID,
    Cantidad,        -- siempre positivo
    PedidoID NULL,   -- trazabilidad al evento de venta
    FechaMovimiento, UsuarioCreacion
)
```

El **stock actual** se deriva por agregación:

```sql
SELECT
    ProductoID,
    SucursalID,
    SUM(Cantidad * Signo) AS StockActual
FROM inventario.Movimientos m
JOIN inventario.TiposMovimiento t ON t.TipoMovID = m.TipoMovID
GROUP BY ProductoID, SucursalID;
```

### 11.3 Concepto general: **Event Sourcing**

Modelas el sistema como una **secuencia inmutable de hechos** (movimientos), de la cual derivas el estado actual. Beneficios:
- Auditoría perfecta sin esfuerzo adicional.
- Capacidad de reconstruir el stock **a cualquier fecha**.
- Imposible "perder" información por update.

> **Esta es la misma idea detrás de la contabilidad de partida doble, que sobrevive desde 1494.**

---

## 12. Vistas indexadas (§5)

```sql
CREATE VIEW ventas.vw_PedidoTotales
WITH SCHEMABINDING
AS
SELECT
    dp.PedidoID,
    SUM(dp.Subtotal)          AS Total,
    SUM(dp.Cantidad)          AS UnidadesTotales,
    COUNT_BIG(*)              AS NumLineas
FROM ventas.DetallePedidos AS dp
GROUP BY dp.PedidoID;
GO

CREATE UNIQUE CLUSTERED INDEX IX_vw_PedidoTotales
    ON ventas.vw_PedidoTotales (PedidoID);
```

### 12.1 ¿Qué resuelve?

El DDL original tenía `Pedidos.Total DECIMAL(12,2)` como columna escalar redundante. Cada vez que cambia una línea, la app debe recalcular y actualizar `Total`. Si olvida, los datos se desincronizan.

### 12.2 Mecánica

Una vista indexada con `WITH SCHEMABINDING` se **materializa** en disco como una tabla. SQL Server mantiene la materialización **automáticamente** ante cada `INSERT`/`UPDATE`/`DELETE` en las tablas base.

### 12.3 Requisitos críticos

- `WITH SCHEMABINDING` impide que alguien `DROP COLUMN` algo de lo que la vista depende.
- `COUNT_BIG(*)` (no `COUNT(*)`) es obligatorio cuando se agrupa.
- Tipos de columna deterministas y exactos.

### 12.4 Costo

Cada cambio en `DetallePedidos` actualiza la vista. Para tablas con alta frecuencia de escritura, evalúa si la lectura compensa.

---

## 13. Triggers de auditoría (§6)

```sql
CREATE TRIGGER ventas.tr_Clientes_AfterUpdate
ON ventas.Clientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(FechaModif)
    BEGIN
        UPDATE c
        SET c.FechaModif = SYSUTCDATETIME(),
            c.UsuarioModif = SUSER_SNAME()
        FROM ventas.Clientes c
        INNER JOIN inserted i ON i.ClienteID = c.ClienteID;
    END
END
```

### 13.1 Anatomía

- **`AFTER UPDATE`** corre tras el UPDATE confirmado, antes del commit.
- **`inserted`** es una pseudo-tabla con el estado *post-update* de las filas afectadas.
- **`SET NOCOUNT ON`** suprime "N filas afectadas" — evita que ORMs interpreten mal el rowcount.
- **`IF NOT UPDATE(FechaModif)`** previene recursión infinita: si el trigger se dispara por un UPDATE que ya incluye `FechaModif`, no hace nada.

### 13.2 Riesgo: triggers en cascada

Triggers que modifican otras tablas con triggers crean cadenas difíciles de depurar. Mantenlos **simples, locales, predecibles**.

---

## 14. Table-Valued Parameters y procedimientos atómicos (§7)

```sql
CREATE TYPE ventas.DetallePedidoTipo AS TABLE (
    ProductoID INT NOT NULL, Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(12, 4) NOT NULL,
    Descuento DECIMAL(5, 4) NOT NULL DEFAULT (0),
    PRIMARY KEY CLUSTERED (ProductoID)
);

CREATE OR ALTER PROCEDURE ventas.usp_CrearPedido
    @ClienteID INT, @SucursalID INT, @EmpleadoID INT, @MonedaID TINYINT,
    @Notas NVARCHAR(500) = NULL,
    @Detalle ventas.DetallePedidoTipo READONLY,
    @PedidoID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- 1) Inserta el pedido
        -- 2) Inserta TODAS las líneas
        -- 3) Genera movimientos de inventario
        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH
END
```

### 14.1 ¿Por qué un TVP?

Imagina la alternativa **ingenua**: la app abre conexión, hace 1 `INSERT` al pedido, **N `INSERT`** a las líneas, **N `INSERT`** a movimientos de inventario. Eso son `2N+1` round-trips de red. Con TVP: **un solo round-trip**.

### 14.2 ¿Por qué un SP atómico?

Tres ventajas:

1. **Atomicidad real**: si falla la inserción del movimiento de inventario, el pedido y sus líneas también se revierten. La aplicación no tiene que orquestar transacciones distribuidas.
2. **Encapsulamiento**: la lógica de negocio "crear pedido" vive en un solo lugar. Si mañana se agrega un paso (notificación, fidelización), se cambia el SP sin tocar 5 clientes.
3. **Seguridad**: puedes otorgar `EXECUTE` sobre el SP y revocar `INSERT` directo sobre las tablas. La app no puede saltarse las reglas.

### 14.3 `SET XACT_ABORT ON`

Si ocurre un error en runtime (deadlock, FK violation), la transacción se **revierte automáticamente**. Sin este flag, ciertos errores dejan la transacción "abierta y rota", obligando a manejo manual frágil.

### 14.4 `THROW` vs `RAISERROR`

`THROW` (SQL 2012+) re-lanza el error original con su número, severidad y mensaje. `RAISERROR` es legado y exige más boilerplate. Prefiere `THROW`.

---

## 15. `MERGE` para seeds idempotentes (§8)

```sql
MERGE catalogo.EstadosPedido AS tgt
USING (VALUES
    (1, N'PENDIENTE',  N'Pedido registrado, pendiente de procesar', 0),
    (2, N'EN_PROCESO', N'Pedido en preparación',                    0),
    (3, N'COMPLETADO', N'Pedido entregado al cliente',              1),
    (4, N'CANCELADO',  N'Pedido cancelado',                         1)
) AS src (EstadoID, Codigo, Descripcion, EsTerminal)
ON tgt.EstadoID = src.EstadoID
WHEN MATCHED AND (tgt.Codigo <> src.Codigo OR ...)
    THEN UPDATE SET ...
WHEN NOT MATCHED BY TARGET
    THEN INSERT (...) VALUES (...);
```

### 15.1 Anatomía del `MERGE`

- **`USING`**: datos fuente (puede ser una subconsulta o `VALUES`).
- **`ON`**: criterio de coincidencia.
- **`WHEN MATCHED AND (cond)`**: hay match y la fila destino difiere → `UPDATE`.
- **`WHEN NOT MATCHED BY TARGET`**: no existe en destino → `INSERT`.
- *(Opcional)* **`WHEN NOT MATCHED BY SOURCE`**: existe en destino pero no en fuente → `DELETE`.

### 15.2 ¿Por qué no `INSERT IF NOT EXISTS`?

`MERGE` es atómica para todo el conjunto, expresiva, y permite **actualizar valores que cambien** (si renombras `'CANCELADO'` a `'CANCELLED'`, el seed lo refleja sin error).

### 15.3 Advertencia honesta

`MERGE` tiene bugs históricos en SQL Server con escenarios concurrentes complejos (KB 2589980). Para seeds estáticos como éste, es seguro. Para *upserts* concurrentes de alto volumen, hay quien prefiere `INSERT` + `UPDATE` separados con `HOLDLOCK`.

---

## 16. Documentación viva con Extended Properties (§9)

```sql
EXEC sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Tabla de pedidos. System-versioned: el histórico vive en historia.PedidosHist.',
    @level0type = N'SCHEMA', @level0name = N'ventas',
    @level1type = N'TABLE',  @level1name = N'Pedidos';
```

### Ventaja

La documentación queda **en la base de datos**, no en un Word que nadie actualiza. SSMS, Azure Data Studio, herramientas de modelado (ER/Studio, dbForge) y generadores de documentación automática (Schema Spy, Redgate) la leen y muestran.

---

## 17. Estrategia de indexación: filtrados, `INCLUDE`, descendentes

### 17.1 Índices filtrados

```sql
CREATE NONCLUSTERED INDEX IX_Clientes_PaisID
    ON ventas.Clientes (PaisID)
    WHERE Activo = 1;

CREATE UNIQUE NONCLUSTERED INDEX UQ_Clientes_Email_Filt
    ON ventas.Clientes (Email)
    WHERE Email IS NOT NULL;
```

Sólo indexan **el subconjunto de filas que cumple el filtro**. Beneficios:

1. **Menos espacio**: si 80% de clientes están activos, omites 20% irrelevante.
2. **Unicidad parcial**: `UQ_..._Email_Filt` permite múltiples filas con `Email = NULL` pero garantiza unicidad cuando hay valor.
3. **Mejor selectividad** para consultas con el mismo filtro.

### 17.2 `INCLUDE` (columnas cubiertas)

```sql
CREATE NONCLUSTERED INDEX IX_Pedidos_ClienteID
    ON ventas.Pedidos (ClienteID)
    INCLUDE (FechaPedido, EstadoID);
```

El **árbol** se ordena por `ClienteID`, pero las **hojas** guardan también `FechaPedido` y `EstadoID`. Si la query es:

```sql
SELECT FechaPedido, EstadoID FROM ventas.Pedidos WHERE ClienteID = 42;
```

SQL Server la resuelve **sin tocar la tabla base** (query coverage). Velocidad: 10× a 100× según el caso.

### 17.3 Orden descendente

```sql
CREATE NONCLUSTERED INDEX IX_Pedidos_FechaPedido_Desc
    ON ventas.Pedidos (FechaPedido DESC) INCLUDE (ClienteID, EstadoID);
```

Si la consulta más común es "últimos 10 pedidos", un índice **descendente** evita un *sort step* en el plan.

### 17.4 La regla de oro de indexación

> Indexa lo que las consultas demandan, no lo que tu intuición sugiere. Habilita Query Store, monitorea `sys.dm_db_missing_index_details` y `sys.dm_db_index_usage_stats`, **luego** decide.

---

## 18. Anti-patrones evitados, con su contraparte

| Anti-patrón | Por qué duele | Patrón en `ddl_v2.sql` |
|-------------|---------------|-------------------------|
| `Stock` escalar | Race conditions, sin historia | `inventario.Movimientos` |
| `Total` redundante en `Pedidos` | Desincronización | Vista indexada `vw_PedidoTotales` |
| `Estado NVARCHAR + CHECK IN (...)` | Cambios requieren `ALTER TABLE` | Catálogo `EstadosPedido` con FK |
| `DATETIME + GETDATE()` | Precisión y zona horaria | `DATETIME2(3) + SYSUTCDATETIME()` |
| Defaults sin nombre | Imposible scriptarlos en migraciones | `CONSTRAINT DF_...` siempre |
| Todo en `dbo` | Sin frontera de permisos ni dominio | 6 schemas por dominio |
| Sin auditoría | Cero trazabilidad regulatoria | 4 columnas + `ROWVERSION` |
| Email sin unicidad | Duplicados silenciosos | Índice único filtrado |
| `IDENTITY` sin `IDENTITY_INSERT` policy | Brechas en numeración aceptadas como dadas | (Documentado en política operativa) |

---

## 19. Ejercicios propuestos

### Nivel introductorio
1. **Idempotencia**. Ejecuta `ddl_v2.sql` dos veces seguidas en una base limpia. ¿Falla? ¿Por qué no? Identifica los tres mecanismos que lo evitan.
2. **Catálogo**. Agrega un nuevo estado de pedido `DEVUELTO` con `EsTerminal = 1`. ¿Cuántas líneas tuviste que cambiar? Compara con el costo en el DDL original.
3. **Constraint**. Implementa un `CHECK` que impida vender productos inactivos desde `usp_CrearPedido`. ¿Lo pondrías en el SP, en la FK o en un trigger? Justifica.

### Nivel intermedio
4. **Stock derivado**. Escribe una **vista indexable** que exponga el stock actual por producto y sucursal a partir de `inventario.Movimientos`. ¿Qué requisitos debe cumplir para que pueda indexarse? ¿Cuáles te fuerzan a renunciar?
5. **Concurrencia optimista**. Implementa un SP `ventas.usp_ActualizarCliente` que use `RowVersion` para detectar conflictos y devuelva un error específico si la fila fue modificada por otro usuario.
6. **Tabla temporal**. Consulta cómo era el `Precio` de un producto el primer día del mes anterior. Escribe la query.

### Nivel avanzado
7. **Particionamiento**. Diseña un esquema de particionamiento por `FechaPedido` para `ventas.Pedidos`. ¿Por mes o por trimestre? ¿Cómo afecta a la vista indexada?
8. **Row-Level Security**. Implementa una política RLS que impida a empleados ver pedidos de sucursales que no son la suya.
9. **In-Memory OLTP**. ¿Qué tabla del modelo se beneficiaría más de convertirse en *memory-optimized*? Argumenta con métricas de patrón de escritura.

---

## 20. Lecturas recomendadas

### Libros canónicos
- **Itzik Ben-Gan, *T-SQL Fundamentals* y *T-SQL Querying*** (Microsoft Press). El estándar académico para SQL Server.
- **Joe Celko, *SQL for Smarties***. Filosofía relacional y patrones avanzados.
- **Markus Winand, *SQL Performance Explained***. Indexación entendida desde primer principios.

### Documentación oficial
- [SQL Server temporal tables](https://learn.microsoft.com/sql/relational-databases/tables/temporal-tables)
- [Indexed Views](https://learn.microsoft.com/sql/relational-databases/views/create-indexed-views)
- [Query Store](https://learn.microsoft.com/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store)

### Para evaluar tu propio DDL
- *Database Reliability Engineering* (Campbell & Majors, O'Reilly).
- *Refactoring Databases* (Ambler & Sadalage). Cómo evolucionar un esquema sin romper el negocio.

---

## Cierre

> Un buen DDL no es el que carga datos rápido. Es el que **te protege de ti mismo** dentro de tres años, cuando ya no recuerdas por qué tomaste cada decisión y un nuevo desarrollador entra al equipo.

La diferencia entre `ddl.sql` y `ddl_v2.sql` no es estética: es la diferencia entre un script que **describe estructura** y uno que **codifica disciplina**. Esa disciplina es lo que distingue al analista de datos del ingeniero de datos.

---

*Documento preparado para el curso de SQL Server. Para dudas, correcciones o ampliaciones, abrir un issue en el repositorio.*
