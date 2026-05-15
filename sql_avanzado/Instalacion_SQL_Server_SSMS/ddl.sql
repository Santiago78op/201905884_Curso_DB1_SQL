IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'TiendaLatam')
BEGIN
    CREATE DATABASE TiendaLatam;
    PRINT 'Base de datos TiendaLatam creada.';
END
ELSE
    PRINT 'Base de datos TiendaLatam ya existe — continuando.';
GO

USE TiendaLatam;
GO

SELECT DB_NAME() AS BaseDeDatosActual;
GO

CREATE TABLE dbo.Paises (
    PaisID       INT            NOT NULL IDENTITY(1,1),
    CodigoPais   NVARCHAR(2)    NOT NULL,
    NombrePais   NVARCHAR(100)  NOT NULL,
    Continente   NVARCHAR(50)   NULL,

    CONSTRAINT PK_Paises         PRIMARY KEY (PaisID),
    CONSTRAINT UQ_Paises_Codigo  UNIQUE (CodigoPais)
);
GO

CREATE TABLE dbo.Categorias (
    CategoriaID      INT            NOT NULL IDENTITY(1,1),
    NombreCategoria  NVARCHAR(100)  NOT NULL,
    Descripcion      NVARCHAR(500)  NULL,

    CONSTRAINT PK_Categorias PRIMARY KEY (CategoriaID)
);
GO

CREATE TABLE dbo.TiposCliente (
    TipoClienteID  INT            NOT NULL IDENTITY(1,1),
    NombreTipo     NVARCHAR(50)   NOT NULL,
    Descripcion    NVARCHAR(500)  NULL,

    CONSTRAINT PK_TiposCliente PRIMARY KEY (TipoClienteID)
);
GO

CREATE TABLE dbo.Sucursales (
    SucursalID        INT            NOT NULL IDENTITY(1,1),
    NombreSucursal    NVARCHAR(150)  NOT NULL,
    Ciudad            NVARCHAR(100)  NULL,
    PaisID            INT            NOT NULL,
    DireccionCompleta NVARCHAR(300)  NULL,
    Activo            BIT            NOT NULL DEFAULT 1,

    CONSTRAINT PK_Sucursales          PRIMARY KEY (SucursalID),
    CONSTRAINT FK_Sucursales_Paises   FOREIGN KEY (PaisID)
        REFERENCES dbo.Paises (PaisID)
);
GO

CREATE NONCLUSTERED INDEX IX_Sucursales_PaisID
    ON dbo.Sucursales (PaisID);
GO

CREATE TABLE dbo.Productos (
    ProductoID      INT              NOT NULL IDENTITY(1,1),
    CodigoProducto  NVARCHAR(20)     NOT NULL,
    NombreProducto  NVARCHAR(200)    NOT NULL,
    CategoriaID     INT              NOT NULL,
    Precio          DECIMAL(10, 2)   NOT NULL,
    Stock           INT              NOT NULL DEFAULT 0,
    Descripcion     NVARCHAR(500)    NULL,
    Activo          BIT              NOT NULL DEFAULT 1,

    CONSTRAINT PK_Productos             PRIMARY KEY (ProductoID),
    CONSTRAINT UQ_Productos_Codigo      UNIQUE (CodigoProducto),
    CONSTRAINT FK_Productos_Categorias  FOREIGN KEY (CategoriaID)
        REFERENCES dbo.Categorias (CategoriaID),
    CONSTRAINT CK_Productos_Precio      CHECK (Precio >= 0),
    CONSTRAINT CK_Productos_Stock       CHECK (Stock >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_Productos_CategoriaID
    ON dbo.Productos (CategoriaID);
GO

CREATE TABLE dbo.Empleados (
    EmpleadoID    INT            NOT NULL IDENTITY(1,1),
    Nombre        NVARCHAR(100)  NOT NULL,
    Apellido      NVARCHAR(100)  NOT NULL,
    Email         NVARCHAR(200)  NULL,
    SucursalID    INT            NOT NULL,
    FechaIngreso  DATE           NULL,
    Cargo         NVARCHAR(100)  NULL,
    Activo        BIT            NOT NULL DEFAULT 1,

    CONSTRAINT PK_Empleados             PRIMARY KEY (EmpleadoID),
    CONSTRAINT FK_Empleados_Sucursales  FOREIGN KEY (SucursalID)
        REFERENCES dbo.Sucursales (SucursalID)
);
GO

CREATE NONCLUSTERED INDEX IX_Empleados_SucursalID
    ON dbo.Empleados (SucursalID);
GO

CREATE TABLE dbo.Clientes (
    ClienteID       INT            NOT NULL IDENTITY(1,1),
    Nombre          NVARCHAR(100)  NOT NULL,
    Apellido        NVARCHAR(100)  NOT NULL,
    Email           NVARCHAR(200)  NULL,
    Telefono        NVARCHAR(30)   NULL,
    PaisID          INT            NOT NULL,
    Ciudad          NVARCHAR(100)  NULL,
    TipoClienteID   INT            NOT NULL DEFAULT 1,
    FechaRegistro   DATE           NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    Activo          BIT            NOT NULL DEFAULT 1,

    CONSTRAINT PK_Clientes               PRIMARY KEY (ClienteID),
    CONSTRAINT FK_Clientes_Paises        FOREIGN KEY (PaisID)
        REFERENCES dbo.Paises (PaisID),
    CONSTRAINT FK_Clientes_TiposCliente  FOREIGN KEY (TipoClienteID)
        REFERENCES dbo.TiposCliente (TipoClienteID)
);
GO

CREATE NONCLUSTERED INDEX IX_Clientes_PaisID
    ON dbo.Clientes (PaisID);

CREATE NONCLUSTERED INDEX IX_Clientes_TipoClienteID
    ON dbo.Clientes (TipoClienteID);

CREATE NONCLUSTERED INDEX IX_Clientes_FechaRegistro
    ON dbo.Clientes (FechaRegistro);
GO

CREATE TABLE dbo.Pedidos (
    PedidoID     INT              NOT NULL IDENTITY(1,1),
    ClienteID    INT              NOT NULL,
    SucursalID   INT              NOT NULL,
    EmpleadoID   INT              NOT NULL,
    FechaPedido  DATETIME         NOT NULL DEFAULT GETDATE(),
    Estado       NVARCHAR(20)     NOT NULL DEFAULT 'Pendiente',
    Total        DECIMAL(12, 2)   NOT NULL DEFAULT 0,
    Notas        NVARCHAR(500)    NULL,

    CONSTRAINT PK_Pedidos             PRIMARY KEY (PedidoID),
    CONSTRAINT FK_Pedidos_Clientes    FOREIGN KEY (ClienteID)
        REFERENCES dbo.Clientes (ClienteID),
    CONSTRAINT FK_Pedidos_Sucursales  FOREIGN KEY (SucursalID)
        REFERENCES dbo.Sucursales (SucursalID),
    CONSTRAINT FK_Pedidos_Empleados   FOREIGN KEY (EmpleadoID)
        REFERENCES dbo.Empleados (EmpleadoID),
    CONSTRAINT CK_Pedidos_Estado      CHECK (Estado IN ('Pendiente','Completado','Cancelado','En proceso')),
    CONSTRAINT CK_Pedidos_Total       CHECK (Total >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_Pedidos_ClienteID
    ON dbo.Pedidos (ClienteID)
    INCLUDE (Total, FechaPedido, Estado);

CREATE NONCLUSTERED INDEX IX_Pedidos_EmpleadoID
    ON dbo.Pedidos (EmpleadoID)
    INCLUDE (Total, FechaPedido);

CREATE NONCLUSTERED INDEX IX_Pedidos_SucursalID
    ON dbo.Pedidos (SucursalID);

CREATE NONCLUSTERED INDEX IX_Pedidos_FechaPedido
    ON dbo.Pedidos (FechaPedido)
    INCLUDE (ClienteID, Total, Estado);

CREATE NONCLUSTERED INDEX IX_Pedidos_Estado
    ON dbo.Pedidos (Estado)
    INCLUDE (ClienteID, Total, FechaPedido);
GO

CREATE TABLE dbo.DetallePedidos (
    DetalleID       INT              NOT NULL IDENTITY(1,1),
    PedidoID        INT              NOT NULL,
    ProductoID      INT              NOT NULL,
    Cantidad        INT              NOT NULL DEFAULT 1,
    PrecioUnitario  DECIMAL(10, 2)   NOT NULL,

    CONSTRAINT PK_DetallePedidos            PRIMARY KEY (DetalleID),
    CONSTRAINT FK_DetallePedidos_Pedidos    FOREIGN KEY (PedidoID)
        REFERENCES dbo.Pedidos (PedidoID),
    CONSTRAINT FK_DetallePedidos_Productos  FOREIGN KEY (ProductoID)
        REFERENCES dbo.Productos (ProductoID),
    CONSTRAINT CK_DetallePedidos_Cantidad   CHECK (Cantidad > 0),
    CONSTRAINT CK_DetallePedidos_Precio     CHECK (PrecioUnitario >= 0)
);
GO

CREATE NONCLUSTERED INDEX IX_DetallePedidos_PedidoID
    ON dbo.DetallePedidos (PedidoID)
    INCLUDE (ProductoID, Cantidad, PrecioUnitario);

CREATE NONCLUSTERED INDEX IX_DetallePedidos_ProductoID
    ON dbo.DetallePedidos (ProductoID)
    INCLUDE (PedidoID, Cantidad, PrecioUnitario);
GO

PRINT '=== VERIFICACIÓN: Tablas creadas ===';
SELECT
    TABLE_SCHEMA   AS Esquema,
    TABLE_NAME     AS Tabla,
    TABLE_TYPE     AS Tipo
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

PRINT '=== VERIFICACIÓN: Claves foráneas ===';
SELECT
    fk.name                                                          AS NombreFK,
    OBJECT_NAME(fk.parent_object_id)                                 AS TablaHijo,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id)            AS ColumnaHijo,
    OBJECT_NAME(fk.referenced_object_id)                             AS TablaPadre,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id)    AS ColumnaPadre
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY TablaHijo, NombreFK;

PRINT '=== VERIFICACIÓN: Índices creados ===';
SELECT
    OBJECT_NAME(i.object_id)  AS Tabla,
    i.name                    AS NombreIndice,
    i.type_desc               AS Tipo
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) IN
    ('Paises','Categorias','TiposCliente','Sucursales','Empleados',
     'Clientes','Productos','Pedidos','DetallePedidos')
  AND i.name IS NOT NULL
ORDER BY Tabla, Tipo DESC, NombreIndice;
GO
