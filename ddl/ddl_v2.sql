-- =============================================================================================
-- DDL AVANZADO - TiendaLatam (versión producción)
-- =============================================================================================
-- Descripción : Esquema relacional con prácticas de producción para SQL Server 2019+.
--               Incluye separación por dominio (schemas), idempotencia total, tablas temporales
--               system-versioned, vista indexada para totales, SP atómico con Table-Valued
--               Parameter, columnas calculadas persistidas, MERGE para catálogos, índices
--               filtrados y configuración de base de datos.
-- Motor       : SQL Server 2019 o superior (necesario para SCHEMA-bound temporal tables)
-- Versión     : 2.0
-- Autor       : Equipo Datos
-- =============================================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- =============================================================================================
-- 0. CREACIÓN Y CONFIGURACIÓN DE LA BASE DE DATOS
-- =============================================================================================
USE master;
GO

IF DB_ID(N'TiendaLatam') IS NULL
BEGIN
    CREATE DATABASE TiendaLatam;
    PRINT N'>> Base de datos TiendaLatam creada.';
END
ELSE
    PRINT N'>> Base de datos TiendaLatam ya existe — continuando.';
GO

-- Configuración a nivel de base de datos
-- RCSI/SI : reduce bloqueos de lectores vs escritores (snapshot isolation)
-- QUERY_STORE : telemetría persistente de planes y rendimiento (gratis e indispensable en prod)
ALTER DATABASE TiendaLatam SET RECOVERY FULL;
ALTER DATABASE TiendaLatam SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
ALTER DATABASE TiendaLatam SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE TiendaLatam SET PAGE_VERIFY CHECKSUM;
ALTER DATABASE TiendaLatam SET QUERY_STORE = ON;
ALTER DATABASE TiendaLatam SET QUERY_STORE (
    OPERATION_MODE              = READ_WRITE,
    CLEANUP_POLICY              = (STALE_QUERY_THRESHOLD_DAYS = 30),
    DATA_FLUSH_INTERVAL_SECONDS = 900,
    MAX_STORAGE_SIZE_MB         = 1024,
    QUERY_CAPTURE_MODE          = AUTO
);
GO

USE TiendaLatam;
GO
SELECT DB_NAME() AS BaseDeDatosActual;
GO

-- =============================================================================================
-- 1. SCHEMAS — separación por dominio (facilita permisos y comprensión)
-- =============================================================================================
IF SCHEMA_ID(N'geo')        IS NULL EXEC(N'CREATE SCHEMA geo        AUTHORIZATION dbo');
IF SCHEMA_ID(N'catalogo')   IS NULL EXEC(N'CREATE SCHEMA catalogo   AUTHORIZATION dbo');
IF SCHEMA_ID(N'rrhh')       IS NULL EXEC(N'CREATE SCHEMA rrhh       AUTHORIZATION dbo');
IF SCHEMA_ID(N'ventas')     IS NULL EXEC(N'CREATE SCHEMA ventas     AUTHORIZATION dbo');
IF SCHEMA_ID(N'inventario') IS NULL EXEC(N'CREATE SCHEMA inventario AUTHORIZATION dbo');
IF SCHEMA_ID(N'auditoria')  IS NULL EXEC(N'CREATE SCHEMA auditoria  AUTHORIZATION dbo');
IF SCHEMA_ID(N'historia')   IS NULL EXEC(N'CREATE SCHEMA historia   AUTHORIZATION dbo');
GO

-- =============================================================================================
-- 2. TABLAS DE CATÁLOGO (lookup)
-- =============================================================================================

-- ----------------- geo.Paises -----------------
IF OBJECT_ID(N'geo.Paises', N'U') IS NULL
BEGIN
    CREATE TABLE geo.Paises (
        PaisID        INT            NOT NULL IDENTITY(1,1),
        CodigoISO2    CHAR(2)        NOT NULL,                  -- ISO 3166-1 alpha-2
        CodigoISO3    CHAR(3)        NULL,                      -- ISO 3166-1 alpha-3
        NombrePais    NVARCHAR(100)  NOT NULL,
        Continente    NVARCHAR(50)   NULL,
        FechaCreacion DATETIME2(3)   NOT NULL
            CONSTRAINT DF_Paises_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        UsuarioCreacion SYSNAME      NOT NULL
            CONSTRAINT DF_Paises_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        RowVersion    ROWVERSION     NOT NULL,

        CONSTRAINT PK_Paises          PRIMARY KEY CLUSTERED (PaisID),
        CONSTRAINT UQ_Paises_ISO2     UNIQUE (CodigoISO2),
        CONSTRAINT CK_Paises_ISO2_Fmt CHECK (CodigoISO2 LIKE '[A-Z][A-Z]'),
        CONSTRAINT CK_Paises_ISO3_Fmt CHECK (CodigoISO3 IS NULL OR CodigoISO3 LIKE '[A-Z][A-Z][A-Z]')
    ) WITH (DATA_COMPRESSION = PAGE);
END
GO

-- ----------------- catalogo.Monedas -----------------
IF OBJECT_ID(N'catalogo.Monedas', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.Monedas (
        MonedaID      TINYINT        NOT NULL IDENTITY(1,1),
        CodigoISO     CHAR(3)        NOT NULL,                  -- ISO 4217 (USD, GTQ, MXN...)
        NombreMoneda  NVARCHAR(50)   NOT NULL,
        Simbolo       NVARCHAR(5)    NULL,
        Decimales     TINYINT        NOT NULL
            CONSTRAINT DF_Monedas_Decimales DEFAULT (2),
        Activa        BIT            NOT NULL
            CONSTRAINT DF_Monedas_Activa DEFAULT (1),

        CONSTRAINT PK_Monedas        PRIMARY KEY CLUSTERED (MonedaID),
        CONSTRAINT UQ_Monedas_ISO    UNIQUE (CodigoISO),
        CONSTRAINT CK_Monedas_ISOFmt CHECK (CodigoISO LIKE '[A-Z][A-Z][A-Z]')
    );
END
GO

-- ----------------- catalogo.Categorias -----------------
IF OBJECT_ID(N'catalogo.Categorias', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.Categorias (
        CategoriaID      INT            NOT NULL IDENTITY(1,1),
        NombreCategoria  NVARCHAR(100)  NOT NULL,
        Descripcion      NVARCHAR(500)  NULL,
        Activa           BIT            NOT NULL
            CONSTRAINT DF_Categorias_Activa DEFAULT (1),
        FechaCreacion    DATETIME2(3)   NOT NULL
            CONSTRAINT DF_Categorias_FechaCreacion DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_Categorias       PRIMARY KEY CLUSTERED (CategoriaID),
        CONSTRAINT UQ_Categorias_Nom   UNIQUE (NombreCategoria)
    );
END
GO

-- ----------------- catalogo.TiposCliente -----------------
IF OBJECT_ID(N'catalogo.TiposCliente', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.TiposCliente (
        TipoClienteID  TINYINT        NOT NULL IDENTITY(1,1),
        Codigo         NVARCHAR(20)   NOT NULL,
        NombreTipo     NVARCHAR(50)   NOT NULL,
        Descripcion    NVARCHAR(500)  NULL,

        CONSTRAINT PK_TiposCliente    PRIMARY KEY CLUSTERED (TipoClienteID),
        CONSTRAINT UQ_TiposCliente_Cd UNIQUE (Codigo)
    );
END
GO

-- ----------------- catalogo.EstadosPedido -----------------
-- Reemplaza el CHECK con lista hardcoded del DDL original — ahora extensible sin ALTER TABLE.
IF OBJECT_ID(N'catalogo.EstadosPedido', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.EstadosPedido (
        EstadoID     TINYINT       NOT NULL,
        Codigo       NVARCHAR(20)  NOT NULL,
        Descripcion  NVARCHAR(100) NULL,
        EsTerminal   BIT           NOT NULL
            CONSTRAINT DF_EstadosPedido_Terminal DEFAULT (0),

        CONSTRAINT PK_EstadosPedido    PRIMARY KEY CLUSTERED (EstadoID),
        CONSTRAINT UQ_EstadosPedido_Cd UNIQUE (Codigo)
    );
END
GO

-- =============================================================================================
-- 3. TABLAS PRINCIPALES
-- =============================================================================================

-- ----------------- geo.Sucursales -----------------
IF OBJECT_ID(N'geo.Sucursales', N'U') IS NULL
BEGIN
    CREATE TABLE geo.Sucursales (
        SucursalID        INT            NOT NULL IDENTITY(1,1),
        CodigoSucursal    NVARCHAR(20)   NOT NULL,
        NombreSucursal    NVARCHAR(150)  NOT NULL,
        Ciudad            NVARCHAR(100)  NULL,
        PaisID            INT            NOT NULL,
        DireccionCompleta NVARCHAR(300)  NULL,
        Activo            BIT            NOT NULL
            CONSTRAINT DF_Sucursales_Activo DEFAULT (1),
        FechaCreacion     DATETIME2(3)   NOT NULL
            CONSTRAINT DF_Sucursales_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModif        DATETIME2(3)   NULL,
        RowVersion        ROWVERSION     NOT NULL,

        CONSTRAINT PK_Sucursales         PRIMARY KEY CLUSTERED (SucursalID),
        CONSTRAINT UQ_Sucursales_Codigo  UNIQUE (CodigoSucursal),
        CONSTRAINT FK_Sucursales_Paises  FOREIGN KEY (PaisID)
            REFERENCES geo.Paises (PaisID)
            ON UPDATE NO ACTION ON DELETE NO ACTION
    ) WITH (DATA_COMPRESSION = PAGE);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Sucursales_PaisID' AND object_id = OBJECT_ID(N'geo.Sucursales'))
    CREATE NONCLUSTERED INDEX IX_Sucursales_PaisID ON geo.Sucursales (PaisID) WHERE Activo = 1;
GO

-- ----------------- catalogo.Productos (TEMPORAL — system-versioned) -----------------
-- Tablas temporales mantienen automáticamente un historial completo de cambios. Útil para
-- auditoría regulatoria, análisis as-of, y "deshacer" cambios.
IF OBJECT_ID(N'catalogo.Productos', N'U') IS NULL
BEGIN
    CREATE TABLE catalogo.Productos (
        ProductoID      INT              NOT NULL IDENTITY(1,1),
        CodigoProducto  NVARCHAR(20)     NOT NULL,
        NombreProducto  NVARCHAR(200)    NOT NULL,
        CategoriaID     INT              NOT NULL,
        MonedaID        TINYINT          NOT NULL,
        Precio          DECIMAL(12, 4)   NOT NULL,
        Descripcion     NVARCHAR(500)    NULL,
        Activo          BIT              NOT NULL
            CONSTRAINT DF_Productos_Activo DEFAULT (1),
        FechaCreacion   DATETIME2(3)     NOT NULL
            CONSTRAINT DF_Productos_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        UsuarioCreacion SYSNAME          NOT NULL
            CONSTRAINT DF_Productos_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        FechaModif      DATETIME2(3)     NULL,
        UsuarioModif    SYSNAME          NULL,
        -- Columnas system-time requeridas por SYSTEM_VERSIONING
        ValidoDesde     DATETIME2(3)     GENERATED ALWAYS AS ROW START   HIDDEN NOT NULL,
        ValidoHasta     DATETIME2(3)     GENERATED ALWAYS AS ROW END     HIDDEN NOT NULL,
        PERIOD FOR SYSTEM_TIME (ValidoDesde, ValidoHasta),

        CONSTRAINT PK_Productos             PRIMARY KEY CLUSTERED (ProductoID),
        CONSTRAINT UQ_Productos_Codigo      UNIQUE (CodigoProducto),
        CONSTRAINT FK_Productos_Categorias  FOREIGN KEY (CategoriaID)
            REFERENCES catalogo.Categorias (CategoriaID),
        CONSTRAINT FK_Productos_Monedas     FOREIGN KEY (MonedaID)
            REFERENCES catalogo.Monedas (MonedaID),
        CONSTRAINT CK_Productos_Precio      CHECK (Precio >= 0)
    ) WITH (
        SYSTEM_VERSIONING  = ON (HISTORY_TABLE = historia.ProductosHist, DATA_CONSISTENCY_CHECK = ON),
        DATA_COMPRESSION   = PAGE
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Productos_CategoriaID' AND object_id = OBJECT_ID(N'catalogo.Productos'))
    CREATE NONCLUSTERED INDEX IX_Productos_CategoriaID
        ON catalogo.Productos (CategoriaID)
        INCLUDE (NombreProducto, Precio)
        WHERE Activo = 1;
GO

-- ----------------- rrhh.Empleados -----------------
IF OBJECT_ID(N'rrhh.Empleados', N'U') IS NULL
BEGIN
    CREATE TABLE rrhh.Empleados (
        EmpleadoID    INT            NOT NULL IDENTITY(1,1),
        CodigoEmpleado NVARCHAR(20)  NOT NULL,
        Nombre        NVARCHAR(100)  NOT NULL,
        Apellido      NVARCHAR(100)  NOT NULL,
        NombreCompleto AS (CONCAT(Nombre, N' ', Apellido)) PERSISTED,  -- columna calculada
        Email         NVARCHAR(254)  NULL,
        SucursalID    INT            NOT NULL,
        FechaIngreso  DATE           NULL,
        FechaBaja     DATE           NULL,
        Cargo         NVARCHAR(100)  NULL,
        Activo        BIT            NOT NULL
            CONSTRAINT DF_Empleados_Activo DEFAULT (1),
        FechaCreacion DATETIME2(3)   NOT NULL
            CONSTRAINT DF_Empleados_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        RowVersion    ROWVERSION     NOT NULL,

        CONSTRAINT PK_Empleados             PRIMARY KEY CLUSTERED (EmpleadoID),
        CONSTRAINT UQ_Empleados_Codigo      UNIQUE (CodigoEmpleado),
        CONSTRAINT FK_Empleados_Sucursales  FOREIGN KEY (SucursalID)
            REFERENCES geo.Sucursales (SucursalID),
        CONSTRAINT CK_Empleados_Email       CHECK (Email IS NULL OR Email LIKE N'%_@_%._%'),
        CONSTRAINT CK_Empleados_Fechas      CHECK (FechaBaja IS NULL OR FechaBaja >= FechaIngreso)
    ) WITH (DATA_COMPRESSION = PAGE);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Empleados_SucursalID' AND object_id = OBJECT_ID(N'rrhh.Empleados'))
    CREATE NONCLUSTERED INDEX IX_Empleados_SucursalID ON rrhh.Empleados (SucursalID) WHERE Activo = 1;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Empleados_Email_Filt' AND object_id = OBJECT_ID(N'rrhh.Empleados'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Empleados_Email_Filt
        ON rrhh.Empleados (Email)
        WHERE Email IS NOT NULL;
GO

-- ----------------- ventas.Clientes -----------------
IF OBJECT_ID(N'ventas.Clientes', N'U') IS NULL
BEGIN
    CREATE TABLE ventas.Clientes (
        ClienteID       INT            NOT NULL IDENTITY(1,1),
        Nombre          NVARCHAR(100)  NOT NULL,
        Apellido        NVARCHAR(100)  NOT NULL,
        Email           NVARCHAR(254)  NULL,
        Telefono        NVARCHAR(30)   NULL,
        PaisID          INT            NOT NULL,
        Ciudad          NVARCHAR(100)  NULL,
        TipoClienteID   TINYINT        NOT NULL
            CONSTRAINT DF_Clientes_TipoClienteID DEFAULT (1),
        FechaRegistro   DATE           NOT NULL
            CONSTRAINT DF_Clientes_FechaRegistro DEFAULT (CAST(SYSUTCDATETIME() AS DATE)),
        Activo          BIT            NOT NULL
            CONSTRAINT DF_Clientes_Activo DEFAULT (1),
        FechaCreacion   DATETIME2(3)   NOT NULL
            CONSTRAINT DF_Clientes_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        UsuarioCreacion SYSNAME        NOT NULL
            CONSTRAINT DF_Clientes_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        FechaModif      DATETIME2(3)   NULL,
        UsuarioModif    SYSNAME        NULL,
        RowVersion      ROWVERSION     NOT NULL,

        CONSTRAINT PK_Clientes               PRIMARY KEY CLUSTERED (ClienteID),
        CONSTRAINT FK_Clientes_Paises        FOREIGN KEY (PaisID)
            REFERENCES geo.Paises (PaisID),
        CONSTRAINT FK_Clientes_TiposCliente  FOREIGN KEY (TipoClienteID)
            REFERENCES catalogo.TiposCliente (TipoClienteID),
        CONSTRAINT CK_Clientes_Email         CHECK (Email IS NULL OR Email LIKE N'%_@_%._%')
    ) WITH (DATA_COMPRESSION = PAGE);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Clientes_PaisID' AND object_id = OBJECT_ID(N'ventas.Clientes'))
    CREATE NONCLUSTERED INDEX IX_Clientes_PaisID         ON ventas.Clientes (PaisID)        WHERE Activo = 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Clientes_TipoClienteID' AND object_id = OBJECT_ID(N'ventas.Clientes'))
    CREATE NONCLUSTERED INDEX IX_Clientes_TipoClienteID  ON ventas.Clientes (TipoClienteID) WHERE Activo = 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Clientes_FechaRegistro' AND object_id = OBJECT_ID(N'ventas.Clientes'))
    CREATE NONCLUSTERED INDEX IX_Clientes_FechaRegistro  ON ventas.Clientes (FechaRegistro DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Clientes_Email_Filt' AND object_id = OBJECT_ID(N'ventas.Clientes'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_Clientes_Email_Filt
        ON ventas.Clientes (Email)
        WHERE Email IS NOT NULL;
GO

-- ----------------- ventas.Pedidos (TEMPORAL — system-versioned) -----------------
IF OBJECT_ID(N'ventas.Pedidos', N'U') IS NULL
BEGIN
    CREATE TABLE ventas.Pedidos (
        PedidoID         INT              NOT NULL IDENTITY(1,1),
        NumeroPedido     AS (CONCAT(N'P-', RIGHT(N'00000000' + CAST(PedidoID AS NVARCHAR(8)), 8))) PERSISTED,
        ClienteID        INT              NOT NULL,
        SucursalID       INT              NOT NULL,
        EmpleadoID       INT              NOT NULL,
        EstadoID         TINYINT          NOT NULL
            CONSTRAINT DF_Pedidos_EstadoID DEFAULT (1),
        MonedaID         TINYINT          NOT NULL,
        FechaPedido      DATETIME2(3)     NOT NULL
            CONSTRAINT DF_Pedidos_FechaPedido DEFAULT (SYSUTCDATETIME()),
        FechaCompletado  DATETIME2(3)     NULL,
        Notas            NVARCHAR(500)    NULL,
        UsuarioCreacion  SYSNAME          NOT NULL
            CONSTRAINT DF_Pedidos_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        ValidoDesde      DATETIME2(3)     GENERATED ALWAYS AS ROW START   HIDDEN NOT NULL,
        ValidoHasta      DATETIME2(3)     GENERATED ALWAYS AS ROW END     HIDDEN NOT NULL,
        PERIOD FOR SYSTEM_TIME (ValidoDesde, ValidoHasta),

        CONSTRAINT PK_Pedidos             PRIMARY KEY CLUSTERED (PedidoID),
        CONSTRAINT FK_Pedidos_Clientes    FOREIGN KEY (ClienteID)
            REFERENCES ventas.Clientes (ClienteID),
        CONSTRAINT FK_Pedidos_Sucursales  FOREIGN KEY (SucursalID)
            REFERENCES geo.Sucursales (SucursalID),
        CONSTRAINT FK_Pedidos_Empleados   FOREIGN KEY (EmpleadoID)
            REFERENCES rrhh.Empleados (EmpleadoID),
        CONSTRAINT FK_Pedidos_Estados     FOREIGN KEY (EstadoID)
            REFERENCES catalogo.EstadosPedido (EstadoID),
        CONSTRAINT FK_Pedidos_Monedas     FOREIGN KEY (MonedaID)
            REFERENCES catalogo.Monedas (MonedaID)
    ) WITH (
        SYSTEM_VERSIONING = ON (HISTORY_TABLE = historia.PedidosHist, DATA_CONSISTENCY_CHECK = ON),
        DATA_COMPRESSION  = PAGE
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Pedidos_ClienteID' AND object_id = OBJECT_ID(N'ventas.Pedidos'))
    CREATE NONCLUSTERED INDEX IX_Pedidos_ClienteID  ON ventas.Pedidos (ClienteID)  INCLUDE (FechaPedido, EstadoID);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Pedidos_EmpleadoID' AND object_id = OBJECT_ID(N'ventas.Pedidos'))
    CREATE NONCLUSTERED INDEX IX_Pedidos_EmpleadoID ON ventas.Pedidos (EmpleadoID) INCLUDE (FechaPedido);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Pedidos_SucursalID' AND object_id = OBJECT_ID(N'ventas.Pedidos'))
    CREATE NONCLUSTERED INDEX IX_Pedidos_SucursalID ON ventas.Pedidos (SucursalID) INCLUDE (FechaPedido);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Pedidos_FechaPedido_Desc' AND object_id = OBJECT_ID(N'ventas.Pedidos'))
    CREATE NONCLUSTERED INDEX IX_Pedidos_FechaPedido_Desc ON ventas.Pedidos (FechaPedido DESC) INCLUDE (ClienteID, EstadoID);
-- Filtrado: solo pedidos abiertos (no completados ni cancelados). EsTerminal = 1 implica cerrado.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Pedidos_Estado_Abiertos' AND object_id = OBJECT_ID(N'ventas.Pedidos'))
    CREATE NONCLUSTERED INDEX IX_Pedidos_Estado_Abiertos
        ON ventas.Pedidos (EstadoID, FechaPedido DESC)
        INCLUDE (ClienteID)
        WHERE EstadoID IN (1, 2);  -- ajustar tras seedear EstadosPedido
GO

-- ----------------- ventas.DetallePedidos -----------------
IF OBJECT_ID(N'ventas.DetallePedidos', N'U') IS NULL
BEGIN
    CREATE TABLE ventas.DetallePedidos (
        DetalleID       INT              NOT NULL IDENTITY(1,1),
        PedidoID        INT              NOT NULL,
        ProductoID      INT              NOT NULL,
        Cantidad        INT              NOT NULL
            CONSTRAINT DF_DetallePedidos_Cantidad DEFAULT (1),
        PrecioUnitario  DECIMAL(12, 4)   NOT NULL,
        Descuento       DECIMAL(5, 4)    NOT NULL
            CONSTRAINT DF_DetallePedidos_Descuento DEFAULT (0),
        -- Columna calculada persistida — siempre consistente, indexable
        Subtotal        AS (CAST(Cantidad * PrecioUnitario * (1 - Descuento) AS DECIMAL(14, 4))) PERSISTED,

        CONSTRAINT PK_DetallePedidos              PRIMARY KEY CLUSTERED (DetalleID),
        CONSTRAINT UQ_DetallePedidos_PedidoProd   UNIQUE (PedidoID, ProductoID),
        CONSTRAINT FK_DetallePedidos_Pedidos      FOREIGN KEY (PedidoID)
            REFERENCES ventas.Pedidos (PedidoID)
            ON DELETE CASCADE,                                                 -- composición fuerte
        CONSTRAINT FK_DetallePedidos_Productos    FOREIGN KEY (ProductoID)
            REFERENCES catalogo.Productos (ProductoID),
        CONSTRAINT CK_DetallePedidos_Cantidad     CHECK (Cantidad > 0),
        CONSTRAINT CK_DetallePedidos_Precio       CHECK (PrecioUnitario >= 0),
        CONSTRAINT CK_DetallePedidos_Descuento    CHECK (Descuento >= 0 AND Descuento <= 1)
    ) WITH (DATA_COMPRESSION = PAGE);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_DetallePedidos_ProductoID' AND object_id = OBJECT_ID(N'ventas.DetallePedidos'))
    CREATE NONCLUSTERED INDEX IX_DetallePedidos_ProductoID
        ON ventas.DetallePedidos (ProductoID)
        INCLUDE (PedidoID, Cantidad, PrecioUnitario, Subtotal);
GO

-- =============================================================================================
-- 4. INVENTARIO — patrón de movimientos (en vez de columna escalar Stock)
-- =============================================================================================
IF OBJECT_ID(N'inventario.TiposMovimiento', N'U') IS NULL
BEGIN
    CREATE TABLE inventario.TiposMovimiento (
        TipoMovID   TINYINT       NOT NULL,
        Codigo      NVARCHAR(20)  NOT NULL,
        Descripcion NVARCHAR(100) NULL,
        Signo       SMALLINT      NOT NULL,   -- +1 entrada, -1 salida, 0 ajuste neto

        CONSTRAINT PK_TiposMovimiento     PRIMARY KEY CLUSTERED (TipoMovID),
        CONSTRAINT UQ_TiposMovimiento_Cd  UNIQUE (Codigo),
        CONSTRAINT CK_TiposMovimiento_Sgn CHECK (Signo IN (-1, 0, 1))
    );
END
GO

IF OBJECT_ID(N'inventario.Movimientos', N'U') IS NULL
BEGIN
    CREATE TABLE inventario.Movimientos (
        MovimientoID    BIGINT          NOT NULL IDENTITY(1,1),
        ProductoID      INT             NOT NULL,
        SucursalID      INT             NOT NULL,
        TipoMovID       TINYINT         NOT NULL,
        Cantidad        INT             NOT NULL,                  -- valor absoluto; signo viene del tipo
        PedidoID        INT             NULL,                      -- traza al pedido que originó la salida
        FechaMovimiento DATETIME2(3)    NOT NULL
            CONSTRAINT DF_Movimientos_Fecha DEFAULT (SYSUTCDATETIME()),
        UsuarioCreacion SYSNAME         NOT NULL
            CONSTRAINT DF_Movimientos_Usuario DEFAULT (SUSER_SNAME()),
        Notas           NVARCHAR(500)   NULL,

        CONSTRAINT PK_Movimientos             PRIMARY KEY CLUSTERED (MovimientoID),
        CONSTRAINT FK_Movimientos_Productos   FOREIGN KEY (ProductoID)
            REFERENCES catalogo.Productos (ProductoID),
        CONSTRAINT FK_Movimientos_Sucursales  FOREIGN KEY (SucursalID)
            REFERENCES geo.Sucursales (SucursalID),
        CONSTRAINT FK_Movimientos_Tipos       FOREIGN KEY (TipoMovID)
            REFERENCES inventario.TiposMovimiento (TipoMovID),
        CONSTRAINT FK_Movimientos_Pedidos     FOREIGN KEY (PedidoID)
            REFERENCES ventas.Pedidos (PedidoID),
        CONSTRAINT CK_Movimientos_Cantidad    CHECK (Cantidad > 0)
    ) WITH (DATA_COMPRESSION = PAGE);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Movimientos_ProdSuc_Fecha' AND object_id = OBJECT_ID(N'inventario.Movimientos'))
    CREATE NONCLUSTERED INDEX IX_Movimientos_ProdSuc_Fecha
        ON inventario.Movimientos (ProductoID, SucursalID, FechaMovimiento DESC)
        INCLUDE (TipoMovID, Cantidad);
GO

-- =============================================================================================
-- 5. VISTAS INDEXADAS — totales pre-agregados de pedidos (no requieren mantenimiento manual)
-- =============================================================================================
-- Una vista indexada materializa el resultado y se mantiene automáticamente al cambiar las
-- filas base. Elimina el problema del Total escalar redundante en Pedidos.
IF OBJECT_ID(N'ventas.vw_PedidoTotales', N'V') IS NOT NULL
    DROP VIEW ventas.vw_PedidoTotales;
GO

CREATE VIEW ventas.vw_PedidoTotales
WITH SCHEMABINDING
AS
SELECT
    dp.PedidoID,
    SUM(dp.Subtotal)                         AS Total,
    SUM(dp.Cantidad)                         AS UnidadesTotales,
    COUNT_BIG(*)                             AS NumLineas
FROM ventas.DetallePedidos AS dp
GROUP BY dp.PedidoID;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_vw_PedidoTotales' AND object_id = OBJECT_ID(N'ventas.vw_PedidoTotales'))
    CREATE UNIQUE CLUSTERED INDEX IX_vw_PedidoTotales
        ON ventas.vw_PedidoTotales (PedidoID);
GO

-- =============================================================================================
-- 6. TRIGGER DE AUDITORÍA — sólo registra fecha/usuario de modificación
-- =============================================================================================
-- Para Clientes: usa la metadata mínima necesaria. Las tablas temporales ya guardan el history;
-- esto sólo asegura que las columnas FechaModif/UsuarioModif reflejen la última edición.
IF OBJECT_ID(N'ventas.tr_Clientes_AfterUpdate', N'TR') IS NOT NULL
    DROP TRIGGER ventas.tr_Clientes_AfterUpdate;
GO

CREATE TRIGGER ventas.tr_Clientes_AfterUpdate
ON ventas.Clientes
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(FechaModif)  -- evita recursión si el UPDATE ya las tocó
    BEGIN
        UPDATE c
        SET c.FechaModif   = SYSUTCDATETIME(),
            c.UsuarioModif = SUSER_SNAME()
        FROM ventas.Clientes AS c
        INNER JOIN inserted AS i ON i.ClienteID = c.ClienteID;
    END
END
GO

-- =============================================================================================
-- 7. TABLE-VALUED PARAMETER + STORED PROCEDURE ATÓMICO
-- =============================================================================================
-- Permite insertar un pedido y todas sus líneas + movimientos de inventario en UNA transacción.
-- Elimina round-trips y garantiza atomicidad real.
IF TYPE_ID(N'ventas.DetallePedidoTipo') IS NOT NULL
    DROP TYPE ventas.DetallePedidoTipo;
GO

CREATE TYPE ventas.DetallePedidoTipo AS TABLE (
    ProductoID     INT             NOT NULL,
    Cantidad       INT             NOT NULL,
    PrecioUnitario DECIMAL(12, 4)  NOT NULL,
    Descuento      DECIMAL(5, 4)   NOT NULL DEFAULT (0),
    PRIMARY KEY CLUSTERED (ProductoID)
);
GO

CREATE OR ALTER PROCEDURE ventas.usp_CrearPedido
    @ClienteID  INT,
    @SucursalID INT,
    @EmpleadoID INT,
    @MonedaID   TINYINT,
    @Notas      NVARCHAR(500) = NULL,
    @Detalle    ventas.DetallePedidoTipo READONLY,
    @PedidoID   INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validaciones tempranas
    IF NOT EXISTS (SELECT 1 FROM @Detalle)
        THROW 50001, N'El detalle del pedido no puede estar vacío.', 1;

    IF EXISTS (
        SELECT 1
        FROM @Detalle d
        LEFT JOIN catalogo.Productos p ON p.ProductoID = d.ProductoID AND p.Activo = 1
        WHERE p.ProductoID IS NULL
    )
        THROW 50002, N'Uno o más productos no existen o están inactivos.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO ventas.Pedidos (ClienteID, SucursalID, EmpleadoID, MonedaID, Notas)
        VALUES (@ClienteID, @SucursalID, @EmpleadoID, @MonedaID, @Notas);

        SET @PedidoID = SCOPE_IDENTITY();

        INSERT INTO ventas.DetallePedidos (PedidoID, ProductoID, Cantidad, PrecioUnitario, Descuento)
        SELECT @PedidoID, d.ProductoID, d.Cantidad, d.PrecioUnitario, d.Descuento
        FROM @Detalle d;

        -- Generar movimientos de inventario tipo SALIDA (TipoMovID 2 por convención)
        INSERT INTO inventario.Movimientos (ProductoID, SucursalID, TipoMovID, Cantidad, PedidoID)
        SELECT d.ProductoID, @SucursalID, 2, d.Cantidad, @PedidoID
        FROM @Detalle d;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- =============================================================================================
-- 8. SEED IDEMPOTENTE DE CATÁLOGOS — MERGE para inserción/actualización segura
-- =============================================================================================
MERGE catalogo.EstadosPedido AS tgt
USING (VALUES
    (1, N'PENDIENTE',  N'Pedido registrado, pendiente de procesar', 0),
    (2, N'EN_PROCESO', N'Pedido en preparación',                    0),
    (3, N'COMPLETADO', N'Pedido entregado al cliente',              1),
    (4, N'CANCELADO',  N'Pedido cancelado',                         1)
) AS src (EstadoID, Codigo, Descripcion, EsTerminal)
ON tgt.EstadoID = src.EstadoID
WHEN MATCHED AND (tgt.Codigo <> src.Codigo OR ISNULL(tgt.Descripcion, N'') <> src.Descripcion OR tgt.EsTerminal <> src.EsTerminal)
    THEN UPDATE SET Codigo = src.Codigo, Descripcion = src.Descripcion, EsTerminal = src.EsTerminal
WHEN NOT MATCHED BY TARGET
    THEN INSERT (EstadoID, Codigo, Descripcion, EsTerminal)
         VALUES (src.EstadoID, src.Codigo, src.Descripcion, src.EsTerminal);
GO

MERGE inventario.TiposMovimiento AS tgt
USING (VALUES
    (1, N'ENTRADA', N'Ingreso de stock',         +1),
    (2, N'SALIDA',  N'Salida de stock por venta', -1),
    (3, N'AJUSTE',  N'Ajuste por inventario',     0),
    (4, N'MERMA',   N'Merma o desperdicio',      -1)
) AS src (TipoMovID, Codigo, Descripcion, Signo)
ON tgt.TipoMovID = src.TipoMovID
WHEN MATCHED AND (tgt.Codigo <> src.Codigo OR tgt.Signo <> src.Signo)
    THEN UPDATE SET Codigo = src.Codigo, Descripcion = src.Descripcion, Signo = src.Signo
WHEN NOT MATCHED BY TARGET
    THEN INSERT (TipoMovID, Codigo, Descripcion, Signo)
         VALUES (src.TipoMovID, src.Codigo, src.Descripcion, src.Signo);
GO

-- =============================================================================================
-- 9. DOCUMENTACIÓN — Extended Properties visibles en SSMS y herramientas de modelado
-- =============================================================================================
DECLARE @desc NVARCHAR(MAX);

SET @desc = N'Catálogo maestro de países (ISO 3166-1) donde opera TiendaLatam.';
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID(N'geo.Paises') AND minor_id = 0 AND name = N'MS_Description')
    EXEC sp_addextendedproperty N'MS_Description', @desc, N'SCHEMA', N'geo', N'TABLE', N'Paises';

SET @desc = N'Tabla de pedidos. System-versioned: el histórico vive en historia.PedidosHist.';
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID(N'ventas.Pedidos') AND minor_id = 0 AND name = N'MS_Description')
    EXEC sp_addextendedproperty N'MS_Description', @desc, N'SCHEMA', N'ventas', N'TABLE', N'Pedidos';

SET @desc = N'Vista indexada: totales pre-agregados por pedido. Reemplaza el campo escalar Total.';
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID(N'ventas.vw_PedidoTotales') AND minor_id = 0 AND name = N'MS_Description')
    EXEC sp_addextendedproperty N'MS_Description', @desc, N'SCHEMA', N'ventas', N'VIEW', N'vw_PedidoTotales';
GO

-- =============================================================================================
-- 10. VERIFICACIÓN — separado para ejecutarse a discreción, no como parte del deploy
-- =============================================================================================
PRINT N'=== Tablas creadas ===';
SELECT s.name AS Esquema, t.name AS Tabla, p.rows AS RowsAprox, t.temporal_type_desc AS TipoTemporal
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE s.name IN (N'geo', N'catalogo', N'rrhh', N'ventas', N'inventario', N'historia')
ORDER BY s.name, t.name;

PRINT N'=== Claves foráneas ===';
SELECT
    fk.name                                                          AS NombreFK,
    OBJECT_SCHEMA_NAME(fk.parent_object_id) + N'.' + OBJECT_NAME(fk.parent_object_id)        AS Hijo,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + N'.' + OBJECT_NAME(fk.referenced_object_id) AS Padre,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys fk
ORDER BY Hijo, NombreFK;

PRINT N'=== Índices (excluyendo PKs) ===';
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) + N'.' + OBJECT_NAME(i.object_id) AS Tabla,
    i.name        AS Indice,
    i.type_desc   AS Tipo,
    i.is_unique   AS EsUnico,
    i.has_filter  AS EsFiltrado,
    i.filter_definition AS Filtro
FROM sys.indexes i
WHERE i.is_primary_key = 0
  AND i.name IS NOT NULL
  AND OBJECT_SCHEMA_NAME(i.object_id) IN (N'geo', N'catalogo', N'rrhh', N'ventas', N'inventario')
ORDER BY Tabla, i.name;
GO

PRINT N'>> DDL avanzado aplicado correctamente.';
GO
