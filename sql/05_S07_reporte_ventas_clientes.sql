-- NovaMarket: reporte de ventas por cliente
-- Responsable: Jorge
-- Ejecutar despues del esquema y de la carga de datos de prueba.

USE PA2_NovaMarket;
GO

CREATE OR ALTER VIEW dbo.vw_ReporteClientes2026
AS
WITH TotalesPorPedido AS (
    -- Primero sumamos las lineas de cada pedido confirmado de 2026.
    SELECT
        p.PedidoID,
        p.ClienteID,
        COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS MontoPedido
    FROM dbo.Pedido AS p
    LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
    WHERE p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '20260101'
      AND p.FechaPedido < '20270101'
    GROUP BY p.PedidoID, p.ClienteID
)
SELECT
    c.ClienteID,
    c.Nombre,
    COUNT(t.PedidoID) AS TotalPedidos2026,
    CAST(COALESCE(SUM(t.MontoPedido), 0) AS DECIMAL(18,2)) AS MontoVendido2026
FROM dbo.Cliente AS c
LEFT JOIN TotalesPorPedido AS t ON t.ClienteID = c.ClienteID
WHERE c.Activo = 1
GROUP BY c.ClienteID, c.Nombre;
GO

-- Resultado final: todos los clientes activos, incluso si no compraron.
SELECT ClienteID, Nombre, TotalPedidos2026, MontoVendido2026
FROM dbo.vw_ReporteClientes2026
ORDER BY ClienteID;
GO
