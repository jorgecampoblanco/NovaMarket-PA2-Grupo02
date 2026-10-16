USE PA2_NovaMarket;
GO
 
/* -----------------------------------------------------
   VISTA 1: ventas confirmadas por año, mes y categoría
   ----------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vw_VentasCategoriaMes
AS
SELECT
    YEAR(p.FechaPedido)                       AS Anio,
    MONTH(p.FechaPedido)                      AS Mes,
    c.CategoriaID,
    c.Nombre                                  AS Categoria,
    COUNT(DISTINCT p.PedidoID)                AS NumPedidos,
    SUM(d.Cantidad)                           AS CantidadVendida,
    SUM(d.Cantidad * d.PrecioUnitario)        AS ImporteVendido
FROM dbo.Pedido        AS p
JOIN dbo.DetallePedido AS d ON d.PedidoID    = p.PedidoID
JOIN dbo.Producto      AS pr ON pr.ProductoID = d.ProductoID
JOIN dbo.Categoria     AS c  ON c.CategoriaID = pr.CategoriaID
WHERE p.Estado = 'CONFIRMADO'
GROUP BY YEAR(p.FechaPedido), MONTH(p.FechaPedido), c.CategoriaID, c.Nombre;
GO