

-- ACTIVIDAD 2: MANTENIMIENTO CONTROLADO DE DATOS (SESIÓN 05)
-- Proyecto: NovaMarket

USE PA2_NovaMarket;
GO

-- A. INSERT ... SELECT: Resguardo histórico de pedidos de 2025

-- 1. Crear la tabla histórica si no existe
IF OBJECT_ID('dbo.PedidoHistorico2025', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PedidoHistorico2025 (
        PedidoID    INT PRIMARY KEY,
        ClienteID   INT,
        FechaPedido DATE,
        Estado      VARCHAR(15),
        Canal       VARCHAR(20)
    );
    PRINT 'Tabla dbo.PedidoHistorico2025 creada exitosamente.';
END
GO

-- 2. Comprobación ANTES: Conteo de origen vs destino
SELECT 'Origen (Pedidos CONFIRMADO < 2026-01-01)' AS Metrica, COUNT(*) AS Cantidad 
FROM dbo.Pedido 
WHERE Estado = 'CONFIRMADO' AND FechaPedido < '2026-01-01';

SELECT 'Destino (PedidoHistorico2025 ANTES)' AS Metrica, COUNT(*) AS Cantidad 
FROM dbo.PedidoHistorico2025;

-- 3. Ejecución de la carga evitando duplicados mediante NOT EXISTS
INSERT INTO dbo.PedidoHistorico2025 (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado, p.Canal
 FROM dbo.Pedido p
WHERE p.Estado = 'CONFIRMADO' 
  AND p.FechaPedido < '2026-01-01'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.PedidoHistorico2025 h WHERE h.PedidoID = p.PedidoID
  );
  GO


-- 4. Comprobación DESPUÉS: Verificar concordancia y reejecución segura sin duplicados
SELECT 'Destino (PedidoHistorico2025 DESPUÉS)' AS Metrica, COUNT(*) AS Cantidad 
 FROM dbo.PedidoHistorico2025;
GO


-- B. UPDATE condicionado: Oferta para productos de Redes

-- 1. Comprobación ANTES: Ver productos de Redes activos con Stock >= 10
SELECT p.ProductoID, p.Nombre, c.Nombre AS Categoria, p.PrecioLista, p.PrecioOferta, p.Stock, p.Activo
FROM dbo.Producto p
JOIN dbo.Categoria c ON p.CategoriaID = c.CategoriaID
where c.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10;
go

-- 2. Ejecución del UPDATE (90% del PrecioLista, redondeado a dos decimales)
-- Nota: Al basarse estrictamente en PrecioLista, se evita el efecto de descuentos acumulativos al reejecutar.
UPDATE p
SET p.PrecioOferta = ROUND(p.PrecioLista * 0.90, 2)
from dbo.Producto p
JOIN dbo.Categoria c ON p.CategoriaID = c.CategoriaID
WHERE c.Nombre = 'Redes' 
  AND p.Activo = 1 
   and p.Stock >= 10;
   GO


-- 3. Comprobación DESPUÉS: Verificar cambios solo en el segmento solicitado
SELECT p.ProductoID, p.Nombre, c.Nombre AS Categoria, p.PrecioLista, p.PrecioOferta, p.Stock, p.Activo
FROM dbo.Producto p
JOIN dbo.Categoria c ON p.CategoriaID = c.CategoriaID
WHERE c.Nombre = 'Redes';
GO


-- C. DELETE protegido: Depuración de pedidos BORRADOR sin detalles

-- 1. Comprobación ANTES: Conteo por estado y listado exacto de borradores vacíos
SELECT Estado, COUNT(*) AS TotalPorEstado 
FROM dbo.Pedido 
GROUP BY Estado;

SELECT p.PedidoID, p.Estado, p.FechaPedido
FROM dbo.Pedido p
WHERE p.Estado = 'BORRADOR'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID = p.PedidoID
  );
  GO
-- 2. Ejecución del DELETE exclusivo para borradores sin detalle
DELETE FROM p
FROM dbo.Pedido p
WHERE p.Estado = 'BORRADOR'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID = p.PedidoID
  );
  GO

-- 3. Comprobación DESPUÉS: Demostrar que los pedidos CONFIRMADO y borradores con detalle permanecen intactos
SELECT Estado, COUNT(*) AS TotalPorEstado 
FROM dbo.Pedido 
GROUP BY Estado;
GO