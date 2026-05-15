USE TiendaLatam;
GO

CREATE VIEW VW_VentasPorPais AS
SELECT
    pa.CodigoPais,
    pa.NombrePais,
    YEAR(p.FechaPedido)  AS Anio,
    MONTH(p.FechaPedido) AS Mes,
    COUNT(p.PedidoID)    AS CantidadPedidos,
    SUM(p.Total)         AS VentasTotales,
    AVG(p.Total)         AS TicketPromedio
FROM Pedidos p
INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
WHERE p.Estado = 'Completado'
GROUP BY pa.CodigoPais, pa.NombrePais, YEAR(p.FechaPedido), MONTH(p.FechaPedido);

GO

SELECT * FROM VW_VentasPorPais WHERE NombrePais = 'Argentina' ORDER BY Anio, Mes;
SELECT NombrePais, SUM(VentasTotales) AS TotalHistorico FROM VW_VentasPorPais GROUP BY NombrePais;

ALTER VIEW VW_VentasPorPais AS
SELECT
    pa.CodigoPais,
    pa.NombrePais,
    YEAR(p.FechaPedido)  AS Anio,
    MONTH(p.FechaPedido) AS Mes,
    COUNT(p.PedidoID)    AS CantidadPedidos,
    SUM(p.Total)         AS VentasTotales,
    AVG(p.Total)         AS TicketPromedio,
    MIN(p.Total)         AS VentaMinima,
    MAX(p.Total)         AS VentaMaxima
FROM Pedidos p
INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
WHERE p.Estado = 'Completado'
GROUP BY pa.CodigoPais, pa.NombrePais, YEAR(p.FechaPedido), MONTH(p.FechaPedido);
GO

DROP VIEW IF EXISTS VW_VentasPorPais;

EXEC sp_helptext 'VW_VentasPorPais';

GRANT SELECT ON VW_VentasPorPais TO [Analista_Ventas];

SELECT * FROM VW_VentasPorPais;           -- ✓ permitido

SELECT * FROM Pedidos;                    -- ✗ denegado (sin acceso a la tabla base)
SELECT * FROM Clientes;                   -- ✗ denegado
