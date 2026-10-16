
-- ACTIVIDAD 2: MANTENIMIENTO CONTROLADO DE DATOS (SESIÓN 05)
-- Proyecto: NovaMarket

USE PA2_NovaMarket;
go

-- A. INSERT  SELECT: Resguardo histórico de pedidos de 2025



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
end
go

-- 2. Comprobación ANTES: Conteo de origen vs destino
SELECT 'Origen (Pedidos CONFIRMADO < 2026-01-01)' AS Metrica, COUNT(*) AS Cantidad 
FROM dbo.Pedido 
WHERE Estado = 'CONFIRMADO' AND FechaPedido < '2026-01-01';

select 'Destino (PedidoHistorico2025 ANTES)' AS Metrica, COUNT(*) AS Cantidad 
FROM dbo.PedidoHistorico2025;

-- 3. Ejecución de la carga inicial
INSERT INTO dbo.PedidoHistorico2025 (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado, p.Canal
FROM dbo.Pedido p
WHERE p.Estado = 'CONFIRMADO' 
  AND p.FechaPedido < '2026-01-01'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.PedidoHistorico2025 h WHERE h.PedidoID = p.PedidoID
  );

-- 4. Comprobación DESPUÉS de la primera carga
SELECT 'Destino (PedidoHistorico2025 DESPUES 1ra Carga)' AS Metrica, COUNT(*) AS Cantidad 
FROM dbo.PedidoHistorico2025;


-- B. UPDATE condicionado: Oferta para productos de Redes

-- 1. Comprobación ANTES: Ver el estado general de los productos (todas las categorías)
SELECT p.ProductoID, p.Nombre, c.Nombre AS Categoria, p.PrecioLista, p.PrecioOferta, p.Stock, p.Activo
FROM dbo.Producto p
JOIN dbo.Categoria c ON p.CategoriaID = c.CategoriaID;

-- 2. Ejecución del UPDATE (90% del PrecioLista en Redes activos con Stock >= 10)[cite: 3, 10]
update p
set p.PrecioOferta = round(p.PrecioLista * 0.90, 2)
FROM dbo.Producto p
JOIN dbo.Categoria c ON p.CategoriaID = c.CategoriaID
WHERE c.Nombre = 'Redes' 
  AND p.Activo = 1 
  AND p.Stock >= 10;

-- 3. VALIDACIÓN EXTRA: Comprobar globalmente que los demás productos conservaron sus precios (PrecioOferta NULL o sin cambios)
SELECT p.ProductoID, p.Nombre, c.Nombre AS Categoria, p.PrecioLista, p.PrecioOferta, p.Stock, p.Activo,
       CASE 
           WHEN c.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10 THEN 'ACTUALIZADO (Con Oferta)'
           ELSE 'CONSERVADO INTACTO (Fuera de alcance)' 
       END AS EstadoValidacion
FROM dbo.Producto p
JOIN dbo.Categoria c ON p.CategoriaID = c.CategoriaID;
GO

-- C. DELETE protegido: Depuración de pedidos BORRADOR sin detalles

-- 1. Mostrar cuáles son los borradores que SE VAN A ELIMINAR (los 3 sin detalle) y cuáles PERMANECEN (con detalles)
SELECT p.PedidoID, p.Estado, 'SERA ELIMINADO (Borrador sin detalles)' AS DetalleAnalisis
FROM dbo.Pedido p
WHERE p.Estado = 'BORRADOR'
  AND NOT EXISTS (SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID = p.PedidoID)

UNION ALL

SELECT p.PedidoID, p.Estado, 'PERMANECE INTACTO (Borrador CON detalles)' AS DetalleAnalisis
FROM dbo.Pedido p
WHERE p.Estado = 'BORRADOR'
  AND EXISTS (SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID = p.PedidoID);

-- 2. Ejecución del DELETE exclusivo para borradores sin detalle
DELETE FROM p
FROM dbo.Pedido p
WHERE p.Estado = 'BORRADOR'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.DetallePedido d WHERE d.PedidoID = p.PedidoID
  );
  go


-- 3. Comprobación DESPUÉS: Demostrar conteos finales por estado y asegurar que los borradores con detalle y los confirmados siguen intactos[cite: 3, 10]
select Estado, COUNT(*) AS TotalPorEstadoDespues 
FROM dbo.Pedido 
GROUP BY Estado;
GO

