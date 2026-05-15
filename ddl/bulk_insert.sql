USE TiendaLatam;
GO

BULK INSERT Paises
FROM 'C:\TiendaLatam_CSV\01_Paises.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO


BULK INSERT Categorias
FROM 'C:\TiendaLatam_CSV\02_Categorias.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO

BULK INSERT TiposCliente
FROM 'C:\TiendaLatam_CSV\03_TiposCliente.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO

-- Sucursales: INSERT directo (evita problemas de BULK INSERT con comas en DireccionCompleta)

DELETE FROM Sucursales;
DBCC CHECKIDENT ('Sucursales', RESEED, 0);

SET IDENTITY_INSERT Sucursales ON;

INSERT INTO Sucursales (SucursalID, NombreSucursal, Ciudad, PaisID, DireccionCompleta, Activo) VALUES
(1, 'Sucursal Buenos Aires Centro', 'Buenos Aires', 1, 'Av. Corrientes 1234, CABA', 1),
(2, 'Sucursal Palermo', 'Buenos Aires', 1, 'Thames 1850, Palermo, CABA', 1),
(3, 'Sucursal Córdoba', 'Córdoba', 1, 'Av. Colón 567, Córdoba', 1),
(4, 'Sucursal Santiago Centro', 'Santiago', 2, 'Av. Libertador Bernardo O''Higgins 890', 1),
(5, 'Sucursal Providencia', 'Santiago', 2, 'Av. Providencia 1234, Providencia', 1),
(6, 'Sucursal Lima Miraflores', 'Lima', 3, 'Av. Larco 456, Miraflores', 1),
(7, 'Sucursal Lima San Isidro', 'Lima', 3, 'Av. Rivera Navarrete 789, San Isidro', 1),
(8, 'Sucursal Bogotá Chapinero', 'Bogotá', 4, 'Cra. 13 #67-45, Chapinero', 1),
(9, 'Sucursal Medellín El Poblado', 'Medellín', 4, 'Calle 10 #43D-25, El Poblado', 1),
(10, 'Sucursal Ciudad de México Polanco', 'Ciudad de México', 5, 'Presidente Masaryk 123, Polanco', 1),
(11, 'Sucursal Monterrey', 'Monterrey', 5, 'Av. Constitución 456, Monterrey', 1),
(12, 'Sucursal São Paulo Paulista', 'São Paulo', 6, 'Av. Paulista 1578, São Paulo', 1),
(13, 'Sucursal Rio de Janeiro', 'Rio de Janeiro', 6, 'Av. Atlântica 2000, Copacabana', 1),
(14, 'Sucursal Montevideo', 'Montevideo', 7, '18 de Julio 890, Centro', 1),
(15, 'Sucursal Asunción', 'Asunción', 8, 'Av. España 567, Asunción', 1),
(16, 'Sucursal La Paz', 'La Paz', 9, 'Av. 16 de Julio 1234, La Paz', 1),
(17, 'Sucursal Quito', 'Quito', 10, 'Av. Naciones Unidas 456, Quito', 1),
(18, 'Sucursal Guayaquil', 'Guayaquil', 10, 'Av. 9 de Octubre 789, Guayaquil', 1),
(19, 'Sucursal Caracas', 'Caracas', 11, 'Av. Francisco de Miranda 123, Chacao', 1),
(20, 'Sucursal Ciudad de Panamá', 'Ciudad de Panamá', 12, 'Via España 456, Bella Vista', 1);

SET IDENTITY_INSERT Sucursales OFF;



BULK INSERT Empleados
FROM 'C:\TiendaLatam_CSV\05_Empleados.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO

BULK INSERT Clientes
FROM 'C:\TiendaLatam_CSV\06_Clientes.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001');
GO

BULK INSERT Productos
FROM 'C:\TiendaLatam_CSV\07_Productos.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\r\n', CODEPAGE = '65001', FIELDQUOTE = '"');
GO

-- Pedidos: campo Notas vacío al final de la fila
BULK INSERT Pedidos
FROM 'C:\TiendaLatam_CSV\08_Pedidos.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    FIELDQUOTE = '"'
);
GO

-- DetallePedidos
BULK INSERT DetallePedidos
FROM 'C:\TiendaLatam_CSV\09_DetallePedidos.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    FIELDQUOTE = '"'
);
GO


USE TiendaLatam;
GO

SELECT 'Paises'           AS Tabla, COUNT(*) AS Registros FROM Paises          UNION ALL
SELECT 'Categorias',                COUNT(*)              FROM Categorias       UNION ALL
SELECT 'TiposCliente',              COUNT(*)              FROM TiposCliente     UNION ALL
SELECT 'Sucursales',                COUNT(*)              FROM Sucursales       UNION ALL
SELECT 'Empleados',                 COUNT(*)              FROM Empleados        UNION ALL
SELECT 'Clientes',                  COUNT(*)              FROM Clientes         UNION ALL
SELECT 'Productos',                 COUNT(*)              FROM Productos        UNION ALL
SELECT 'Pedidos',                   COUNT(*)              FROM Pedidos          UNION ALL
SELECT 'DetallePedidos',            COUNT(*)              FROM DetallePedidos
ORDER BY 1;



SET IDENTITY_INSERT Sucursales ON;

INSERT INTO Sucursales (SucursalID, NombreSucursal, Ciudad, PaisID, DireccionCompleta, Activo)
VALUES
(21, 'Sucursal Recién Inaugurada', 'Quito',     6, 'Av. Amazonas 1000, Quito',       1),
(22, 'Sucursal En Construcción',   'La Paz',    5, 'Av. 6 de Agosto 500, La Paz',    0),
(23, 'Sucursal Piloto',            'Asunción',  8, 'Av. Mariscal López 200, Asunción', 1);

SET IDENTITY_INSERT Sucursales OFF;
