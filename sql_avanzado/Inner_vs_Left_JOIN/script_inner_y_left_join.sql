USE TiendaLatam;
GO

-- El gerente de ventas pide: "dame el total de ventas de todos nuestros clientes".
-- ¿Qué escribe el analista?

SELECT
-- c.ClienteID,
-- c.Nombre,
-- SUM(p.Total) AS TotalCompras
FROM Clientes c
INNER JOIN Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY c.ClienteID, c.Nombre
ORDER BY TotalCompras DESC;

-- Parece correcto. Pero hay clientes que nunca hicieron un pedido.
-- Con INNER JOIN, esos clientes no aparecen en el resultado.
-- El gerente cree que está viendo "todos los clientes". En realidad está viendo solo los que tienen pedidos.
-- Este es un error de interpretación — no de sintaxis. Y es el más peligroso.

-- Cuando la pregunta es "todos los clientes, con o sin pedidos":

SELECT
-- c.ClienteID,
-- c.Nombre,
-- ISNULL(SUM(p.Total), 0) AS TotalCompras,
-- COUNT(p.PedidoID)        AS CantidadPedidos
FROM Clientes c
LEFT JOIN Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY c.ClienteID, c.Nombre
ORDER BY TotalCompras DESC;

-- Dos diferencias clave:
-- Primero: LEFT JOIN en lugar de INNER JOIN.
-- Segundo: ISNULL(SUM(p.Total), 0) — porque cuando no hay pedidos, SUM devuelve NULL, no cero.
-- Ahora el gerente ve todos los clientes, incluidos los que tienen TotalCompras = 0.
-- Esos son clientes que se registraron pero nunca compraron — una información de negocio valiosa.

LEFT JOIN tiene un uso especial muy poderoso: encontrar filas que NO tienen par.
-- ¿Qué clientes de TiendaLatam NUNCA hicieron un pedido?

SELECT
-- c.ClienteID,
-- c.Nombre,
-- c.Email,
-- c.FechaRegistro
FROM Clientes c
LEFT JOIN Pedidos p ON c.ClienteID = p.ClienteID
WHERE p.PedidoID IS NULL
ORDER BY c.FechaRegistro DESC;

-- La clave: filtramos WHERE p.PedidoID IS NULL.
-- Si el pedido es NULL después del LEFT JOIN, significa que ese cliente no tiene ningún pedido.
-- Este patrón — LEFT JOIN + WHERE columna_derecha IS NULL — es uno de los más útiles en análisis de datos.
-- Lo vamos a ver de nuevo en distintos contextos a lo largo del curso.

