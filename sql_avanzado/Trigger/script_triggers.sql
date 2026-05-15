USE TiendaLatam;
GO

CREATE TABLE AuditoriaPedidos (
-- AuditoriaID   INT IDENTITY(1,1) PRIMARY KEY,
-- PedidoID      INT NOT NULL,
-- Accion        NVARCHAR(10) NOT NULL,       -- INSERT, UPDATE, DELETE
-- EstadoAntes   NVARCHAR(50) NULL,
-- EstadoDespues NVARCHAR(50) NULL,
-- TotalAntes    DECIMAL(10,2) NULL,
-- TotalDespues  DECIMAL(10,2) NULL,
-- Usuario       NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
-- FechaHora     DATETIME NOT NULL DEFAULT GETDATE()
);
GO

CREATE TRIGGER TR_Pedidos_Auditoria
ON Pedidos
-- AFTER INSERT, UPDATE, DELETE
-- AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditoriaPedidos (PedidoID, Accion, EstadoAntes, EstadoDespues, TotalAntes, TotalDespues)
    SELECT
        ISNULL(i.PedidoID, d.PedidoID),
        CASE
        WHEN EXISTS (SELECT 1 FROM INSERTED)  AND NOT EXISTS (SELECT 1 FROM DELETED)  THEN 'INSERT'
        WHEN EXISTS (SELECT 1 FROM INSERTED)  AND EXISTS (SELECT 1 FROM DELETED)       THEN 'UPDATE'
        WHEN NOT EXISTS (SELECT 1 FROM INSERTED) AND EXISTS (SELECT 1 FROM DELETED)    THEN 'DELETE'
        END,
        d.Estado,
        i.Estado,
        d.Total,
        i.Total
    FROM INSERTED i
    FULL OUTER JOIN DELETED d ON i.PedidoID = d.PedidoID;
END;
GO

UPDATE Pedidos SET Estado = 'Cancelado' WHERE PedidoID = 1;
SELECT * FROM AuditoriaPedidos;

CREATE TRIGGER TR_VW_VentasPorPais_InsteadOfInsert
ON VW_VentasPorPais
-- INSTEAD OF INSERT
-- AS
BEGIN
    SET NOCOUNT ON;
    RAISERROR('Esta vista es de solo lectura. Use las tablas base directamente.', 16, 1);
END;
GO
