USE TiendaLatam;
GO

CREATE VIEW VW_ResumenVentasPais
WITH SCHEMABINDING AS
SELECT
    c.PaisID,
    YEAR(p.FechaPedido)    AS Anio,
    MONTH(p.FechaPedido)   AS Mes,
    COUNT_BIG(*)           AS CantidadPedidos,
    SUM(p.Total)           AS VentasTotales
FROM dbo.Pedidos p
INNER JOIN dbo.Clientes c ON p.ClienteID = c.ClienteID
WHERE p.Estado = 'Completado'
GROUP BY c.PaisID, YEAR(p.FechaPedido), MONTH(p.FechaPedido);
GO

CREATE UNIQUE CLUSTERED INDEX IX_VW_ResumenVentasPais
ON VW_ResumenVentasPais (PaisID, Anio, Mes);
GO

SELECT PaisID, Anio, Mes, VentasTotales FROM VW_ResumenVentasPais;

SELECT PaisID, Anio, Mes, VentasTotales
FROM VW_ResumenVentasPais WITH (NOEXPAND);

ALTER TABLE dbo.Pedidos DROP COLUMN Total;
-- Error: Cannot drop the column because it is used by an object.
