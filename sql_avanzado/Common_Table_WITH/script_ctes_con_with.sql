USE TiendaLatam;
GO

SELECT *
FROM (
    SELECT
        pais, empleado, ventas_totales,
        RANK() OVER (PARTITION BY pais ORDER BY ventas_totales DESC) AS ranking
    FROM (
        SELECT
            pa.NombrePais AS pais,
            e.Nombre      AS empleado,
            SUM(p.Total)  AS ventas_totales
        FROM Pedidos p
        INNER JOIN Empleados e  ON p.EmpleadoID = e.EmpleadoID
        INNER JOIN Sucursales s ON e.SucursalID  = s.SucursalID
        INNER JOIN Paises pa   ON s.PaisID       = pa.PaisID
        WHERE p.Estado = 'Completado'
        GROUP BY pa.NombrePais, e.Nombre
    ) AS base
) AS con_ranking
WHERE ranking <= 3
  AND pais IN (
      SELECT pa.NombrePais
      FROM Pedidos p
      INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
      INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
      WHERE p.Estado = 'Completado'
      GROUP BY pa.NombrePais
      HAVING SUM(p.Total) > 100000
  )
ORDER BY pais, ranking;

-- WITH
-- VentasPorEmpleado AS (
    SELECT
        pa.NombrePais,
        e.EmpleadoID,
        e.Nombre      AS NombreEmpleado,
        SUM(p.Total)  AS VentasTotales
    FROM Pedidos p
    INNER JOIN Empleados e  ON p.EmpleadoID = e.EmpleadoID
    INNER JOIN Sucursales s ON e.SucursalID  = s.SucursalID
    INNER JOIN Paises pa   ON s.PaisID       = pa.PaisID
    WHERE p.Estado = 'Completado'
    GROUP BY pa.NombrePais, e.EmpleadoID, e.Nombre
),
-- ConRanking AS (
    SELECT
        NombrePais,
        NombreEmpleado,
        VentasTotales,
        RANK() OVER (PARTITION BY NombrePais ORDER BY VentasTotales DESC) AS Ranking
    FROM VentasPorEmpleado
),
-- PaisesRelevantes AS (
    SELECT NombrePais
    FROM VentasPorEmpleado
    GROUP BY NombrePais
    HAVING SUM(VentasTotales) > 100000
)
SELECT
    cr.NombrePais,
    cr.NombreEmpleado,
    cr.VentasTotales,
    cr.Ranking
FROM ConRanking cr
INNER JOIN PaisesRelevantes pr ON cr.NombrePais = pr.NombrePais
WHERE cr.Ranking <= 3
ORDER BY cr.NombrePais, cr.Ranking;

WITH Jerarquia AS (
    SELECT
        EmpleadoID,
        Nombre,
        SupervisorID,
        0 AS Nivel,
        CAST(Nombre AS NVARCHAR(500)) AS Camino
    FROM Empleados
    WHERE SupervisorID IS NULL

    UNION ALL

    SELECT
        e.EmpleadoID,
        e.Nombre,
        e.SupervisorID,
        j.Nivel + 1,
        CAST(j.Camino + ' → ' + e.Nombre AS NVARCHAR(500))
    FROM Empleados e
    INNER JOIN Jerarquia j ON e.SupervisorID = j.EmpleadoID
)
SELECT EmpleadoID, Nombre, Nivel, Camino
FROM Jerarquia
ORDER BY Nivel, Nombre;

-- OPTION (MAXRECURSION 50)

-- SELECT Nombre, VentasMes, VentasMes - LAG(VentasMes) OVER (PARTITION BY Pais ORDER BY Mes) AS Crecimiento
-- FROM (
-- SELECT pa.NombrePais AS Pais, MONTH(p.FechaPedido) AS Mes, SUM(p.Total) AS VentasMes,
-- MIN(c.Nombre) AS Nombre
-- FROM Pedidos p
-- INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
-- INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
-- GROUP BY pa.NombrePais, MONTH(p.FechaPedido)
-- ) AS base
-- ORDER BY Pais, Mes;
