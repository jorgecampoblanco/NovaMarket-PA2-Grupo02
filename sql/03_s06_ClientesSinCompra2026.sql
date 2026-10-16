USE PA2_NovaMarket;
GO

/* -----------------------------------------------------
   VISTA 2: clientes sin pedidos CONFIRMADOS en 2026
   (pueden tener pedidos en otros estados u otros años)
   ----------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_ClientesSinCompra2026
AS
SELECT
    cl.ClienteID,
    cl.Documento,
    cl.Nombre,
    cl.Ciudad,
    cl.Activo,
    (SELECT COUNT(*)
       FROM dbo.Pedido AS x
      WHERE x.ClienteID = cl.ClienteID
        AND x.FechaPedido >= '20260101' AND x.FechaPedido < '20270101') AS PedidosNoConfirmados2026
FROM dbo.Cliente AS cl
WHERE NOT EXISTS (
        SELECT 1
          FROM dbo.Pedido AS p
         WHERE p.ClienteID   = cl.ClienteID
           AND p.Estado      = 'CONFIRMADO'
           AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101');
GO