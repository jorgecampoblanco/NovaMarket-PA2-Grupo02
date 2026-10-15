-- Pruebas del reporte de clientes - NovaMarket
-- Ejecutar despues de ReporteClientes.sql.
-- Las pruebas solo consultan; no modifican registros.

USE PA2_NovaMarket;
GO

IF OBJECT_ID('dbo.vw_ReporteClientes2026', 'V') IS NULL
    THROW 51000, 'Ejecute primero sql/ReporteClientes.sql.', 1;
GO

DECLARE @Resultados TABLE (
    Numero INT,
    Caso NVARCHAR(100),
    Resultado VARCHAR(10)
);

-- Prueba 1. Cliente 5: activo, sin pedidos. Debe salir con 0 y 0.00.
INSERT INTO @Resultados (Numero, Caso, Resultado)
SELECT 1, N'Cliente sin pedidos (ID 5)',
       CASE WHEN EXISTS (
                 SELECT 1 FROM dbo.Cliente
                 WHERE ClienteID = 5 AND Activo = 1
             )
             AND NOT EXISTS (
                 SELECT 1 FROM dbo.Pedido WHERE ClienteID = 5
             )
             AND EXISTS (
                 SELECT 1 FROM dbo.vw_ReporteClientes2026
                 WHERE ClienteID = 5
                   AND PedidosConfirmados2026 = 0
                   AND MontoVendido2026 = 0
             )
            THEN 'APROBADO' ELSE 'FALLIDO' END;

-- Prueba 2. Cliente 6: solo PENDIENTE/ANULADO. No son ventas validas.
INSERT INTO @Resultados (Numero, Caso, Resultado)
SELECT 2, N'Pedidos no confirmados (ID 6)',
       CASE WHEN EXISTS (
                 SELECT 1 FROM dbo.Pedido
                 WHERE ClienteID = 6 AND Estado IN ('PENDIENTE', 'ANULADO')
             )
             AND NOT EXISTS (
                 SELECT 1 FROM dbo.Pedido
                 WHERE ClienteID = 6 AND Estado = 'CONFIRMADO'
                   AND FechaPedido >= '20260101' AND FechaPedido < '20270101'
             )
             AND EXISTS (
                 SELECT 1 FROM dbo.vw_ReporteClientes2026
                 WHERE ClienteID = 6
                   AND PedidosConfirmados2026 = 0
                   AND MontoVendido2026 = 0
             )
            THEN 'APROBADO' ELSE 'FALLIDO' END;

-- Prueba 3. Cliente 7: varios pedidos y detalles.
-- Se calculan las cifras esperadas desde Pedido y DetallePedido.
-- Esta prueba tambien sirve si agregan mas pedidos al cliente.
DECLARE @PedidosEsperados7 INT;
DECLARE @MontoEsperado7 DECIMAL(18,2);

SELECT @PedidosEsperados7 = COUNT(*)
FROM dbo.Pedido
WHERE ClienteID = 7 AND Estado = 'CONFIRMADO'
  AND FechaPedido >= '20260101' AND FechaPedido < '20270101';

SELECT @MontoEsperado7 = CAST(COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS DECIMAL(18,2))
FROM dbo.Pedido AS p
INNER JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
WHERE p.ClienteID = 7 AND p.Estado = 'CONFIRMADO'
  AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101';

INSERT INTO @Resultados (Numero, Caso, Resultado)
SELECT 3, N'Varios pedidos y detalles (ID 7)',
       CASE WHEN @PedidosEsperados7 >= 2
             AND EXISTS (
                 SELECT 1 FROM dbo.Pedido AS p
                 JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
                 WHERE p.ClienteID = 7 AND p.Estado = 'CONFIRMADO'
                   AND p.FechaPedido >= '20260101' AND p.FechaPedido < '20270101'
                 GROUP BY p.ClienteID
                 HAVING COUNT(*) > COUNT(DISTINCT p.PedidoID)
             )
             AND EXISTS (
                 SELECT 1 FROM dbo.vw_ReporteClientes2026
                 WHERE ClienteID = 7
                   AND PedidosConfirmados2026 = @PedidosEsperados7
                   AND MontoVendido2026 = @MontoEsperado7
             )
            THEN 'APROBADO' ELSE 'FALLIDO' END;

-- Prueba 4. Cliente 12: inactivo. No debe aparecer aunque haya comprado.
INSERT INTO @Resultados (Numero, Caso, Resultado)
SELECT 4, N'Cliente inactivo excluido (ID 12)',
       CASE WHEN EXISTS (
                 SELECT 1 FROM dbo.Cliente
                 WHERE ClienteID = 12 AND Activo = 0
             )
             AND EXISTS (
                 SELECT 1 FROM dbo.Pedido
                 WHERE ClienteID = 12 AND Estado = 'CONFIRMADO'
             )
             AND NOT EXISTS (
                 SELECT 1 FROM dbo.vw_ReporteClientes2026
                 WHERE ClienteID = 12
             )
            THEN 'APROBADO' ELSE 'FALLIDO' END;

-- Resumen de los cuatro casos: guardar captura como evidencia.
SELECT Numero, Caso, Resultado
FROM @Resultados
ORDER BY Numero;

-- Resultados concretos de los clientes evaluados (el 12 no aparecera).
SELECT ClienteID, Nombre, PedidosConfirmados2026, MontoVendido2026
FROM dbo.vw_ReporteClientes2026
WHERE ClienteID IN (5, 6, 7, 12)
ORDER BY ClienteID;

IF EXISTS (SELECT 1 FROM @Resultados WHERE Resultado = 'FALLIDO')
    THROW 51001, 'Hay pruebas fallidas. Revise los casos y el reporte.', 1;
GO
