USE TiendaLatam;
GO

SELECT
   s.SucursalID,
   s.NombreSucursal,
   s.Ciudad,
   COUNT(p.PedidoID) AS TotalPedidos
FROM Pedidos p
RIGHT JOIN Sucursales s ON p.SucursalID = s.SucursalID
GROUP BY s.SucursalID, s.NombreSucursal, s.Ciudad
ORDER BY TotalPedidos ASC;

-- ¿Cuándo usar RIGHT JOIN en lugar de LEFT JOIN?
-- La convención es poner la tabla "principal" a la izquierda y usar LEFT JOIN.
-- Si te encuentras escribiendo un RIGHT JOIN, normalmente es más claro cambiar el orden de las tablas y usar LEFT JOIN.

SELECT
   p.PaisID,
   p.NombrePais,
   c.ClienteID,
   c.Nombre  AS NombreCliente
FROM Paises p
FULL OUTER JOIN Clientes c ON p.PaisID = c.PaisID
WHERE p.PaisID IS NULL OR c.PaisID IS NULL
ORDER BY p.NombrePais, c.Nombre;

-- FULL OUTER JOIN es la herramienta de auditoría de datos por excelencia.

SELECT
   cat.NombreCategoria,
   p.NombrePais
FROM Categorias cat
  CROSS JOIN Paises p
ORDER BY cat.NombreCategoria, p.NombrePais;

-- El riesgo del CROSS JOIN: si las tablas son grandes, el resultado puede ser enorme.
-- Siempre calcular el tamaño esperado antes de ejecutar.

SELECT
   p.NombrePais,
   cat.NombreCategoria,
   COUNT(dp.DetallePedidoID) AS TotalVentas
FROM Paises p
  CROSS JOIN Categorias cat
LEFT JOIN Clientes c       ON c.PaisID = p.PaisID
LEFT JOIN Pedidos ped      ON ped.ClienteID = c.ClienteID
LEFT JOIN DetallePedidos dp ON dp.PedidoID = ped.PedidoID
LEFT JOIN Productos prod   ON prod.ProductoID = dp.ProductoID
                          AND prod.CategoriaID = cat.CategoriaID
GROUP BY p.NombrePais, cat.NombreCategoria
HAVING COUNT(dp.DetallePedidoID) = 0
ORDER BY p.NombrePais, cat.NombreCategoria;
