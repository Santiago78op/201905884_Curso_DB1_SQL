USE TiendaLatam;
GO

EXEC SP_CierreDeMes '2025-01-01', '2025-01-31', 'AR';

CREATE PROCEDURE SP_ConsultarVentasPorPais
   @CodigoPais   NVARCHAR(2),
   @FechaInicio  DATE,
   @FechaFin     DATE
   AS
  beGIN
    SET NOCOUNT ON;  -- evita que SQL Server cuente las filas afectadas (mejora rendimiento)

    SELECT
   pa.NombrePais,
   pa.CodigoPais,
   COUNT(p.PedidoID)    AS TotalPedidos,
   SUM(p.Total)         AS VentasTotales,
   AVG(p.Total)         AS TicketPromedio,
   MIN(p.FechaPedido)   AS PrimerPedido,
   MAX(p.FechaPedido)   AS UltimoPedido
    FROM Pedidos p
    INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
    INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
    WHERE pa.CodigoPais   = @CodigoPais
      AND p.FechaPedido  >= @FechaInicio
      AND p.FechaPedido  <= DATEADD(DAY, 1, @FechaFin)  -- incluir el día completo
      AND p.Estado        = 'Completado'
    GROUP BY pa.NombrePais, pa.CodigoPais;

END;
GO

EXEC SP_ConsultarVentasPorPais @CodigoPais = 'AR', @FechaInicio = '2024-01-01', @FechaFin = '2024-12-31';

EXEC SP_ConsultarVentasPorPais 'CL', '2024-01-01', '2024-12-31';

CREATE OR ALTER PROCEDURE SP_ConsultarVentasPorPais
   @CodigoPais   NVARCHAR(2)  = NULL,      -- NULL = todos los países
   @FechaInicio  DATE         = NULL,       -- NULL = sin límite inferior
   @FechaFin     DATE         = NULL        -- NULL = hoy
   AS
  BEGIN
    SET NOCOUNT ON;

    SET @FechaFin     = ISNULL(@FechaFin,     CAST(GETDATE() AS DATE));
    SET @FechaInicio  = ISNULL(@FechaInicio,  DATEADD(YEAR, -1, @FechaFin));

    SELECT
   pa.NombrePais,
   pa.CodigoPais,
   COUNT(p.PedidoID)    AS TotalPedidos,
   SUM(p.Total)         AS VentasTotales,
   AVG(p.Total)         AS TicketPromedio
    FROM Pedidos p
    INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
    INNER JOIN Paises pa  ON c.PaisID    = pa.PaisID
    WHERE (@CodigoPais IS NULL OR pa.CodigoPais = @CodigoPais)
      AND p.FechaPedido  >= @FechaInicio
      AND p.FechaPedido  <= DATEADD(DAY, 1, @FechaFin)
      AND p.Estado        = 'Completado'
    GROUP BY pa.NombrePais, pa.CodigoPais
    ORDER BY VentasTotales DESC;

END;
GO

EXEC SP_ConsultarVentasPorPais;
EXEC SP_ConsultarVentasPorPais @CodigoPais = 'MX';
EXEC SP_ConsultarVentasPorPais @FechaInicio = '2024-06-01', @FechaFin = '2024-12-31';

ALTER PROCEDURE SP_ConsultarVentasPorPais ...

CREATE OR ALTER PROCEDURE SP_ConsultarVentasPorPais ...

DROP PROCEDURE IF EXISTS SP_ConsultarVentasPorPais;

EXEC sp_helptext 'SP_ConsultarVentasPorPais';

GRANT EXECUTE ON SP_ConsultarVentasPorPais TO [Analista_Ventas];
