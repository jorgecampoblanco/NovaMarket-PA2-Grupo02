USE PA2_NovaMarket;
GO

/* ---------  VISTAS  --------- */
 
-- VISTA 1: ventas confirmadas por año, mes y categoría
CREATE OR ALTER VIEW dbo.vw_VentasCategoriaMes
AS
SELECT
    YEAR(p.FechaPedido)                  AS Anio,
    MONTH(p.FechaPedido)                 AS Mes,
    c.CategoriaID,
    c.Nombre                             AS NombreCategoria,
    SUM(d.Cantidad)                      AS TotalUnidades,
    SUM(d.Cantidad * d.PrecioUnitario)   AS MontoTotal
FROM dbo.Pedido        AS p
JOIN dbo.DetallePedido AS d  ON d.PedidoID    = p.PedidoID
JOIN dbo.Producto      AS pr ON pr.ProductoID = d.ProductoID
JOIN dbo.Categoria     AS c  ON c.CategoriaID = pr.CategoriaID
WHERE p.Estado = 'CONFIRMADO'
GROUP BY YEAR(p.FechaPedido), MONTH(p.FechaPedido), c.CategoriaID, c.Nombre;
GO
 
-- VISTA 2: clientes sin pedidos CONFIRMADOS en 2026
-- (pueden tener pedidos en otros estados u otros años)
CREATE OR ALTER VIEW dbo.vw_ClientesSinCompra2026
AS
SELECT
    cl.ClienteID,
    cl.Nombre,
    cl.Ciudad
FROM dbo.Cliente AS cl
WHERE NOT EXISTS (
        SELECT 1
          FROM dbo.Pedido AS p
         WHERE p.ClienteID   = cl.ClienteID
           AND p.Estado      = 'CONFIRMADO'
           AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101');
GO
 
/* --------  CONSULTA DE LAS VISTAS  -------- */
 
SELECT * FROM dbo.vw_VentasCategoriaMes
ORDER BY Anio, Mes, NombreCategoria;
 
SELECT * FROM dbo.vw_ClientesSinCompra2026
ORDER BY ClienteID;
GO
 
/* --------  VERIFICACION CONTRA REGISTROS ORIGINALES  -------- */
 
-- Total mensual desde la vista
SELECT Anio, Mes,
       SUM(TotalUnidades) AS Unidades,
       SUM(MontoTotal)    AS Monto
FROM dbo.vw_VentasCategoriaMes
GROUP BY Anio, Mes
ORDER BY Anio, Mes;
 
-- Enero 2026 en tablas originales (esperado: 12 unidades, 2376.10)
SELECT p.PedidoID, p.FechaPedido, d.ProductoID, d.Cantidad, d.PrecioUnitario,
       d.Cantidad * d.PrecioUnitario AS Importe
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20260201'
ORDER BY p.PedidoID;
 
SELECT SUM(d.Cantidad) AS Unidades, SUM(d.Cantidad * d.PrecioUnitario) AS Monto
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20260201';
 
-- Diciembre 2025 en tablas originales (esperado: 5 unidades, 1005.67)
SELECT SUM(d.Cantidad) AS Unidades, SUM(d.Cantidad * d.PrecioUnitario) AS Monto
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido >= '20251201' AND p.FechaPedido < '20260101';
GO