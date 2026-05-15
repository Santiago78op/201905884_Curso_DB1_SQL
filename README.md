# PT3_FINAL — Curso de SQL Server para Analistas de Datos

Material del curso *Curso de SQL Server para Analistas de Datos* (Platzi), organizado como una **biblioteca de temas** sobre el caso de estudio `TiendaLatam`. No es una aplicación: el "producto" son los scripts T-SQL y los playbooks PDF que los acompañan. Todo en español, identificadores incluidos.

> Requisito: **SQL Server 2019+** con SSMS o Azure Data Studio. Algunos scripts asumen la base `TiendaLatam` ya creada — ver [Orden de ejecución](#orden-de-ejecución).

---

## Estructura

```
PT3_FINAL/
├── ddl/                # Esquema TiendaLatam (v1 y v2) + carga CSV
├── manual/             # Walkthrough didáctico de v2
├── sql_basico/         # 21 temas: del CREATE DATABASE al reporte de ventas
├── sql_avanzado/       # 11 temas: JOINs avanzados, CTEs, vistas, SPs, triggers
└── sql_vault/          # Vault tipo Obsidian (manuales temáticos + progreso)
```

| Carpeta | Qué contiene | Para qué sirve |
|---|---|---|
| [`ddl/`](./ddl) | `ddl.sql` (v1 académico), `ddl_v2.sql` (v2 producción), `bulk_insert.sql` (CSV → v1), `script.sql` (ejercicio `COUNTRY`) | Construir y poblar la base |
| [`manual/`](./manual) | `ddl_v2_explicacion.md` | Justificación didáctica del DDL v2 — leer antes de defender una decisión de v2 |
| [`sql_basico/`](./sql_basico) | 20 temas + [`MANUAL.md`](./sql_basico/MANUAL.md) consolidado | Practicar fundamentos |
| [`sql_avanzado/`](./sql_avanzado) | 10 temas + [`MANUAL.md`](./sql_avanzado/MANUAL.md) **(WIP)** | Profundizar |
| [`sql_vault/`](./sql_vault) | `MOC.md`, `Bienvenido.md`, `manuales/`, `progreso/` | Notas estilo Obsidian — manuales temáticos y bitácora de avance |

> 📘 **Atajo a los manuales:** [Manual Básico](./sql_basico/MANUAL.md) · [Manual Avanzado (WIP)](./sql_avanzado/MANUAL.md). Cada uno consolida los conceptos de los playbooks PDF de su nivel.

---

## Orden de ejecución

Elegir **una** de las dos rutas para `TiendaLatam`. **No mezclar v1 y v2** — son esquemas independientes.

### Ruta v1 (académica, con carga desde CSV)

1. Ejecutar [`ddl/ddl.sql`](./ddl/ddl.sql) — crea la base y las 9 tablas en `dbo`.
2. Descomprimir los CSVs (zip en [`sql_basico/Create_DB/tiendalatam_csv.zip`](./sql_basico/Create_DB) o [`sql_avanzado/Instalacion_SQL_Server_SSMS/tiendalatam__csv.zip`](./sql_avanzado/Instalacion_SQL_Server_SSMS)) a `C:\TiendaLatam_CSV\`. La ruta está **hardcodeada** en el script; si los CSVs no están ahí, el `BULK INSERT` falla.
3. Ejecutar [`ddl/bulk_insert.sql`](./ddl/bulk_insert.sql) — el orden de carga importa: `Paises → Categorias → TiposCliente → Sucursales → Empleados → Clientes → Productos → Pedidos → DetallePedidos`.

### Ruta v2 (producción, sin loader)

1. Ejecutar [`ddl/ddl_v2.sql`](./ddl/ddl_v2.sql) — idempotente de punta a punta, seguro de re-ejecutar. Crea schemas por dominio (`geo`, `catalogo`, `rrhh`, `ventas`, `inventario`, `auditoria`, `historia`), tablas temporales, vista indexada, TVP, SP atómico y seeds por `MERGE`.
2. Leer [`manual/ddl_v2_explicacion.md`](./manual/ddl_v2_explicacion.md) en paralelo — explica el porqué de cada decisión.

> No hay loader de CSVs para v2: la forma de columnas difiere (`Productos.MonedaID`, `Pedidos.EstadoID`, `Sucursales.CodigoSucursal`, etc.).

### Ejercicio suelto

[`ddl/script.sql`](./ddl/script.sql) — usa una tabla `COUNTRY`, **no depende de TiendaLatam**. Sirve para practicar subqueries, `ALL`, `HAVING` y correlated subqueries.

---

## Índice de temas — `sql_basico/`

Fundamentos. Cada fila enlaza al **concepto** dentro del [Manual Básico](./sql_basico/MANUAL.md) y a la **carpeta** con el script + playbook PDF.

| # | Tema | Concepto en MANUAL | Carpeta |
|---|---|---|---|
| 1 | Conoce TiendaLatam | [§1](./sql_basico/MANUAL.md#1-conoce-tiendalatam) | [`Intro/`](./sql_basico/Intro) |
| 2 | Cómo navegar PostgreSQL | [§2](./sql_basico/MANUAL.md#2-cómo-navegar-postgresql) | [`PostgresSQL/`](./sql_basico/PostgresSQL) |
| 3 | Entidades, atributos y conexiones | [§3](./sql_basico/MANUAL.md#3-entidades-atributos-y-conexiones) | [`Entidades_atributos_conexiones/`](./sql_basico/Entidades_atributos_conexiones) |
| 4 | Tipos de relaciones entre tablas | [§4](./sql_basico/MANUAL.md#4-tipos-de-relaciones-entre-tablas) | [`Tipos_relaciones_tablas/`](./sql_basico/Tipos_relaciones_tablas) |
| 5 | Diagrama ER con Crow's Foot | [§5](./sql_basico/MANUAL.md#5-diagrama-er-con-notación-crows-foot) | [`Diagrama_ER _Crows_foot/`](./sql_basico/Diagrama_ER%20_Crows_foot) |
| 6 | Normalización | [§6](./sql_basico/MANUAL.md#6-normalización-de-tabla-plana-a-modelo-limpio) | [`Nomalizacion_tabla/`](./sql_basico/Nomalizacion_tabla) |
| 7 | `CREATE DATABASE` TiendaLatam | [§7](./sql_basico/MANUAL.md#7-crea-la-base-de-datos-tiendalatam) | [`Create_DB/`](./sql_basico/Create_DB) |
| 8 | `CREATE TABLE` + PK + restricciones | [§8](./sql_basico/MANUAL.md#8-create-table-con-pk-y-restricciones) | [`Create_table/`](./sql_basico/Create_table) |
| 9 | Tipos de datos en SQL | [§9](./sql_basico/MANUAL.md#9-tipos-de-datos-en-sql) | [`Tipos_Datos/`](./sql_basico/Tipos_Datos) |
| 10 | Claves foráneas e integridad referencial | [§10](./sql_basico/MANUAL.md#10-claves-foráneas-e-integridad-referencial) | [`Clave_foranea/`](./sql_basico/Clave_foranea) |
| 11 | `ALTER TABLE` sin perder datos | [§11](./sql_basico/MANUAL.md#11-alter-table-modificar-tablas-sin-perder-datos) | [`Alter_table/`](./sql_basico/Alter_table) |
| 12 | `INSERT` | [§12](./sql_basico/MANUAL.md#12-insert-cargar-datos-en-tablas) | [`Insert/`](./sql_basico/Insert) |
| 13 | `UPDATE` (regla del WHERE) | [§13](./sql_basico/MANUAL.md#13-update-modificar-registros-la-regla-del-where) | [`Update/`](./sql_basico/Update) |
| 14 | `DELETE` + borrado lógico | [§14](./sql_basico/MANUAL.md#14-delete-borrar-filas-o-desactivarlas-borrado-lógico) | [`Delete/`](./sql_basico/Delete) |
| 15 | `SELECT` básico + operadores | [§15](./sql_basico/MANUAL.md#15-select-básico-proyección-where-y-operadores) | [`Select/`](./sql_basico/Select) |
| 16 | `ORDER BY` + `LIMIT` | [§16](./sql_basico/MANUAL.md#16-order-by-y-limit-ordenar-y-paginar) | [`Order_Limit/`](./sql_basico/Order_Limit) |
| 17 | `GROUP BY` + agregación | [§17](./sql_basico/MANUAL.md#17-group-by-y-funciones-de-agregación) | [`Group_by_Func_agregacion/`](./sql_basico/Group_by_Func_agregacion) |
| 18 | `HAVING` | [§18](./sql_basico/MANUAL.md#18-having-filtrar-después-de-agrupar) | [`Having/`](./sql_basico/Having) |
| 19 | Funciones de texto/fecha/número | [§19](./sql_basico/MANUAL.md#19-funciones-de-texto-fecha-y-número) | [`Func_texto/`](./sql_basico/Func_texto) |
| 20 | `INNER JOIN` y `LEFT JOIN` | [§20](./sql_basico/MANUAL.md#20-inner-join-y-left-join) | [`Inner_Left_Join/`](./sql_basico/Inner_Left_Join) |
| — | Reporte de ventas (integrador) | (sin sección, solo script) | [`Reportes_sql/`](./sql_basico/Reportes_sql) |

---

## Índice de temas — `sql_avanzado/` *(WIP)*

> 📌 El nivel avanzado sigue creciendo. Los temas listados ya están con concepto + script + playbook. Los próximos se irán incorporando al [Manual Avanzado](./sql_avanzado/MANUAL.md) en la sección "Temas pendientes".

| # | Tema | Concepto en MANUAL | Carpeta |
|---|---|---|---|
| 0 | Instalación SQL Server + SSMS | [§0](./sql_avanzado/MANUAL.md#0-instalación-sql-server--ssms) | [`Instalacion_SQL_Server_SSMS/`](./sql_avanzado/Instalacion_SQL_Server_SSMS) |
| 1 | `INNER JOIN` vs `LEFT JOIN` | [§1](./sql_avanzado/MANUAL.md#1-inner-join-vs-left-join) | [`Inner_vs_Left_JOIN/`](./sql_avanzado/Inner_vs_Left_JOIN) |
| 2 | `RIGHT`, `FULL OUTER`, `CROSS JOIN` | [§2](./sql_avanzado/MANUAL.md#2-right-join-full-outer-join-y-cross-join) | [`right_full_cross_JOIN/`](./sql_avanzado/right_full_cross_JOIN) |
| 3 | Subqueries en `WHERE` / `EXISTS` | [§3](./sql_avanzado/MANUAL.md#3-subqueries-en-where-escalar-lista-exists) | [`Subquery_Where_Exists/`](./sql_avanzado/Subquery_Where_Exists) |
| 4 | Subqueries en `FROM` y `SELECT` | [§4](./sql_avanzado/MANUAL.md#4-subqueries-en-from-y-select) | [`Subquery_From_vs_Select/`](./sql_avanzado/Subquery_From_vs_Select) |
| 5 | CTEs con `WITH` | [§5](./sql_avanzado/MANUAL.md#5-common-table-expressions-ctes) | [`Common_Table_WITH/`](./sql_avanzado/Common_Table_WITH) |
| 6 | Vistas (`VIEW`) | [§6](./sql_avanzado/MANUAL.md#6-vistas-views) | [`Vistas/`](./sql_avanzado/Vistas) |
| 7 | Vistas indexadas | [§7](./sql_avanzado/MANUAL.md#7-vistas-indexadas-materializadas) | [`Index_vistas/`](./sql_avanzado/Index_vistas) |
| 8 | Columnas calculadas vs persistidas | [§8](./sql_avanzado/MANUAL.md#8-columnas-calculadas-y-columnas-persistidas) | [`Columnas_Calculadas_vs_Computadas_persistidas/`](./sql_avanzado/Columnas_Calculadas_vs_Computadas_persistidas) |
| 9 | Stored Procedures | [§9](./sql_avanzado/MANUAL.md#9-stored-procedures-sp) | [`Store_Procedure_SQL/`](./sql_avanzado/Store_Procedure_SQL) |
| 10 | Triggers | [§10](./sql_avanzado/MANUAL.md#10-triggers) | [`Trigger/`](./sql_avanzado/Trigger) |
| … | *Próximos temas* | [Pendientes →](./sql_avanzado/MANUAL.md#temas-pendientes-por-incorporar) | — |

---

## Convenciones del repo

Estas no son preferencias genéricas — son decisiones que el código ya toma de forma consistente. Cualquier script nuevo debe respetarlas.

- **Idioma:** identificadores, comentarios y `PRINT` en español. `Paises`, `Sucursales`, `Pedidos`, `DetallePedidos`. No anglicizar.
- **v1 vs v2 separadas:** no inyectar idempotencia de v2 en v1, ni quitársela a v2. Si un cambio aplica a ambas, editar las dos.
- **Idempotencia (v2):** todo `CREATE TABLE` envuelto en `IF OBJECT_ID(N'esquema.Tabla', N'U') IS NULL`; índices con `IF NOT EXISTS (SELECT 1 FROM sys.indexes ...)`.
- **Constraints con nombre explícito:** `PK_`, `FK_<Hijo>_<Padre>`, `UQ_`, `CK_`, `DF_<Tabla>_<Columna>`. Nunca dejar que SQL Server autonombre.
- **Schemas por dominio (v2):** `geo` (países/sucursales), `catalogo` (productos/lookups), `rrhh` (empleados), `ventas` (clientes/pedidos), `inventario` (movimientos), `historia` (historiales de temporales), `auditoria` (reservado).
- **Tipos monetarios:** `DECIMAL(10,2)` en v1; `DECIMAL(12,4)` en v2 con `Subtotal AS (...) PERSISTED` en `ventas.DetallePedidos`.
- **El total del pedido vive en la vista indexada** `ventas.vw_PedidoTotales`, no en una columna escalar. No re-añadir `Pedidos.Total`.
- **Inventario event-sourced (v2):** sin columna escalar `Stock`; el stock se calcula agregando `inventario.Movimientos`. El SP `ventas.usp_CrearPedido` inserta SALIDA (`TipoMovID = 2`) por línea en la misma transacción.
- **Estados de pedido:** lookup `catalogo.EstadosPedido` poblado con `MERGE` (v2), no `CHECK IN (...)` (v1).
- **Batches:** `GO` al final de cada DDL que lo necesita; `SET NOCOUNT ON; SET XACT_ABORT ON;` al inicio de SPs.

---

## El vault (`sql_vault/`)

Notas estilo Obsidian — no son ejecutables, son tu cuaderno:

- [`Bienvenido.md`](./sql_vault/Bienvenido.md) — punto de entrada.
- [`MOC.md`](./sql_vault/MOC.md) — Map of Content, índice maestro.
- [`manuales/`](./sql_vault/manuales) — manuales temáticos que se van actualizando por tema.
- [`progreso/`](./sql_vault/progreso) — bitácora de aprendizaje.

---

## Verificación

No hay tests ni CI. La "verificación" es manual:

- **v1:** los `SELECT` finales contra `INFORMATION_SCHEMA`, `sys.foreign_keys` y `sys.indexes` al pie de [`ddl/ddl.sql`](./ddl/ddl.sql).
- **v2:** el §10 de [`ddl/ddl_v2.sql`](./ddl/ddl_v2.sql) imprime `=== Tablas creadas ===`, conteos y muestras. Re-ejecutar el script entero debe ser un no-op salvo por esos `SELECT`.
