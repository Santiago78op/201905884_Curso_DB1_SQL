USE TiendaLatam;
GO

SELECT Nombre, VentasMes, VentasMes - LAG(VentasMes) OVER (PARTITION BY Pais ORDER BY Mes) AS Crecimiento
FROM (
    SELECT
        pa.NombrePais AS Pais,
        MONTH(p.FechaPedido) AS Mes,
        SUM(p.Total) AS VentasMes,
        MIN(c.Nombre) AS Nombre
    FROM Pedidos p
    INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
    INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
    GROUP BY pa.NombrePais, MONTH(p.FechaPedido)
) AS base
ORDER BY Pais, Mes;
