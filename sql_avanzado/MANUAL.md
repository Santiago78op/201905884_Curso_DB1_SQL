# Manual de SQL — Nivel Avanzado

> Síntesis de conceptos por tema, basada en los playbooks PDF del curso *SQL Server para Analistas de Datos* aplicados al caso de estudio `TiendaLatam`. A diferencia del nivel básico (PostgreSQL), este manual usa sintaxis **T-SQL / SQL Server**.
>
> Cada sección tiene la misma estructura: **concepto clave**, **por qué importa**, **sintaxis mínima**, **puntos finos / errores comunes**, **cuándo usarlo (y cuándo no)**.

> ⚠️ **Estado: WIP (Work In Progress).** Este nivel sigue creciendo. Los temas actualmente publicados están abajo; al final hay una lista de [temas pendientes](#temas-pendientes-por-incorporar). Cuando agregues un playbook nuevo, sumalo a esa lista y luego promovelo a sección numerada acá arriba.

---

## Tabla de contenidos

**Setup**
0. [Instalación SQL Server + SSMS](#0-instalación-sql-server--ssms)

**JOINs avanzados**
1. [INNER JOIN vs LEFT JOIN](#1-inner-join-vs-left-join)
2. [RIGHT JOIN, FULL OUTER JOIN y CROSS JOIN](#2-right-join-full-outer-join-y-cross-join)

**Subqueries y CTEs**
3. [Subqueries en WHERE (escalar, lista, EXISTS)](#3-subqueries-en-where-escalar-lista-exists)
4. [Subqueries en FROM y SELECT](#4-subqueries-en-from-y-select)
5. [Common Table Expressions (CTEs)](#5-common-table-expressions-ctes)

**Vistas y columnas derivadas**
6. [Vistas (Views)](#6-vistas-views)
7. [Vistas indexadas (materializadas)](#7-vistas-indexadas-materializadas)
8. [Columnas calculadas y columnas persistidas](#8-columnas-calculadas-y-columnas-persistidas)

**Lógica del lado del servidor**
9. [Stored Procedures (SP)](#9-stored-procedures-sp)
10. [Triggers](#10-triggers)

[**Temas pendientes por incorporar →**](#temas-pendientes-por-incorporar)

---

## 0. Instalación SQL Server + SSMS
**Carpeta:** `Instalacion_SQL_Server_SSMS/` · **Recursos:** `ddl.sql`, `bulk_insert.sql`, `tiendalatam__csv.zip`

Esta carpeta no es un tema de SQL — es la **preparación del entorno** para todo el nivel avanzado:
1. Instalar SQL Server 2019+ y SSMS (o Azure Data Studio).
2. Descomprimir `tiendalatam__csv.zip` en `C:\TiendaLatam_CSV\`.
3. Ejecutar `ddl.sql` y luego `bulk_insert.sql` para tener `TiendaLatam` (v1) cargada.

Una vez listo, podés ejecutar cualquiera de los scripts de los temas que siguen. *Nota:* si vas a trabajar con la versión de producción (v2, schemas por dominio), usá `../ddl/ddl_v2.sql` desde la raíz del repo.

---

## 1. INNER JOIN vs LEFT JOIN
**Carpeta:** `Inner_vs_Left_JOIN/` · **Script:** `script_inner_y_left_join.sql` · **Playbook:** `playbook-inner-join-vs-left-join.pdf`

**Concepto clave:** `INNER JOIN` solo devuelve filas con coincidencia en ambas tablas; `LEFT JOIN` trae todo lo de la tabla izquierda y rellena con `NULL` cuando no hay match a la derecha.

**¿Por qué importa?** Un JOIN mal elegido produce reportes que mienten sin dar error. Si el gerente te pide "todos los clientes" y usás `INNER JOIN` con `Pedidos`, los clientes registrados que nunca compraron desaparecen del resultado — sin aviso. Es un error de interpretación, no de sintaxis, y por eso es el más peligroso. Esos clientes "fantasma" son oro para marketing y retención.

**Sintaxis mínima:**
```sql
-- Versión correcta: todos los clientes, incluso los que nunca compraron
SELECT c.ClienteID, c.Nombre, ISNULL(SUM(p.Total), 0) AS TotalComprado
FROM Clientes c
LEFT JOIN Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY c.ClienteID, c.Nombre;
```

**Puntos finos / errores comunes:**
- Cuando un cliente no tiene pedidos, `SUM(p.Total)` no da 0, da `NULL`. Envolvé con `ISNULL(SUM(p.Total), 0)` para que el reporte se vea limpio.
- `NULL` significa "no hay dato", no significa cero. Son cosas distintas.
- Patrón a memorizar: **`LEFT JOIN` + `WHERE columna_derecha IS NULL`** sirve para encontrar lo que falta (clientes sin pedidos, productos sin venta, etc.).
- Regla de decisión por lenguaje natural: si la pregunta dice "todos" o "nunca", probablemente es `LEFT JOIN`; si solo te interesan los que sí tienen relación, `INNER JOIN`.

**Cuándo usarlo (y cuándo NO):** `LEFT JOIN` cuando necesitás conservar el universo completo de la tabla principal; `INNER JOIN` cuando solo importan los registros que efectivamente tienen relación en ambos lados.

---

## 2. RIGHT JOIN, FULL OUTER JOIN y CROSS JOIN
**Carpeta:** `right_full_cross_JOIN/` · **Script:** `script_right_full_outer_cross_join.sql` · **Playbook:** `playbook-right-join-full-outer-join-y-cross-join.pdf`

**Concepto clave:** `RIGHT JOIN` es el espejo de `LEFT`; `FULL OUTER JOIN` trae todo de ambos lados (coincida o no); `CROSS JOIN` no busca coincidencias, hace producto cartesiano (cada fila de A combinada con cada fila de B).

**¿Por qué importa?** `INNER` y `LEFT` cubren el 90 % de los casos, pero los otros tres existen por razones específicas. Si no los conocés, terminás escribiendo consultas innecesariamente complejas para llegar al mismo resultado, o peor, no detectás problemas de integridad de datos en ambas direcciones.

**Sintaxis mínima:**
```sql
-- FULL OUTER JOIN para auditoría de integridad
SELECT pa.NombrePais, c.ClienteID
FROM Paises pa
FULL OUTER JOIN Clientes c ON pa.PaisID = c.PaisID
WHERE pa.PaisID IS NULL OR c.ClienteID IS NULL;

-- CROSS JOIN para análisis de cobertura (todas las combinaciones país × categoría)
SELECT pa.NombrePais, ca.NombreCategoria
FROM Paises pa
CROSS JOIN Categorias ca;
```

**Puntos finos / errores comunes:**
- `RIGHT JOIN` se usa muy poco en la práctica: cualquier `RIGHT JOIN` puede reescribirse como `LEFT JOIN` invirtiendo el orden de las tablas. La convención de la industria es siempre poner la tabla principal a la izquierda y usar `LEFT`. Conocelo igual para leer código ajeno.
- `FULL OUTER JOIN` brilla en **auditoría**: con un solo query y un `WHERE ... IS NULL` detectás huérfanos en ambas direcciones (países sin clientes y clientes con país inexistente).
- `CROSS JOIN` es base de **análisis de cobertura**: combinás país × categoría con CROSS JOIN y después hacés `LEFT JOIN` con ventas reales para detectar qué combinaciones nunca vendieron.
- Precaución con `CROSS JOIN`: 100.000 clientes × 10.000 productos = mil millones de filas. Siempre hacé la multiplicación mental antes de ejecutar.

**Cuándo usarlo (y cuándo NO):** `FULL OUTER JOIN` cuando necesitás detectar huecos en ambos lados; `CROSS JOIN` cuando necesitás el universo completo de combinaciones (cobertura); `RIGHT JOIN` casi nunca por convención de legibilidad.

---

## 3. Subqueries en WHERE (escalar, lista, EXISTS)
**Carpeta:** `Subquery_Where_Exists/` · **Script:** `script_subqueries_en_where.sql` · **Playbook:** `playbook-subqueries-en-where.pdf`

**Concepto clave:** Una subquery es una consulta dentro de otra. En el `WHERE` funciona como **filtro dinámico**: primero se ejecuta la subquery, produce un resultado, y la query principal lo usa como si fuera un valor escrito a mano.

**¿Por qué importa?** Los filtros estáticos (`WHERE Total > 500`) sirven cuando conocés el valor de antemano. Pero "clientes que compraron por encima del promedio" no se puede escribir como número fijo — el promedio cambia con cada venta. La subquery mantiene tu consulta viva: siempre usa el valor actualizado.

**Sintaxis mínima:**
```sql
-- Subquery escalar: un solo valor
SELECT ClienteID, Total
FROM Pedidos
WHERE Total > (SELECT AVG(Total) FROM Pedidos WHERE Estado = 'Completado');

-- Subquery de lista: con IN
SELECT * FROM Productos
WHERE ProductoID IN (
    SELECT ProductoID FROM DetallePedidos dp
    JOIN Pedidos p ON dp.PedidoID = p.PedidoID
    WHERE p.PaisID = 1
);

-- EXISTS: subquery correlacionada
SELECT c.ClienteID, c.Nombre FROM Clientes c
WHERE EXISTS (
    SELECT 1 FROM Pedidos p
    WHERE p.ClienteID = c.ClienteID AND p.Total > 500
);
```

**Puntos finos / errores comunes:**
- **Escalar** = un único valor (número, fecha, texto). Uno solo.
- **Lista** = se usa con `IN` / `NOT IN`. **Trampa del `NOT IN`:** si la subquery devuelve aunque sea un solo `NULL`, `NOT IN` devuelve cero filas aunque "lógicamente" debería traer resultados. Solución: agregá `WHERE columna IS NOT NULL` dentro de la subquery, o mejor, usá `NOT EXISTS`.
- **`EXISTS`** es **correlacionada**: se ejecuta una vez por cada fila de la query principal. Solo responde sí/no, no devuelve valores. Por eso adentro se escribe `SELECT 1` por convención — no importa qué columna pidas, solo importa si hay filas.
- `NOT EXISTS` es la alternativa **segura** a `NOT IN` con NULLs. Es otra forma de hacer lo mismo que `LEFT JOIN + IS NULL`.

**Cuándo usarlo (y cuándo NO):** escalar si el filtro depende de un único valor calculado; lista (`IN`) si depende de un conjunto de IDs; `EXISTS` si solo necesitás chequear existencia fila por fila.

---

## 4. Subqueries en FROM y SELECT
**Carpeta:** `Subquery_From_vs_Select/` · **Script:** `script_subqueries_en_from_y_select.sql` · **Playbook:** `subqueries-en-from-y-select.pdf`

**Concepto clave:** La misma sintaxis (subquery entre paréntesis) se comporta distinto según dónde vive: en `WHERE` es filtro, en `FROM` es **tabla derivada** (tabla virtual con la que trabajás en una segunda etapa), en `SELECT` es un **valor calculado fila por fila**.

**¿Por qué importa?** Permite organizar la lógica en capas. En vez de meter todo en una sola pasada confusa con GROUP BYs y agregaciones, separás: primera etapa calcula, segunda etapa ordena/filtra/cruza. Más legible y a veces ni siquiera es posible hacerlo de otra forma.

**Sintaxis mínima:**
```sql
-- Subquery en FROM (tabla derivada): top 3 países por ticket promedio
SELECT TOP 3 *
FROM (
    SELECT pa.NombrePais, AVG(p.Total) AS TicketPromedio
    FROM Pedidos p
    JOIN Clientes c ON p.ClienteID = c.ClienteID
    JOIN Paises pa  ON c.PaisID = pa.PaisID
    GROUP BY pa.NombrePais
) AS resumen      -- alias OBLIGATORIO en SQL Server
ORDER BY TicketPromedio DESC;

-- Subquery en SELECT: porcentaje de cada país sobre el total global
SELECT pa.NombrePais,
       SUM(p.Total) AS Ventas,
       (SELECT SUM(Total) FROM Pedidos) AS VentasGlobales,
       SUM(p.Total) * 100.0 / (SELECT SUM(Total) FROM Pedidos) AS Porcentaje
FROM Pedidos p
JOIN Clientes c ON p.ClienteID = c.ClienteID
JOIN Paises pa  ON c.PaisID = pa.PaisID
GROUP BY pa.NombrePais;

-- Alternativa con DECLARE (más eficiente si el valor es constante)
DECLARE @TotalGlobal DECIMAL(12,2) = (SELECT SUM(Total) FROM Pedidos);
SELECT pa.NombrePais, SUM(p.Total) * 100.0 / @TotalGlobal AS Porcentaje
FROM Pedidos p
JOIN Clientes c ON p.ClienteID = c.ClienteID
JOIN Paises pa  ON c.PaisID = pa.PaisID
GROUP BY pa.NombrePais;
```

**Puntos finos / errores comunes:**
- En SQL Server, **toda tabla derivada en `FROM` necesita alias** (el `AS resumen`). Sin alias, la consulta no corre.
- Subquery en `SELECT` se ejecuta **una vez por cada fila** del resultado. Con 12 filas no pasa nada, con 10.000 filas y una subquery costosa el rendimiento se degrada rápido.
- Solución elegante: `DECLARE @Variable` calcula el valor una sola vez y lo usa en toda la query. Más rápido y más legible. Pero solo aplica si el valor es **constante para toda la consulta** (no cambia fila por fila).

**Cuándo usarlo (y cuándo NO):** `FROM` cuando necesitás trabajar en dos etapas con un cálculo intermedio complejo; `SELECT` cuando agregás una columna calculada por fila; pero si ese valor es el mismo para todas las filas, mejor `DECLARE`.

---

## 5. Common Table Expressions (CTEs)
**Carpeta:** `Common_Table_WITH/` · **Scripts:** `script_ctes_con_with.sql`, `script_ejercicio.sql` · **Playbook:** `common-table-expressions-ctes.pdf`

**Concepto clave:** Una CTE es una **subquery con nombre** definida al inicio del query con `WITH`. La consulta se lee de arriba hacia abajo como una receta de pasos, en vez de pelar capas de subqueries anidadas.

**¿Por qué importa?** Cuando una consulta necesita 3+ subqueries anidadas, leerla obliga a ir de adentro hacia afuera. Funciona, pero seis meses después nadie la entiende — eso es deuda técnica. Las CTEs convierten esa lógica en pasos con nombre, cada uno con su responsabilidad clara. Es la forma profesional que vas a encontrar en código de producción serio.

**Sintaxis mínima:**
```sql
WITH VentasPorEmpleado AS (
    SELECT EmpleadoID, PaisID, SUM(Total) AS Ventas
    FROM Pedidos
    GROUP BY EmpleadoID, PaisID
),
ConRanking AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY PaisID ORDER BY Ventas DESC) AS rk
    FROM VentasPorEmpleado
),
PaisesRelevantes AS (
    SELECT PaisID FROM VentasPorEmpleado
    GROUP BY PaisID HAVING SUM(Ventas) > 10000
)
SELECT cr.*
FROM ConRanking cr
JOIN PaisesRelevantes pr ON cr.PaisID = pr.PaisID
WHERE cr.rk <= 3;
```

**Puntos finos / errores comunes:**
- Una CTE existe **solo durante la ejecución del query**. No se guarda en la base de datos, no la podés llamar desde otra consulta. Si querés algo persistente para que cualquiera use, eso es una **Vista**.
- Podés definir varias CTEs separadas por comas; cada una puede referenciar a las anteriores (encadenamiento).
- En SQL Server las CTEs **no se materializan automáticamente**: si referenciás la misma CTE varias veces, el motor puede ejecutar su lógica varias veces. Si pesa demasiado, la alternativa es volcar el resultado a una tabla temporal `#TempTable`.
- **CTE recursiva:** sirve para datos jerárquicos (organigramas con `SupervisorID`). Tiene un caso base + un caso recursivo. Protegete contra ciclos con `OPTION (MAXRECURSION N)`.

**Cuándo usarlo (y cuándo NO):** Regla del instructor — si tu consulta tiene **más de 2-3 pasos lógicos**, usá CTEs. Para queries simples de un solo paso, el `WITH` es overkill.

---

## 6. Vistas (Views)
**Carpeta:** `Vistas/` · **Script:** `script_vistas_views.sql` · **Playbook:** `vistas-views_-consultas-que-cualquiera-puede-usar.pdf`

**Concepto clave:** Una vista es una **consulta guardada con nombre**. No almacena datos, almacena la definición del `SELECT`. Cada vez que alguien la consulta, SQL Server ejecuta la query en ese instante.

**¿Por qué importa?** Resuelve tres problemas al mismo tiempo: (1) **abstracción** — el equipo comercial usa `SELECT * FROM VW_VentasPorPais` sin saber que detrás hay 4 JOINs; (2) **seguridad** — das acceso a la vista sin dar acceso a las tablas originales (principio de mínimo privilegio); (3) **mantenimiento** — si cambia la lógica de negocio, actualizás la vista en un solo lugar y todos ven la versión nueva automáticamente.

**Sintaxis mínima:**
```sql
CREATE VIEW VW_VentasPorPais AS
SELECT pa.NombrePais,
       SUM(p.Total) AS VentasTotales,
       AVG(p.Total) AS TicketPromedio,
       COUNT(*)     AS NumeroPedidos
FROM Pedidos p
JOIN Clientes c ON p.ClienteID = c.ClienteID
JOIN Paises pa  ON c.PaisID = pa.PaisID
WHERE p.Estado = 'Completado'
GROUP BY pa.NombrePais;
GO

-- Modificar
ALTER VIEW VW_VentasPorPais AS ...;
-- Eliminar
DROP VIEW IF EXISTS VW_VentasPorPais;
-- Ver la definición
EXEC sp_helptext 'VW_VentasPorPais';
```

**Puntos finos / errores comunes:**
- La vista es una **ventana en tiempo real**, no una foto. Si entran ventas nuevas hoy, mañana al consultar la vista ya están reflejadas.
- Convención de la industria: prefijo `VW_` en el nombre.
- Limitaciones a recordar: **no podés** poner `ORDER BY` directamente en la vista (a menos que uses `TOP` u `OFFSET/FETCH`); **no recibe parámetros** (para eso son funciones de tabla); no podés hacer `INSERT/UPDATE/DELETE` si tiene `GROUP BY`, JOINs complejos o columnas calculadas.
- **Si la query interna es lenta, la vista es igual de lenta.** No hay magia de rendimiento — para eso están las vistas indexadas.

**Cuándo usarlo (y cuándo NO):** Vista cuando una misma consulta la usa mucha gente o se reutiliza en múltiples scripts, y querés esconder complejidad. No cuando necesitás parámetros dinámicos (usá funciones o SPs) o cuando es un reporte one-off.

---

## 7. Vistas indexadas (materializadas)
**Carpeta:** `Index_vistas/` · **Script:** `script_vistas_indexadas.sql` · **Playbook:** `vistas-indexadas-en-sql-server.pdf`

**Concepto clave:** Una vista indexada **almacena físicamente el resultado** de la query (no solo la definición). En otras bases de datos se llama vista materializada. SQL Server la mantiene actualizada automáticamente cuando las tablas base cambian.

**¿Por qué importa?** Una vista normal ejecuta el `GROUP BY` con sus JOINs cada vez que la consultan. Si la consultan 500 veces por hora, son 500 veces el mismo cálculo desde cero. Es un trade-off clásico: ganás velocidad en lecturas a cambio de costo en escrituras (cada `INSERT/UPDATE/DELETE` en las tablas base tiene que actualizar también la vista).

**Sintaxis mínima:**
```sql
-- Paso 1: vista con SCHEMABINDING y schema completo en las referencias
CREATE VIEW VW_VentasPorPais
WITH SCHEMABINDING
AS
SELECT pa.PaisID, pa.NombrePais,
       SUM(p.Total) AS VentasTotales,
       COUNT_BIG(*) AS NumPedidos
FROM dbo.Pedidos p
JOIN dbo.Clientes c ON p.ClienteID = c.ClienteID
JOIN dbo.Paises pa  ON c.PaisID = pa.PaisID
GROUP BY pa.PaisID, pa.NombrePais;
GO

-- Paso 2: índice clustered único (esto es lo que materializa)
CREATE UNIQUE CLUSTERED INDEX IX_VW_VentasPorPais
ON VW_VentasPorPais(PaisID);
```

**Puntos finos / errores comunes:**
- `WITH SCHEMABINDING` **bloquea** modificaciones a las columnas de las tablas base usadas por la vista. Si intentás `ALTER TABLE Pedidos DROP COLUMN Total`, SQL Server lo rechaza. Es exactamente la protección que querés.
- Las referencias a tablas dentro de la vista **deben usar schema completo**: `dbo.Pedidos`, no `Pedidos`. Sin esto, la vista no se crea.
- Hasta que no crees el **índice clustered único**, la vista con SCHEMABINDING es solo una vista normal con restricciones extra. El índice es lo que la materializa.
- Regla del instructor: **mide primero, indexa después, nunca al revés.** No materialices vistas "por si acaso".

**Cuándo usarlo (y cuándo NO):** SÍ cuando hay alta frecuencia de lecturas + tablas base con baja frecuencia de escrituras + agregaciones pesadas + tiempo de respuesta crítico (dashboards). NO cuando las tablas base reciben muchas escrituras (el costo de mantenimiento supera el beneficio) o cuando la consulta corre pocas veces al día.

---

## 8. Columnas calculadas y columnas persistidas
**Carpeta:** `Columnas_Calculadas_vs_Computadas_persistidas/` · **Script:** `script_columnas_computadas.sql` · **Playbook:** `columnas-calculadas-y-columnas-computadas-persistidas.pdf`

**Concepto clave:** Una columna calculada es una **fórmula guardada como columna de la tabla**. Por defecto se recalcula al consultar; con `PERSISTED` el resultado se almacena en disco y solo se recalcula cuando cambian las columnas de las que depende.

**¿Por qué importa?** Resuelve el problema de **fórmulas duplicadas**: si "margen = (precio - costo)/precio*100" aparece en 20 scripts y mañana cambia la lógica, tenés que actualizar los 20. Con una columna calculada la fórmula vive en un solo lugar — la tabla — y todos los `SELECT *` la incluyen automáticamente con la lógica correcta.

**Sintaxis mínima:**
```sql
-- Columna calculada simple (no almacena, recalcula al consultar)
ALTER TABLE Productos
ADD PrecioConIVA AS (Precio * 1.21);

-- Columna calculada PERSISTED (almacena el resultado)
ALTER TABLE Productos
ADD MargenPorcentaje AS
    CASE WHEN Precio = 0 OR Costo IS NULL THEN NULL
         ELSE (Precio - Costo) * 100.0 / Precio
    END PERSISTED;

-- Cambiar fórmula = drop + add (no podés UPDATE ni ALTER directo)
ALTER TABLE Productos DROP COLUMN PrecioConIVA;
ALTER TABLE Productos ADD PrecioConIVA AS (Precio * 1.19);

-- Sobre una persistida sí podés crear índice
CREATE INDEX IX_Productos_Margen ON Productos(MargenPorcentaje);
```

**Puntos finos / errores comunes:**
- **No se puede hacer `UPDATE` sobre una columna calculada.** No tiene valor propio, su valor sale de la fórmula. Para cambiar la fórmula tenés que dropear y recrear.
- Para `PERSISTED` la expresión debe ser **determinista**: con los mismos inputs, siempre mismo output. `GETDATE()` y `NEWID()` no son deterministas, no funcionan en persistidas.
- En SSMS, las columnas calculadas aparecen con ícono distinto y la leyenda "calculado".
- **Ventaja oculta de PERSISTED:** podés crear **índices** sobre ella. Sin PERSISTED no se puede. Filtrar `WHERE MargenPorcentaje > 30` se vuelve instantáneo con índice.
- Validá divisiones por cero / NULLs con `CASE` antes de marcarla `PERSISTED` — el valor queda almacenado y un error en la fórmula se propaga a todos.

**Cuándo usarlo (y cuándo NO):** SÍ cuando la fórmula es estable, se reusa en muchas consultas, y querés un punto único de verdad. PERSISTED + índice cuando filtrás/ordenás por esa columna seguido. NO si la fórmula cambia frecuentemente (cada `ALTER TABLE` en producción cuesta) ni para cálculos de un único reporte.

---

## 9. Stored Procedures (SP)
**Carpeta:** `Store_Procedure_SQL/` · **Script:** `script_stored_procedures.sql` · **Playbook:** `stored-procedures-en-sql-server.pdf`

**Concepto clave:** Un SP es un **bloque de código SQL con nombre** guardado en la base de datos, que recibe parámetros y se ejecuta con `EXEC`. Es un "contrato": acepta inputs definidos, ejecuta una lógica fija y devuelve un resultado predecible.

**¿Por qué importa?** Centraliza procesos que hoy implican abrir 15 scripts y rezar para no equivocarse. Cuatro razones que se acumulan: (1) **rendimiento** — el plan de ejecución queda cacheado tras la primera corrida; (2) **mantenimiento** — la lógica vive en un solo lugar; (3) **seguridad** — das `EXECUTE` sin dar acceso a las tablas; (4) **reutilización** — lo llamás desde SSMS, una app, Power BI, una API u otro SP.

**Sintaxis mínima:**
```sql
CREATE OR ALTER PROCEDURE SP_ConsultarVentasPorPais
    @CodigoPais  CHAR(2) = NULL,
    @FechaInicio DATE    = NULL,
    @FechaFin    DATE    = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Valores por defecto: último año si no se pasan fechas
    SET @FechaFin    = ISNULL(@FechaFin, GETDATE());
    SET @FechaInicio = ISNULL(@FechaInicio, DATEADD(YEAR, -1, @FechaFin));

    SELECT pa.NombrePais, SUM(p.Total) AS Ventas
    FROM Pedidos p
    JOIN Clientes c ON p.ClienteID = c.ClienteID
    JOIN Paises pa  ON c.PaisID = pa.PaisID
    WHERE (@CodigoPais IS NULL OR pa.CodigoPais = @CodigoPais)
      AND p.FechaPedido BETWEEN @FechaInicio AND @FechaFin
    GROUP BY pa.NombrePais;
END;
GO

-- Ejecución por nombre (recomendado)
EXEC SP_ConsultarVentasPorPais @CodigoPais = 'AR',
                               @FechaInicio = '2024-01-01',
                               @FechaFin    = '2024-12-31';
-- Ejecución por posición
EXEC SP_ConsultarVentasPorPais 'CL', '2024-01-01', '2024-12-31';
```

**Puntos finos / errores comunes:**
- Convención de prefijos: `SP_` para procedimientos, `VW_` para vistas, `TR_` para triggers.
- **Siempre poné `SET NOCOUNT ON`** al inicio. Suprime los mensajes "N filas afectadas" que viajan por red. Una línea, sin costo, alto impacto si una app ejecuta el SP en loop.
- Parámetros con **valores por defecto** convierten un SP rígido en una herramienta flexible — un SP único sirve para el analista, el reporte mensual y el dashboard.
- `CREATE OR ALTER PROCEDURE` (desde SQL Server 2016) es lo que vas a usar en el día a día: si no existe lo crea, si existe lo modifica.
- Para dar permisos: `GRANT EXECUTE ON SP_X TO usuario;`. Para ver código ajeno: `EXEC sp_helptext 'SP_X';`.

**Cuándo usarlo (y cuándo NO):** SÍ para coordinar múltiples operaciones (cierre de mes, alta de pedido atómica), para automatizar reportes parametrizados, para exponer lógica de forma controlada. NO para queries one-off de análisis exploratorio.

---

## 10. Triggers
**Carpeta:** `Trigger/` · **Script:** `script_triggers.sql` · **Playbook:** `triggers-en-sql-server.pdf`

**Concepto clave:** Un trigger es **código que se ejecuta solo**, automáticamente, cuando ocurre un `INSERT`, `UPDATE` o `DELETE` en una tabla. Nadie lo invoca con `EXEC` — se dispara por su cuenta. Puede ser `AFTER` (después del evento) o `INSTEAD OF` (en lugar del evento).

**¿Por qué importa?** La analogía del instructor: son **como alarmas de incendio**. Indispensables en el momento justo, pero un problema serio si se disparan cuando no deben. Bien usados, automatizan auditoría sin que nadie tenga que hacer nada. Mal usados, convierten cada `INSERT` en una cadena oculta de efectos secundarios que nadie recuerda.

**Sintaxis mínima:**
```sql
-- Tabla de auditoría primero
CREATE TABLE AuditoriaPedidos (
    AuditoriaID    INT IDENTITY PRIMARY KEY,
    PedidoID       INT,
    Accion         VARCHAR(10),
    EstadoAntes    VARCHAR(20),  EstadoDespues VARCHAR(20),
    TotalAntes     DECIMAL(10,2), TotalDespues DECIMAL(10,2),
    Usuario        SYSNAME DEFAULT SUSER_SNAME(),
    Fecha          DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER TR_AuditarPedidos
ON Pedidos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditoriaPedidos
        (PedidoID, Accion, EstadoAntes, EstadoDespues, TotalAntes, TotalDespues)
    SELECT
        COALESCE(i.PedidoID, d.PedidoID),
        CASE WHEN i.PedidoID IS NOT NULL AND d.PedidoID IS NOT NULL THEN 'UPDATE'
             WHEN i.PedidoID IS NOT NULL THEN 'INSERT'
             ELSE 'DELETE' END,
        d.Estado, i.Estado,
        d.Total,  i.Total
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.PedidoID = d.PedidoID;
END;
```

**Puntos finos / errores comunes:**
- Las tablas mágicas `INSERTED` y `DELETED` existen solo dentro del trigger. **`INSERT`** → INSERTED tiene filas, DELETED vacía. **`DELETE`** → al revés. **`UPDATE`** → ambas tienen filas (DELETED = antes, INSERTED = después).
- **El trigger se ejecuta UNA VEZ POR STATEMENT, no por fila.** Un `UPDATE` que toca 10.000 filas dispara el trigger una sola vez con 10.000 filas en INSERTED/DELETED. Si lo escribís pensando "fila por fila", el rendimiento se desploma — siempre escribilo con operaciones sobre conjuntos.
- **Invisibilidad**: el trigger no aparece en el código de la app. Útil para auditoría (nadie puede saltársela), peligroso para todo lo demás (errores vienen "de la nada").
- **Encadenamiento**: un trigger puede disparar otro, hasta 32 niveles. Cuidado con bucles.
- `INSTEAD OF` es el truco para hacer escribibles vistas que normalmente no lo son (vistas con `GROUP BY`, etc.) — interceptás el `INSERT` y decidís a dónde redirigirlo.

**Cuándo usarlo (y cuándo NO):** SÍ para auditoría (quién cambió qué y cuándo) y para proteger integridad de datos. NO para lógica de negocio compleja (eso es de SPs), NO para validaciones que se resuelven con `CHECK` constraints, NO para replicación en tiempo real, NO para cálculos que pueden vivir en columnas calculadas. Criterio del instructor: trigger = auditoría e integridad; cualquier otra cosa → herramienta distinta.

---

## Temas pendientes por incorporar

> Este nivel sigue creciendo. Cuando subas un playbook nuevo, agregalo acá y luego promovelo a una sección numerada arriba (con concepto clave, ¿por qué importa?, sintaxis, puntos finos, cuándo usarlo).

- [ ] *(agregá acá el siguiente tema cuando lo tengas listo)*

### Pista para futuros temas

Cuando organices la siguiente tanda, considerá el flujo natural que sigue al estado actual: **funciones (escalares, tabla, multistatement)**, **window functions** (`OVER`, `PARTITION BY`, `ROW_NUMBER`, `LAG`/`LEAD`), **transacciones e `ISOLATION LEVEL`**, **MERGE**, **TVPs y procedimientos atómicos** (como `usp_CrearPedido` de `ddl_v2.sql`), **tablas temporales del sistema**, **índices avanzados** (covering, filtrados, columnstore), **Query Store / planes de ejecución**. No es prescripción — es la lista corta de lo que viene después en un programa típico de "SQL Server para analistas que se profesionalizan".

---

> **Volver al manual básico:** [`../sql_basico/MANUAL.md`](../sql_basico/MANUAL.md)
