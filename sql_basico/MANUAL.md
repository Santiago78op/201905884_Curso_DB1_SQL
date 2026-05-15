# Manual de SQL — Nivel Básico

> Síntesis de conceptos por tema, basada en los playbooks PDF del curso *SQL Server para Analistas de Datos* aplicados al caso de estudio `TiendaLatam`.
>
> Cada sección tiene la misma estructura: **concepto clave**, **por qué importa**, **sintaxis mínima**, **puntos finos / errores comunes**, **cuándo usarlo (y cuándo no)**. Está pensado como referencia rápida, no como reemplazo del playbook completo.

---

## Tabla de contenidos

**Modelado conceptual**
1. [Conoce TiendaLatam](#1-conoce-tiendalatam)
2. [Cómo navegar PostgreSQL](#2-cómo-navegar-postgresql)
3. [Entidades, atributos y conexiones](#3-entidades-atributos-y-conexiones)
4. [Tipos de relaciones entre tablas](#4-tipos-de-relaciones-entre-tablas)
5. [Diagrama ER con notación Crow's Foot](#5-diagrama-er-con-notación-crows-foot)
6. [Normalización: de tabla plana a modelo limpio](#6-normalización-de-tabla-plana-a-modelo-limpio)

**DDL — definición del esquema**
7. [Crea la base de datos TiendaLatam](#7-crea-la-base-de-datos-tiendalatam)
8. [CREATE TABLE con PK y restricciones](#8-create-table-con-pk-y-restricciones)
9. [Tipos de datos en SQL](#9-tipos-de-datos-en-sql)
10. [Claves foráneas e integridad referencial](#10-claves-foráneas-e-integridad-referencial)
11. [ALTER TABLE: modificar tablas sin perder datos](#11-alter-table-modificar-tablas-sin-perder-datos)

**DML — cargar y modificar datos**
12. [INSERT: cargar datos en tablas](#12-insert-cargar-datos-en-tablas)
13. [UPDATE: modificar registros (la regla del WHERE)](#13-update-modificar-registros-la-regla-del-where)
14. [DELETE: borrar filas o desactivarlas (borrado lógico)](#14-delete-borrar-filas-o-desactivarlas-borrado-lógico)

**DQL — consultar**
15. [SELECT básico: proyección, WHERE y operadores](#15-select-básico-proyección-where-y-operadores)
16. [ORDER BY y LIMIT: ordenar y paginar](#16-order-by-y-limit-ordenar-y-paginar)
17. [GROUP BY y funciones de agregación](#17-group-by-y-funciones-de-agregación)
18. [HAVING: filtrar después de agrupar](#18-having-filtrar-después-de-agrupar)
19. [Funciones de texto, fecha y número](#19-funciones-de-texto-fecha-y-número)
20. [INNER JOIN y LEFT JOIN](#20-inner-join-y-left-join)

---

## 1. Conoce TiendaLatam
**Carpeta:** `Intro/` · **Playbook:** `playbook-conoce-tiendalatam.pdf`

**Concepto clave:** TiendaLatam es un retail multi-país modelado en exactamente 9 tablas que cubren contexto (Paises, Categorias, TiposCliente), operación (Sucursales, Empleados, Clientes, Productos) y ventas (Pedidos, DetallePedidos).

**¿Por qué importa?** Si guardás todo en una sola tabla, repetís la información del cliente y la sucursal cada vez que alguien compra varios productos. Eso genera inconsistencias, errores al actualizar y desperdicio. Separar en 9 tablas conectadas por identificadores resuelve eso desde el diseño.

**Modelo:**
```
-- Cada tabla representa "una cosa" del negocio.
-- Las _id (cliente_id, pais_id, ...) son los puentes entre tablas.
-- Pedidos guarda quién/cuándo/dónde de la venta.
-- DetallePedidos guarda qué productos y a qué precio en ese momento.
```

**Puntos finos / errores comunes:**
- Tres tablas son "diccionarios" del negocio (Paises, Categorias, TiposCliente) y se crean primero porque todo lo demás depende de ellas.
- En `DetallePedidos` el precio se guarda al momento de la venta, no se calcula con el precio actual del producto — los precios cambian y el historial debe ser fiel.
- Empleados no se borra: se marca como inactivo (borrado lógico).
- Antes de consultar, sabé responder tres preguntas por tabla: ¿qué guarda?, ¿qué columna `_id` la conecta con otra?, ¿qué representa una fila?

**Cuándo usarlo (y cuándo NO):** Es el caso de estudio del curso completo; toda consulta posterior asume este modelo. No es un modelo genérico — está pensado para enseñar.

---

## 2. Cómo navegar PostgreSQL
**Carpeta:** `PostgresSQL/` · **Playbook:** `playbook-como-navegar-postgresql.pdf`

**Concepto clave:** PostgreSQL organiza todo en cuatro niveles jerárquicos: Cluster → Base de datos → Esquema → Tablas.

**¿Por qué importa?** El error más frecuente al empezar es ejecutar código en la base de datos equivocada. Si estás conectado a `postgres` pero tus tablas viven en `tienda_latam`, el motor no las encuentra y el resultado es un error o una respuesta vacía sin explicación.

**Sintaxis mínima:**
```sql
-- Para verificar en qué base de datos estás trabajando:
SELECT current_database();
```

**Puntos finos / errores comunes:**
- El cluster es la instalación completa (lo ves como "PostgreSQL 18"); contiene varias bases de datos independientes.
- El esquema por defecto se llama `public` y para este curso no necesitás cambiarlo.
- pgAdmin tiene muchas secciones (roles, extensiones, disparadores) que no se usan en este curso — sólo Base de datos, Esquema y Tablas.
- Antes de ejecutar cualquier cosa, mirá la parte superior del Query Tool para confirmar la base activa.

**Cuándo usarlo (y cuándo NO):** Es orientación de herramienta (pgAdmin), no contenido SQL. Útil al principio y cuando reabrís el entorno tras un descanso. *Nota: el resto del curso usa SQL Server / SSMS — este capítulo es contextual.*

---

## 3. Entidades, atributos y conexiones
**Carpeta:** `Entidades_atributos_conexiones/` · **Playbook:** `playbook-entidades-atributos-y-conexiones.pdf`

**Concepto clave:** Diseñar una base relacional son cuatro decisiones: qué entidades existen, qué atributos tienen, cómo se identifica cada registro (clave primaria) y cómo se conectan (clave foránea).

**¿Por qué importa?** Sin estas cuatro herramientas mentales, terminás copiando información por toda la base, eligiendo malas claves primarias (como el correo, que cambia) y rompiendo la integridad cada vez que actualizás algo. El orden es: primero identificás la entidad, después construís la tabla.

**Modelo:**
```
-- Cliente como entidad: tiene atributos simples (precio),
-- compuestos (nombre + apellido), derivados (edad calculable
-- desde fecha_nac) y nunca multivaluados en una sola celda.
-- Identidad: cliente_id (clave sustituta).
-- Conexión:  cliente.pais_id apunta a paises.pais_id.
```

**Puntos finos / errores comunes:**
- Una entidad pasa el test si: existe por sí sola, necesitás guardar datos sobre ella, y puede haber más de una.
- No uses el correo como clave primaria: la gente lo cambia, lo comparte o lo tipea mal — usá una clave sustituta (`cliente_id`).
- En una relación 1:N, la clave foránea va siempre en el lado de "muchos" (la FK de país va en Sucursales, no al revés).
- Una misma columna puede ser PK en su tabla y FK en otra: `pedido_id` es PK en Pedidos y FK en DetallePedidos. Lo que cambia es la perspectiva.
- Excepción a los atributos derivados: el subtotal de DetallePedidos sí se guarda porque los precios cambian y el historial debe ser fiel.

**Cuándo usarlo (y cuándo NO):** Antes de crear la primera tabla, siempre. Es la base conceptual de toda la fase de diseño.

---

## 4. Tipos de relaciones entre tablas
**Carpeta:** `Tipos_relaciones_tablas/` · **Playbook:** `playbook-tipos-de-relaciones-entre-tablas.pdf`

**Concepto clave:** Hay tres tipos de relaciones (1:1, 1:N, N:M) y se descubren con la técnica de las dos preguntas: hacés la misma pregunta en las dos direcciones.

**¿Por qué importa?** Si confundís el tipo de relación, ponés la FK en el lado equivocado o, peor, no creás la tabla intermedia que una relación N:M necesita. Eso te obliga después a meter columnas vacías (`producto_1`, `producto_2`, `producto_3`) o a duplicar datos del pedido en cada línea.

**Modelo:**
```
-- 1:N → un país, muchas sucursales
--       FK pais_id vive en Sucursales

-- N:M → un pedido tiene muchos productos
--       un producto está en muchos pedidos
-- Se resuelve con una tabla intermedia: DetallePedidos
-- DetallePedidos (detalle_id PK, pedido_id FK, producto_id FK, cantidad, precio)
```

**Puntos finos / errores comunes:**
- La técnica: dos noes → 1:1; un sí y un no → 1:N; dos síes → N:M. No hay más casos.
- 1:1 son raras (información sensible separada, por ejemplo `perfil_empleado`); en TiendaLatam no hay ninguna.
- En N:M, la tabla intermedia no es un "conector vacío" — guarda los atributos que pertenecen a la combinación (cantidad, precio del momento).
- El precio en DetallePedidos es del momento de la venta, no el precio actual. Si el smartphone hoy sube, el recibo de María no cambia.

**Cuándo usarlo (y cuándo NO):** Cuando dudás de dónde poner una FK o si necesitás una tabla intermedia. Si ya tenés el modelo claro, pasá a diagramarlo.

---

## 5. Diagrama ER con notación Crow's Foot
**Carpeta:** `Diagrama_ER _Crows_foot/` · **Playbook:** `playbook-construir-el-diagrama-er-con-notacion-crows-foot.pdf`

**Concepto clave:** Crow's Foot ("pata de cuervo") es la notación visual estándar para documentar relaciones entre tablas: línea vertical = uno, pata de cuervo = muchos, círculo = cero (opcional).

**¿Por qué importa?** Cuando hay 9 tablas conectadas, explicarlo con palabras se vuelve imposible. El diagrama te permite ver toda la estructura de un vistazo, comunicar con gente no técnica, y descubrir errores de diseño antes de escribir una sola línea de código.

**Notación:**
```
Paises  |———o<  Sucursales
"Un país tiene cero o muchas sucursales,
 y cada sucursal pertenece a exactamente un país"

Pedidos  ————<  DetallePedidos  >————  Productos
(la N:M se resuelve con tabla intermedia)
```

**Puntos finos / errores comunes:**
- La FK siempre vive del lado donde está la pata de cuervo.
- Nunca debería haber pata de cuervo en los dos extremos de una línea directa: si la ves, falta la tabla intermedia.
- Se construye en capas: primero tablas base (Paises, Categorias, TiposCliente), luego operativas (Sucursales, Productos, Clientes, Empleados), después Pedidos como nodo central, y por último DetallePedidos.
- Errores típicos: FK en el lado equivocado, falta tabla intermedia en N:M, entidad sin clave primaria, conexiones incompletas (Pedidos tiene 3 FKs — dibujá las tres).

**Cuándo usarlo (y cuándo NO):** Después de identificar entidades y antes de escribir DDL. No reemplaza al modelo conceptual — lo formaliza.

---

## 6. Normalización: de tabla plana a modelo limpio
**Carpeta:** `Nomalizacion_tabla/` · **Playbook:** `playbook-normalizacion_-de-una-tabla-plana-a-un-modelo-limpio.pdf` · **Hoja:** `normalizacion.xlsx`

**Concepto clave:** Las tres formas normales son tres reglas que, aplicadas en orden, validan que tu diseño no tiene datos repetidos, dependencias parciales ni dependencias transitivas.

**¿Por qué importa?** Una tabla gigante "con todo junto" parece fácil al principio, pero en cuanto los datos crecen aparecen inconsistencias: la Laptop HP con dos precios distintos, "Buenos Aires" y "Bs. As." como ciudades diferentes, columnas `producto_1`, `producto_2` vacías. Las formas normales te evitan ese dolor.

**Reglas:**
```
1FN → cada celda un solo valor (separar Pedidos de DetallePedidos)
2FN → cada columna depende de la llave COMPLETA
       (nombre del producto va a tabla Productos, no a DetallePedidos)
3FN → nada depende de algo que no sea la llave
       (código postal depende de Ciudad, no del Cliente
        → tabla CodigosPostales separada)
```

**Puntos finos / errores comunes:**
- 1FN resuelve grupos repetidos (`producto_1`, `producto_2`, ...): una fila por cada producto vendido.
- 2FN sólo aplica cuando la PK es compuesta — si la PK es una sola columna, automáticamente la cumplís.
- 3FN ataca la dependencia transitiva: en `clientes(cliente_id, ciudad, codigo_postal)`, el código postal depende de la ciudad, no del cliente.
- Hay un cuarto problema fuera de las formas normales pero igual de roto: variantes de escritura ("Buenos Aires" vs "Bs. As."). Se resuelve con tablas de referencia para que sólo exista una versión válida.
- Pregunta de duda común ("¿no es más complicado tener siete tablas?"): la simplicidad de una tabla gigante es aparente — colapsa al primer crecimiento real.

**Cuándo usarlo (y cuándo NO):** Como check final antes de pasar a DDL. Si una tabla viola alguna forma normal, paralo y reestructurá.

---

## 7. Crea la base de datos TiendaLatam
**Carpeta:** `Create_DB/` · **Script:** `creacion-bbdd-tiendalatam_script.sql` · **Playbook:** `crea-la-base-de-datos-tiendalatam.pdf` · **Datos:** `tiendalatam_csv.zip`

**Concepto clave:** `CREATE DATABASE` es una línea de SQL, pero el paso crítico es conectarse a la base correcta antes de crear tablas.

**¿Por qué importa?** Si abrís el Query Tool desde la pantalla general de pgAdmin, por defecto estás conectado a `postgres`, no a `tienda_latam`. Si ejecutás código ahí, las tablas se crean en el lugar equivocado y la consulta posterior falla sin explicación clara.

**Sintaxis mínima:**
```sql
CREATE DATABASE tienda_latam;

-- Hábito que evita el error más frecuente:
SELECT current_database();
-- Si no dice tienda_latam, abrí el Query Tool desde
-- esa base de datos en el navegador de objetos.
```

**Puntos finos / errores comunes:**
- Para ejecutar, seleccionás la línea y F5 o el botón de play.
- Después de crear, hacé click derecho en el servidor → Refresh para verla en el navegador.
- Hay que abrir el Query Tool desde `tienda_latam` (click derecho sobre la base → Query Tool), no desde la pantalla general.
- La carga de CSVs se hace con el asistente de pgAdmin: click derecho en la tabla → Import/Export Data, activar Header en Options, y respetar el orden padre → hija.

**Cuándo usarlo (y cuándo NO):** Una sola vez por instalación de la base. El hábito de `SELECT current_database()` sí — cada vez que abras pgAdmin.

---

## 8. CREATE TABLE con PK y restricciones
**Carpeta:** `Create_table/` · **Script:** `create-table.sql` · **Playbook:** `playbook-create-table-con-claves-primarias-y-restricciones.pdf`

**Concepto clave:** Una tabla sin restricciones es una hoja de cálculo disfrazada; las restricciones (`PRIMARY KEY`, `NOT NULL`, `UNIQUE`, `DEFAULT`) son las que la convierten en una base de datos confiable.

**¿Por qué importa?** Sin restricciones, cualquier dato entra: clientes sin nombre, dos clientes con el mismo correo, fechas vacías. El error aparece recién cuando alguien corre un reporte y los números no cierran. Las restricciones lo bloquean al momento de insertar.

**Sintaxis mínima:**
```sql
CREATE TABLE clientes (
    cliente_id      INTEGER     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          TEXT        NOT NULL,
    correo          VARCHAR(100) NOT NULL UNIQUE,
    telefono        VARCHAR(20),
    fecha_registro  DATE        NOT NULL DEFAULT CURRENT_DATE,
    activo          BOOLEAN     NOT NULL DEFAULT TRUE,
    tipo_cliente_id INTEGER     NOT NULL
);
```

**Puntos finos / errores comunes:**
- Cada columna se separa con coma; la última no lleva coma; la instrucción termina con `;`.
- Hay dos formas de PK autoincremental: `SERIAL PRIMARY KEY` (corta, antigua) y `INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY` (recomendada, estándar moderno). En este curso vas a ver las dos.
- `NOT NULL` + `UNIQUE` se combinan en la misma columna; `DEFAULT` provee el valor cuando no lo especificás al insertar.
- Para verificar lo creado: `SELECT table_name, column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_schema = 'public'`.

**Cuándo usarlo (y cuándo NO):** Siempre que necesites crear una tabla. Nunca crees una tabla "rápida sin restricciones" pensando en agregarlas después — los datos malos ya van a estar adentro.

---

## 9. Tipos de datos en SQL
**Carpeta:** `Tipos_Datos/` · **Script:** `tipos-de-datos_script.sql` · **Playbook:** `playbook-tipos-de-datos-en-sql.pdf`

**Concepto clave:** Cada columna tiene un tipo de dato que le dice al motor exactamente qué clase de información puede recibir. Seis tipos cubren el 90 % de los casos: `INTEGER`, `NUMERIC(p,d)`, `TEXT`, `VARCHAR(n)`, `BOOLEAN`, `DATE`, `TIMESTAMP`.

**¿Por qué importa?** Un tipo equivocado puede hacer cálculos incorrectos sin avisarte, ocupar el doble de espacio o hacer que un filtro falle silenciosamente. Elegirlo bien toma segundos; corregirlo con datos cargados toma horas.

**Sintaxis mínima:**
```sql
INTEGER          -- 1, 42, 1500     (sin decimales)
NUMERIC(10,2)    -- 1500.00         (10 dígitos totales, 2 decimales)
TEXT             -- 'cualquier texto sin límite'
VARCHAR(100)     -- texto con tope; CORTA al límite, no avisa
BOOLEAN          -- TRUE / FALSE
DATE             -- 2024-07-31      (sólo día)
TIMESTAMP        -- 2024-03-15 10:30:25  (día + hora)
```

**Puntos finos / errores comunes:**
- `NUMERIC(10,2)`: si pasás más decimales, redondea; si pasás más dígitos totales, error.
- `VARCHAR(10)` con texto de 20 caracteres → te lo guarda truncado a 10 sin advertencia. Conocé tus datos antes de fijar el límite.
- Texto siempre entre comillas simples (`'Bogotá'`), no dobles.
- `CAST(valor AS tipo)` o `'2024-07-31'::DATE` convierten entre tipos. `CURRENT_DATE` y `NOW()` devuelven la fecha/momento del servidor.
- Error clásico: guardar números como texto. Pierden los cálculos, los filtros y las comparaciones de orden.

**Cuándo usarlo (y cuándo NO):** Cada vez que diseñás una columna. La regla: el tipo más restrictivo que cubra el caso real.

---

## 10. Claves foráneas e integridad referencial
**Carpeta:** `Clave_foranea/` · **Script:** `claves-foraneas_script.sql` · **Playbook:** `playbook-claves-foraneas-e-integridad-referencial.pdf`

**Concepto clave:** `REFERENCES` define una clave foránea: una columna cuyo valor debe existir previamente en la PK de otra tabla.

**¿Por qué importa?** Sin FKs, nada le impide al motor aceptar un pedido con un `cliente_id` inexistente, un producto en una categoría que no se creó o un empleado huérfano. El error no se descubre hasta que alguien cruza los datos y nada cierra. Las FKs lo bloquean al momento de insertar.

**Sintaxis mínima:**
```sql
CREATE TABLE pedidos (
    pedido_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha       DATE NOT NULL DEFAULT CURRENT_DATE,
    cliente_id  INTEGER NOT NULL REFERENCES clientes(cliente_id),
    sucursal_id INTEGER NOT NULL REFERENCES sucursales(sucursal_id),
    empleado_id INTEGER NOT NULL REFERENCES empleados(empleado_id)
);
```

**Puntos finos / errores comunes:**
- "Tabla padre" tiene la PK; "tabla hija" tiene la FK. La hija no puede insertar un valor que no exista en el padre.
- Orden obligatorio de creación: primero Paises / Categorias / TiposCliente, luego Sucursales / Clientes / Productos / Empleados, por último Pedidos y DetallePedidos.
- Una tabla puede tener múltiples FKs (Pedidos tiene 3: cliente, sucursal, empleado).
- La tabla intermedia para N:M (DetallePedidos) tiene dos FKs como columnas, además de los atributos propios de la combinación (cantidad, precio).
- A esto se le llama integridad referencial: la garantía la pone el motor, no la disciplina de quien inserta.

**Cuándo usarlo (y cuándo NO):** Siempre que una columna apunte conceptualmente a otra tabla. La única razón válida para no usarla es si estás haciendo una tabla descartable de pruebas.

---

## 11. ALTER TABLE: modificar tablas sin perder datos
**Carpeta:** `Alter_table/` · **Script:** `alter-table_script.sql` · **Playbook:** `playbook-alter-table_-como-modificar-tablas-sin-perder-datos.pdf`

**Concepto clave:** `ALTER TABLE` modifica una tabla existente (agregar/cambiar/renombrar columnas, agregar/quitar restricciones, eliminar columnas, renombrar la tabla) sin tocar los datos cargados.

**¿Por qué importa?** Las bases cambian: aparece un requisito nuevo, alguien olvidó una columna, una restricción se aplicó mal. Eliminar y recrear la tabla no es opción cuando ya tiene datos. ALTER te permite evolucionar sin perder lo cargado.

**Sintaxis mínima:**
```sql
ALTER TABLE empleados_demo ADD COLUMN email TEXT;
ALTER TABLE empleados_demo ALTER COLUMN email TYPE VARCHAR(100);
ALTER TABLE empleados_demo RENAME COLUMN cargo TO puesto;
ALTER TABLE empleados_demo ADD CONSTRAINT email_unico UNIQUE (email);
ALTER TABLE empleados_demo DROP CONSTRAINT email_unico;
ALTER TABLE empleados_demo DROP COLUMN activo;
ALTER TABLE empleados_demo RENAME TO empleados_v2;
```

**Puntos finos / errores comunes:**
- Al agregar columna con `NOT NULL`, es obligatorio darle un `DEFAULT` — las filas existentes necesitan un valor para ese campo nuevo.
- Cambiar el tipo puede fallar si los datos no son compatibles (no se puede pasar TEXT con letras a INTEGER).
- Para poder eliminar una restricción después, hay que crearla con nombre explícito (`ADD CONSTRAINT email_unico UNIQUE (email)`).
- `DROP COLUMN` y `DROP CONSTRAINT` son irreversibles — no hay deshacer en SQL.
- Si renombrás una columna o tabla, todas las consultas, vistas o reportes que la usen con el nombre viejo van a romperse.

**Cuándo usarlo (y cuándo NO):** Para evolucionar el esquema. Agregar es seguro; eliminar requiere certeza absoluta (¿hay respaldo? ¿hay consultas que dependen de eso?).

---

## 12. INSERT: cargar datos en tablas
**Carpeta:** `Insert/` · **Script:** `insert_script.sql` · **Playbook:** `playbook-insert_-como-cargar-datos-en-tus-tablas.pdf`

**Concepto clave:** `INSERT INTO ... VALUES` carga filas; podés hacerlo una por una, varias en una sola instrucción, y usar `RETURNING` para ver el resultado sin un SELECT aparte.

**¿Por qué importa?** Insertar cien filas con cien instrucciones separadas tarda minutos; con la forma múltiple, segundos. Y nombrar las columnas explícitamente te protege cuando alguien más adelante reordena la tabla.

**Sintaxis mínima:**
```sql
-- Básico
INSERT INTO paises (nombre, codigo) VALUES ('Chile', 'CHL');

-- Múltiple (recomendado para varios registros)
INSERT INTO paises (nombre, codigo) VALUES
    ('Colombia', 'COL'),
    ('México',   'MEX'),
    ('Perú',     'PER');

-- Con RETURNING para confirmar el ID generado
INSERT INTO categorias (nombre) VALUES ('Electrónica')
RETURNING categoria_id, nombre;
```

**Puntos finos / errores comunes:**
- Nombrar las columnas explícitamente: si no lo hacés, el orden de los valores tiene que coincidir EXACTAMENTE con el orden de definición, y si alguien agrega una columna después, tu INSERT se rompe.
- `RETURNING *` te devuelve la fila completa tal como quedó guardada — útil para ver los `DEFAULT` aplicados.
- Si la tabla tiene FKs, los valores referenciados deben existir antes en la tabla padre, o el motor lo rechaza.
- El orden de carga de TiendaLatam refleja el orden de creación: padres antes que hijas.

**Cuándo usarlo (y cuándo NO):** Para cargar datos manualmente o desde scripts. Para cargas masivas desde CSV, mejor el asistente de pgAdmin o `COPY`.

---

## 13. UPDATE: modificar registros (la regla del WHERE)
**Carpeta:** `Update/` · **Script:** `update_script.sql` · **Playbook:** `playbook-update.pdf`

**Concepto clave:** `UPDATE ... SET ... WHERE` modifica registros existentes. La regla de oro: **un `UPDATE` sin `WHERE` modifica todas las filas de la tabla, y no hay Ctrl+Z en SQL**.

**¿Por qué importa?** Las dos instrucciones son sintácticamente válidas: el motor ejecuta las dos sin error. La diferencia es que una afecta una fila y la otra afecta toda la tabla. En miles de clientes, ese olvido es catastrófico.

**Sintaxis mínima:**
```sql
-- Una columna
UPDATE clientes SET activo = FALSE WHERE cliente_id = 1;

-- Varias columnas
UPDATE clientes
SET nombre = 'María González Reyes',
    activo = TRUE
WHERE cliente_id = 1;

-- Calculando desde el valor actual (con confirmación)
UPDATE productos
SET precio = precio * 1.10
WHERE categoria_id = 1
RETURNING producto_id, nombre, precio;
```

**Puntos finos / errores comunes:**
- El hábito que evita desastres: antes de un UPDATE, ejecutá un `SELECT` con el mismo `WHERE` para ver exactamente qué filas vas a tocar.
- El `WHERE` del UPDATE acepta todo lo del SELECT: `=`, `>`, `BETWEEN`, `IN`, `AND`, `OR`.
- `RETURNING` es especialmente útil cuando el valor nuevo se calcula desde el viejo (`precio * 1.10`) — te confirma el resultado sin segunda consulta.
- Los valores se separan con coma dentro del `SET`, no con `AND` (eso es del WHERE).

**Cuándo usarlo (y cuándo NO):** Para modificar datos existentes. Cuando el "cambio" es realmente una baja, considerá borrado lógico (siguiente tema) antes que UPDATE drástico.

---

## 14. DELETE: borrar filas o desactivarlas (borrado lógico)
**Carpeta:** `Delete/` · **Script:** `delete_script.sql` · **Playbook:** `playbook-delete.pdf`

**Concepto clave:** `DELETE FROM ... WHERE` elimina filas de forma permanente. En datos de negocio, casi nunca se usa: se prefiere el borrado lógico (marcar `activo = FALSE`).

**¿Por qué importa?** Si borrás un cliente, sus pedidos quedan apuntando a un ID que ya no existe, los reportes históricos rompen y la integridad referencial colapsa. El borrado lógico mantiene la fila, el historial y todas las relaciones; lo único que cambia es que ya no aparece en las consultas normales.

**Sintaxis mínima:**
```sql
-- DELETE físico (sólo para datos temporales/error de carga)
DELETE FROM clientes WHERE cliente_id = 99
RETURNING *;

-- Borrado lógico (lo correcto para datos de negocio)
UPDATE clientes SET activo = FALSE WHERE cliente_id = 5;

-- Para "ver sólo activos" después:
SELECT * FROM clientes WHERE activo = TRUE;
```

**Puntos finos / errores comunes:**
- La regla de oro del WHERE aplica con consecuencias todavía peores: `DELETE FROM clientes;` borra TODOS los clientes sin advertencia.
- DELETE físico tiene sentido para datos de prueba, errores de carga o duplicados. Para clientes, empleados, productos o pedidos reales: borrado lógico.
- Reactivar es trivial: `UPDATE ... SET activo = TRUE WHERE ...` — no perdiste nada.
- Pregunta guía para decidir: ¿este dato tiene historial o relaciones con otras tablas? Si sí → borrado lógico.

**Cuándo usarlo (y cuándo NO):** DELETE físico sólo para limpiar datos sin historial. Para todo lo demás, borrado lógico vía UPDATE del campo `activo`.

---

## 15. SELECT básico: proyección, WHERE y operadores
**Carpeta:** `Select/` · **Script:** `select_script.sql` · **Playbook:** `playbook-select-basico.pdf`

**Concepto clave:** `SELECT ... FROM ... WHERE` extrae datos. La proyección (qué columnas) y el filtro (qué filas) son las dos decisiones de toda consulta.

**¿Por qué importa?** Es el comando más ejecutado en SQL. Una consulta que trae todas las columnas con `*` cuando sólo necesitás tres es más lenta, más difícil de leer y más propensa a malinterpretarse. Filtrar con `WHERE` correctamente es lo que convierte "todos los datos" en "la respuesta a la pregunta".

**Sintaxis mínima:**
```sql
SELECT nombre, correo, activo
FROM clientes
WHERE activo = TRUE
LIMIT 10;

-- Operadores que más usás:
WHERE precio > 100                              -- >, <, >=, <=, =
WHERE precio BETWEEN 50 AND 200                 -- rango (incluye extremos)
WHERE codigo IN ('CHL', 'ARG', 'COL')           -- lista
WHERE nombre LIKE 'Mar%'                        -- texto que empieza
WHERE correo LIKE '%@gmail.com'                 -- texto que termina
WHERE telefono IS NULL                          -- nulos (NO usar = NULL)
WHERE precio > 50 AND stock > 0                 -- combinar con AND/OR/NOT
```

**Puntos finos / errores comunes:**
- `NULL` no es vacío ni cero: es ausencia. No se compara con `=`; usás `IS NULL` / `IS NOT NULL`.
- `LIKE` usa `%` para "cualquier secuencia"; puede ir al inicio, al final o ambos lados.
- `AS` renombra columnas sólo en el resultado: `SELECT nombre AS cliente FROM ...` no toca la tabla.
- `LIMIT` mientras explorás te evita traer miles de filas accidentalmente.
- `BETWEEN x AND y` incluye los dos extremos.

**Cuándo usarlo (y cuándo NO):** Para cualquier consulta de lectura. `SELECT *` está bien para explorar; en código real, listá las columnas que necesitás.

---

## 16. ORDER BY y LIMIT: ordenar y paginar
**Carpeta:** `Order_Limit/` · **Script:** `order-by_script.sql` · **Playbook:** `playbook-order-by.pdf`

**Concepto clave:** `ORDER BY` define el orden de los resultados; `LIMIT` corta cuántas filas devuelve; `OFFSET` salta filas para paginar.

**¿Por qué importa?** Sin orden explícito, el motor devuelve filas en orden arbitrario. "Los 10 productos más caros" exige `ORDER BY precio DESC LIMIT 10` — sin el ORDER BY, el LIMIT te trae 10 productos al azar y el reporte miente.

**Sintaxis mínima:**
```sql
-- Top 5 productos más caros
SELECT nombre, precio
FROM productos
ORDER BY precio DESC
LIMIT 5;

-- Orden jerárquico (primero categoría, dentro de cada una por precio)
SELECT nombre, categoria_id, precio
FROM productos
ORDER BY categoria_id ASC, precio DESC;

-- Paginación: página 2 de 10 en 10
SELECT nombre FROM productos
ORDER BY nombre ASC
LIMIT 10 OFFSET 10;
```

**Puntos finos / errores comunes:**
- `ASC` (ascendente) es el default si no escribís nada; `DESC` (descendente) hay que ponerlo explícito.
- En PostgreSQL, con `ASC` los NULLs van al final; con `DESC` van al inicio. Podés forzarlo con `NULLS FIRST` o `NULLS LAST`.
- El orden de las cláusulas en el código: `SELECT ... FROM ... WHERE ... ORDER BY ... LIMIT ... OFFSET`.
- `LIMIT` sin `ORDER BY` da resultados imprevisibles — siempre van juntos para preguntas de negocio.

**Cuándo usarlo (y cuándo NO):** Siempre que el orden importe o necesites un "top N". OFFSET es para paginar exportes o pantallas, no para "buscar la fila N".

---

## 17. GROUP BY y funciones de agregación
**Carpeta:** `Group_by_Func_agregacion/` · **Script:** `group-by_script.sql` · **Playbook:** `playbook-group-by-y-funciones-de-agregacion-en-sql.pdf`

**Concepto clave:** `GROUP BY` agrupa filas con el mismo valor en una columna y aplica una función de agregación (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) sobre cada grupo. El resultado es una fila por grupo, no por registro.

**¿Por qué importa?** Las preguntas de negocio reales son agregadas: "¿cuánto vendemos por país?", "¿cuál es el ticket promedio por sucursal?", "¿cuántos productos hay por categoría?". Sin GROUP BY, tendrías millones de filas individuales en lugar de la respuesta.

**Sintaxis mínima:**
```sql
SELECT
    categoria_id,
    COUNT(*)     AS total_productos,
    AVG(precio)  AS precio_promedio,
    MIN(precio)  AS precio_minimo,
    MAX(precio)  AS precio_maximo
FROM productos
GROUP BY categoria_id
ORDER BY total_productos DESC;
```

**Puntos finos / errores comunes:**
- **La regla:** toda columna del SELECT que no sea una función de agregación debe estar en el GROUP BY. Si no, el motor rechaza la consulta — y tiene razón: no sabe qué valor "individual" mostrar para un grupo de 50 filas.
- `COUNT(*)` cuenta todas las filas; `COUNT(columna)` ignora los NULL — los dos números pueden diferir.
- `SUM`, `AVG`, `MIN`, `MAX` operan sobre columnas numéricas (MIN/MAX también sobre fechas y texto).
- Para agrupar por año/mes, lo que va en el GROUP BY no es la columna fecha cruda sino su transformación: `GROUP BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)`.
- Verificá el nombre exacto de la columna en pgAdmin antes de escribir — si la tabla tiene `fecha_pedido` y escribís `fecha`, falla.

**Cuándo usarlo (y cuándo NO):** Para todo reporte de resumen. Si la pregunta tiene "por", "promedio", "total", "cantidad de" — es GROUP BY.

---

## 18. HAVING: filtrar después de agrupar
**Carpeta:** `Having/` · **Script:** `having_script.sql` · **Playbook:** `playbook-having-docx.pdf`

**Concepto clave:** `HAVING` filtra grupos formados por `GROUP BY`, igual que `WHERE` filtra filas individuales antes de agrupar.

**¿Por qué importa?** "Categorías con más de 5 productos" o "clientes con más de 3 pedidos en 2024" no se pueden expresar con WHERE: la condición es sobre el resultado de una agregación que todavía no existe cuando WHERE actúa. Para eso existe HAVING.

**Sintaxis mínima:**
```sql
-- Orden lógico de ejecución:
-- Tabla → WHERE filtra filas → GROUP BY agrupa → HAVING filtra grupos → Resultado

SELECT
    cliente_id,
    COUNT(*) AS pedidos_2024
FROM pedidos
WHERE EXTRACT(YEAR FROM fecha_pedido) = 2024  -- filtra filas
GROUP BY cliente_id
HAVING COUNT(*) > 3                            -- filtra grupos
ORDER BY pedidos_2024 DESC;
```

**Puntos finos / errores comunes:**
- Regla simple de decisión: condición sobre fila individual → `WHERE`; condición sobre resultado de agregación → `HAVING`.
- Si ponés una función de agregación en el `WHERE`, error: las funciones no existen todavía en ese momento.
- WHERE es más eficiente porque reduce el volumen antes de agrupar — no uses HAVING para condiciones que pertenecen al WHERE.
- Orden obligatorio en el código: `SELECT ... FROM ... WHERE ... GROUP BY ... HAVING ... ORDER BY ... LIMIT`.
- Diferencia entre `> 5` y `>= 5` cambia cuántos grupos aparecen.

**Cuándo usarlo (y cuándo NO):** Sólo cuando la condición depende de una agregación (`COUNT(*) > N`, `SUM(total) > X`). Si la condición se puede expresar sobre filas individuales, WHERE es la opción correcta.

---

## 19. Funciones de texto, fecha y número
**Carpeta:** `Func_texto/` · **Script:** `funciones-de-texto_script.sql` · **Playbook:** `playbook-funciones-de-texto.pdf`

**Concepto clave:** Las funciones de transformación cambian cómo se ven los datos en el resultado sin modificar lo guardado: texto (`UPPER`, `LOWER`, `TRIM`, `LENGTH`, `||`, `SUBSTRING`, `LEFT`, `RIGHT`, `REPLACE`), fecha (`NOW`, `EXTRACT`, `INTERVAL`, `TO_CHAR`) y número (`ROUND`, `CEIL`, `FLOOR`, `ABS`, `TO_CHAR`), más `COALESCE` para nulos.

**¿Por qué importa?** Los datos guardados están en formato técnico (`2024-01-15`, mayúsculas mezcladas, NULL en teléfono). Los reportes los necesitan en formato humano: "15 de enero de 2024", todo en mayúsculas, "Sin teléfono" en vez de vacío. Estas funciones hacen la traducción.

**Sintaxis mínima:**
```sql
SELECT
    UPPER(nombre)                              AS nombre,
    LOWER(correo)                              AS correo,
    nombre || ' ' || apellido                  AS nombre_completo,
    TO_CHAR(fecha_registro, 'DD/MM/YYYY')      AS fecha_legible,
    EXTRACT(YEAR FROM fecha_registro)          AS anio,
    CURRENT_DATE - fecha_registro              AS dias_como_cliente,
    ROUND(precio, 2)                           AS precio_redondeado,
    TO_CHAR(precio, 'FM$999,999,990.00')       AS precio_moneda,
    COALESCE(telefono, correo, 'Sin contacto') AS contacto
FROM clientes;
```

**Puntos finos / errores comunes:**
- Concatenación en PostgreSQL es `||`, no `+` ni `&`.
- `VARCHAR` y los limitadores: `LEFT('postgres', 4)` da `'post'`; `SUBSTRING('postgres', 1, 7)` da `'postgre'`.
- Aritmética de fechas con `INTERVAL`: `CURRENT_DATE + INTERVAL '30 days'`. Restar dos fechas devuelve la diferencia en días.
- `TO_CHAR` con fechas: patrones `DD`, `MM`, `Month`, `YYYY`. Con números: `'FM$999,999,990.00'` controla símbolo, separadores y decimales.
- `COALESCE(a, b, c)` evalúa en orden y devuelve el primer no nulo — encadenable a cuantos quieras.

**Cuándo usarlo (y cuándo NO):** Para todo reporte de presentación. No las uses para "cambiar los datos" — no los cambian, sólo cambian el resultado de esa consulta.

---

## 20. INNER JOIN y LEFT JOIN
**Carpeta:** `Inner_Left_Join/` · **Script:** `inner-join-y-left-join_script.sql` · **Playbook:** `playbook-inner-join-y-left-join-para-conectar-tablas.pdf`

**Concepto clave:** `JOIN` combina filas de dos tablas usando una FK como puente (`ON`). `INNER JOIN` devuelve sólo coincidencias; `LEFT JOIN` devuelve todas las filas de la izquierda aunque no haya coincidencia.

**¿Por qué importa?** "¿Qué vendió TiendaLatam en Argentina por categoría?" cruza 6 tablas. Sin JOIN, harías varias consultas separadas y cruzarías a mano como en Excel. Con JOIN, es una sola consulta. Y `LEFT JOIN` responde lo que INNER JOIN no puede: "¿qué clientes nunca compraron?".

**Sintaxis mínima:**
```sql
-- INNER JOIN: clientes con sus pedidos (sólo los que sí compraron)
SELECT
    p.cliente_id,
    c.nombre AS nombre_cliente,
    COUNT(*) AS cantidad_pedidos
FROM pedidos AS p
INNER JOIN clientes AS c ON p.cliente_id = c.cliente_id
GROUP BY p.cliente_id, c.nombre
HAVING COUNT(*) >= 3
ORDER BY cantidad_pedidos DESC;

-- LEFT JOIN: clientes que NUNCA hicieron pedido (campaña de reactivación)
SELECT c.nombre, c.correo
FROM clientes AS c
LEFT JOIN pedidos AS p ON c.cliente_id = p.cliente_id
WHERE p.pedido_id IS NULL;
```

**Puntos finos / errores comunes:**
- Alias obligatorios (`AS p`, `AS c`): si las dos tablas tienen una columna con el mismo nombre y no lo prefijás, el motor falla por ambigüedad.
- Olvidar el `ON` produce un **producto cartesiano**: cada fila de A con cada fila de B → millones de filas que congelan la consulta.
- En `LEFT JOIN`, la tabla "izquierda" es la del `FROM`; sus filas se conservan todas. Para encontrar "los que no tienen contraparte", filtrá `WHERE columna_de_la_derecha IS NULL`.
- En GROUP BY con JOIN, todas las columnas no-agregadas del SELECT deben estar en GROUP BY, vengan de la tabla que vengan.
- En el GROUP BY usá el alias (`p.cliente_id`), no el nombre completo de la tabla.

**Cuándo usarlo (y cuándo NO):** INNER JOIN para "lo que está en ambas tablas". LEFT JOIN para "todo lo de la izquierda, con o sin coincidencia" — especialmente para detectar huecos (clientes sin pedidos, productos sin ventas, etc.).

---

> **Siguiente paso:** cuando termines este manual, pasá al de [SQL Avanzado](../sql_avanzado/MANUAL.md) — JOINs avanzados, subqueries, CTEs, vistas, columnas calculadas, SPs y triggers.
