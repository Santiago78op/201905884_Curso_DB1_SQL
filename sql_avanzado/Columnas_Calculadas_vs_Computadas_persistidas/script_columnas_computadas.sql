USE TiendaLatam;
GO

SELECT NombreProducto, Precio, (Precio - Costo) / Precio * 100 AS MargenPorcentaje FROM Productos.

ALTER TABLE Productos
-- ADD PrecioConIVA AS (Precio * 1.21);

SELECT NombreProducto, Precio, PrecioConIVA FROM Productos;

UPDATE Productos SET PrecioConIVA = 100;  -- ✗ Error: cannot update computed column

ALTER TABLE Productos ADD Costo DECIMAL(10,2) NULL;
GO

ALTER TABLE Productos
-- ADD MargenPorcentaje AS (
-- CASE
-- WHEN Costo IS NULL OR Costo = 0 THEN NULL
-- ELSE CAST((Precio - Costo) / Precio * 100 AS DECIMAL(5,2))
    END
) PERSISTED;
GO

SELECT NombreProducto, Precio, Costo, MargenPorcentaje FROM Productos WHERE Costo IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_Productos_MargenPorcentaje
ON Productos (MargenPorcentaje)
WHERE MargenPorcentaje IS NOT NULL;  -- índice filtrado

SELECT NombreProducto, MargenPorcentaje
FROM Productos
WHERE MargenPorcentaje > 30
ORDER BY MargenPorcentaje DESC;
