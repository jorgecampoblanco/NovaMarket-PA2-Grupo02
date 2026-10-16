USE PA2_NovaMarket;
GO

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

/* -----  CONSULTA DE LAS VISTAS  ----- */

-- Ventas de 2026, ordenadas por mes y monto
SELECT *
FROM dbo.vw_VentasCategoriaMes
WHERE Anio = 2026
ORDER BY Mes, MontoTotal DESC;

-- Clientes sin compras confirmadas en 2026
SELECT *
FROM dbo.vw_ClientesSinCompra2026
ORDER BY ClienteID;
GO

/* ==========  VERIFICACION 1: TOTALES MENSUALES (VISTA vs TABLAS)  ==========
   Enero 2026   esperado: 29 unidades, S/ 7,035.40
   Febrero 2026 esperado: 35 unidades, S/ 8,591.20                           */

-- 1a) Totales mensuales desde la vista
SELECT Anio, Mes,
       SUM(TotalUnidades) AS Unidades,
       SUM(MontoTotal)    AS Monto
FROM dbo.vw_VentasCategoriaMes
WHERE Anio = 2026 AND Mes IN (1, 2)
GROUP BY Anio, Mes
ORDER BY Mes;

-- 1b) Enero 2026 en las tablas originales: detalle línea por línea
SELECT p.PedidoID, p.FechaPedido, d.ProductoID, d.Cantidad, d.PrecioUnitario,
       d.Cantidad * d.PrecioUnitario AS Importe
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20260201'
ORDER BY p.PedidoID, d.DetalleID;

-- 1c) Febrero 2026 en las tablas originales: detalle línea por línea
SELECT p.PedidoID, p.FechaPedido, d.ProductoID, d.Cantidad, d.PrecioUnitario,
       d.Cantidad * d.PrecioUnitario AS Importe
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido >= '20260201' AND p.FechaPedido < '20260301'
ORDER BY p.PedidoID, d.DetalleID;

-- 1d) Contraste final: vista vs tablas originales vs valor esperado
SELECT
    v.Mes,
    v.Unidades  AS Unidades_Vista,
    o.Unidades  AS Unidades_Original,
    e.Unidades  AS Unidades_Esperado,
    v.Monto     AS Monto_Vista,
    o.Monto     AS Monto_Original,
    e.Monto     AS Monto_Esperado,
    CASE WHEN v.Unidades = o.Unidades AND v.Monto = o.Monto
          AND o.Unidades = e.Unidades AND o.Monto = e.Monto
         THEN 'COINCIDE' ELSE 'REVISAR' END AS Resultado
FROM (SELECT Mes, SUM(TotalUnidades) AS Unidades, SUM(MontoTotal) AS Monto
        FROM dbo.vw_VentasCategoriaMes
       WHERE Anio = 2026 AND Mes IN (1, 2)
       GROUP BY Mes) AS v
JOIN (SELECT MONTH(p.FechaPedido) AS Mes,
             SUM(d.Cantidad) AS Unidades,
             SUM(d.Cantidad * d.PrecioUnitario) AS Monto
        FROM dbo.Pedido p
        JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
       WHERE p.Estado = 'CONFIRMADO'
         AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20260301'
       GROUP BY MONTH(p.FechaPedido)) AS o ON o.Mes = v.Mes
JOIN (VALUES (1, 29, CAST(7035.40 AS DECIMAL(12,2))),
             (2, 35, CAST(8591.20 AS DECIMAL(12,2)))) AS e(Mes, Unidades, Monto)
     ON e.Mes = v.Mes
ORDER BY v.Mes;
GO

/* ====  VERIFICACION 2: CLIENTES SIN COMPRA 2026 (VISTA vs TABLAS)  ==== */

-- 2a) Consulta independiente sobre Cliente y Pedido (LEFT JOIN con el filtro en el ON)
SELECT cl.ClienteID, cl.Nombre, cl.Ciudad
FROM dbo.Cliente AS cl
LEFT JOIN dbo.Pedido AS p
       ON p.ClienteID   = cl.ClienteID
      AND p.Estado      = 'CONFIRMADO'
      AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
WHERE p.PedidoID IS NULL
ORDER BY cl.ClienteID;

-- 2b) Diferencias en ambos sentidos: si no devuelve filas, los resultados son idénticos
SELECT 'Solo en la vista' AS Origen, ClienteID, Nombre, Ciudad
FROM (SELECT ClienteID, Nombre, Ciudad FROM dbo.vw_ClientesSinCompra2026
      EXCEPT
      SELECT cl.ClienteID, cl.Nombre, cl.Ciudad
      FROM dbo.Cliente cl
      LEFT JOIN dbo.Pedido p
             ON p.ClienteID = cl.ClienteID AND p.Estado = 'CONFIRMADO'
            AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
      WHERE p.PedidoID IS NULL) AS a
UNION ALL
SELECT 'Solo en tablas originales', ClienteID, Nombre, Ciudad
FROM (SELECT cl.ClienteID, cl.Nombre, cl.Ciudad
      FROM dbo.Cliente cl
      LEFT JOIN dbo.Pedido p
             ON p.ClienteID = cl.ClienteID AND p.Estado = 'CONFIRMADO'
            AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
      WHERE p.PedidoID IS NULL
      EXCEPT
      SELECT ClienteID, Nombre, Ciudad FROM dbo.vw_ClientesSinCompra2026) AS b;

-- 2c) Conteo de ambos métodos
SELECT
    (SELECT COUNT(*) FROM dbo.vw_ClientesSinCompra2026) AS Clientes_Vista,
    (SELECT COUNT(*)
       FROM dbo.Cliente cl
       LEFT JOIN dbo.Pedido p
              ON p.ClienteID = cl.ClienteID AND p.Estado = 'CONFIRMADO'
             AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
      WHERE p.PedidoID IS NULL) AS Clientes_Tablas_Originales;
GO