-- Reporte de clientes - NovaMarket (2026)
-- Muestra pedidos confirmados y monto vendido en 2026 por cliente activo.
-- Los clientes sin compras validas tambien aparecen con valores en cero.
-- La vista permite consultar este reporte en las pruebas.

USE PA2_NovaMarket;
GO

CREATE OR ALTER VIEW dbo.vw_ReporteClientes2026
AS
WITH PedidosValidos AS (
    -- Pedidos confirmados en el 2026.
    SELECT p.PedidoID, p.ClienteID
    FROM dbo.Pedido AS p
    WHERE p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '20260101'
      AND p.FechaPedido <  '20270101'
),
TotalesPorPedido AS (
    -- Calculamos el importe de cada pedido para no contarlo varias veces
    -- cuando tiene mas de un producto.
    SELECT
        p.PedidoID,
        p.ClienteID,
        COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS TotalPedido
    FROM PedidosValidos AS p
    LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
    GROUP BY p.PedidoID, p.ClienteID
)
SELECT
    c.ClienteID,
    c.Documento,
    c.Nombre,
    c.Ciudad,
    COUNT(t.PedidoID) AS PedidosConfirmados2026,
    CAST(COALESCE(SUM(t.TotalPedido), 0) AS DECIMAL(18,2)) AS MontoVendido2026
FROM dbo.Cliente AS c
LEFT JOIN TotalesPorPedido AS t ON t.ClienteID = c.ClienteID
WHERE c.Activo = 1
GROUP BY c.ClienteID, c.Documento, c.Nombre, c.Ciudad;
GO

-- Consultamos el reporte ordenado por monto vendido.
SELECT
    ClienteID,
    Documento,
    Nombre,
    Ciudad,
    PedidosConfirmados2026,
    MontoVendido2026
FROM dbo.vw_ReporteClientes2026
ORDER BY MontoVendido2026 DESC, ClienteID;
GO
