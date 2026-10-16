-- NovaMarket: pruebas del reporte de ventas por cliente
-- Responsable: Jorge
-- Ejecutar despues de 05_S07_reporte_ventas_clientes.sql.
-- Solo realiza consultas; no modifica registros.

USE PA2_NovaMarket;
GO

IF OBJECT_ID('dbo.vw_ReporteClientes2026', 'V') IS NULL
    THROW 51000, 'Primero ejecute sql/05_S07_reporte_ventas_clientes.sql.', 1;
GO

-- Los valores esperados se obtienen de las tablas originales.
-- COUNT(DISTINCT) evita contar varias veces pedidos con mas de una linea.
DECLARE @Esperados TABLE (
    ClienteID INT PRIMARY KEY,
    TotalPedidos2026 INT,
    MontoVendido2026 DECIMAL(18,2)
);

INSERT INTO @Esperados (ClienteID, TotalPedidos2026, MontoVendido2026)
SELECT
    c.ClienteID,
    COUNT(DISTINCT p.PedidoID),
    CAST(COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS DECIMAL(18,2))
FROM dbo.Cliente AS c
LEFT JOIN dbo.Pedido AS p
    ON p.ClienteID = c.ClienteID
   AND p.Estado = 'CONFIRMADO'
   AND p.FechaPedido >= '20260101'
   AND p.FechaPedido < '20270101'
LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
WHERE c.ClienteID IN (1, 3, 5)
GROUP BY c.ClienteID;

-- Estos pedidos permiten verificar que el reporte no mezcle estados.
-- En el conjunto de datos actual: 41 = confirmado (5 lineas),
-- 42 = pendiente (848.80), 43 = anulado (998.80).
SELECT
    p.PedidoID,
    p.ClienteID,
    p.Estado,
    COUNT(d.DetalleID) AS Lineas,
    CAST(COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS DECIMAL(18,2)) AS MontoPedido
FROM dbo.Pedido AS p
LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
WHERE p.PedidoID IN (41, 42, 43)
GROUP BY p.PedidoID, p.ClienteID, p.Estado
ORDER BY p.PedidoID;

DECLARE @Casos TABLE (
    Numero INT,
    Caso NVARCHAR(100),
    ClienteID INT,
    PedidoEjemplo INT NULL,
    EscenarioExiste BIT
);

-- 1. Un pedido con varias lineas debe contar como un solo pedido.
INSERT INTO @Casos
SELECT 1, N'Pedido con varias lineas', 3, 41,
       CASE WHEN EXISTS (
           SELECT 1
           FROM dbo.Pedido AS p
           INNER JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
           WHERE p.PedidoID = 41 AND p.ClienteID = 3
             AND p.Estado = 'CONFIRMADO'
             AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
           GROUP BY p.PedidoID
           HAVING COUNT(*) > 1
       ) THEN 1 ELSE 0 END;

-- 2. Un cliente activo sin compras confirmadas debe aparecer con ceros.
INSERT INTO @Casos
SELECT 2, N'Cliente sin compras confirmadas', 5, NULL,
       CASE WHEN EXISTS (
           SELECT 1 FROM dbo.Cliente
           WHERE ClienteID = 5 AND Activo = 1
       ) AND NOT EXISTS (
           SELECT 1 FROM dbo.Pedido
           WHERE ClienteID = 5 AND Estado = 'CONFIRMADO'
             AND FechaPedido >= '20260101' AND FechaPedido < '20270101'
       ) THEN 1 ELSE 0 END;

-- 3. El pedido pendiente 42 no debe aumentar el reporte del cliente 1.
INSERT INTO @Casos
SELECT 3, N'Pedido pendiente excluido', 1, 42,
       CASE WHEN EXISTS (
           SELECT 1 FROM dbo.Pedido AS p
           INNER JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
           WHERE p.PedidoID = 42 AND p.ClienteID = 1
             AND p.Estado = 'PENDIENTE'
             AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
       ) THEN 1 ELSE 0 END;

-- 4. El pedido anulado 43 tampoco debe aumentar el reporte del cliente 1.
INSERT INTO @Casos
SELECT 4, N'Pedido anulado excluido', 1, 43,
       CASE WHEN EXISTS (
           SELECT 1 FROM dbo.Pedido AS p
           INNER JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
           WHERE p.PedidoID = 43 AND p.ClienteID = 1
             AND p.Estado = 'ANULADO'
             AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
       ) THEN 1 ELSE 0 END;

DECLARE @Resultados TABLE (
    Numero INT,
    Caso NVARCHAR(100),
    ClienteID INT,
    PedidoEjemplo INT NULL,
    PedidosEsperados INT,
    PedidosObtenidos INT NULL,
    MontoEsperado DECIMAL(18,2),
    MontoObtenido DECIMAL(18,2) NULL,
    Resultado VARCHAR(10)
);

INSERT INTO @Resultados
SELECT
    ca.Numero,
    ca.Caso,
    ca.ClienteID,
    ca.PedidoEjemplo,
    e.TotalPedidos2026,
    r.TotalPedidos2026,
    e.MontoVendido2026,
    r.MontoVendido2026,
    CASE WHEN ca.EscenarioExiste = 1
              AND r.ClienteID IS NOT NULL
              AND r.TotalPedidos2026 = e.TotalPedidos2026
              AND r.MontoVendido2026 = e.MontoVendido2026
         THEN 'APROBADO' ELSE 'FALLIDO' END
FROM @Casos AS ca
INNER JOIN @Esperados AS e ON e.ClienteID = ca.ClienteID
LEFT JOIN dbo.vw_ReporteClientes2026 AS r ON r.ClienteID = ca.ClienteID;

-- Matriz con valores esperados, valores obtenidos y conclusion.
SELECT
    Numero, Caso, ClienteID, PedidoEjemplo,
    PedidosEsperados, PedidosObtenidos,
    MontoEsperado, MontoObtenido,
    Resultado
FROM @Resultados
ORDER BY Numero;

IF EXISTS (SELECT 1 FROM @Resultados WHERE Resultado = 'FALLIDO')
    THROW 51001, 'Hay pruebas fallidas. Revise el reporte y los datos.', 1;
GO
