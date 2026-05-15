USE TiendaLatam;
GO

SELECT
    c.Nombre,
    p.Total,
    p.FechaPedido
FROM Clientes c
INNER JOIN Pedidos p ON c.ClienteID = p.ClienteID
WHERE p.Total > (
    SELECT AVG(Total)
    FROM Pedidos
    WHERE Estado = 'Completado'
)
ORDER BY p.Total DESC;

SELECT
    ProductoID,
    NombreProducto,
    Precio,
    Stock
FROM Productos
WHERE ProductoID IN (
    SELECT DISTINCT dp.ProductoID
    FROM DetallePedidos dp
    INNER JOIN Pedidos p    ON dp.PedidoID = p.PedidoID
    INNER JOIN Clientes c   ON p.ClienteID = c.ClienteID
    INNER JOIN Paises pa    ON c.PaisID    = pa.PaisID
    WHERE pa.CodigoPais = 'AR'
)
ORDER BY NombreProducto;

SELECT ProductoID, NombreProducto, Stock
FROM Productos
WHERE ProductoID NOT IN (
    SELECT DISTINCT ProductoID
    FROM DetallePedidos
    WHERE ProductoID IS NOT NULL  -- ← CRÍTICO: si la subquery devuelve un NULL, NOT IN devuelve cero filas
)
ORDER BY NombreProducto;

SELECT c.ClienteID, c.Nombre, c.Email
FROM Clientes c
WHERE EXISTS (
    SELECT 1
    FROM Pedidos p
    WHERE p.ClienteID = c.ClienteID   -- ← referencia a la query exterior
      AND p.Total > 500
      AND p.Estado = 'Completado'
)
ORDER BY c.Nombre;
