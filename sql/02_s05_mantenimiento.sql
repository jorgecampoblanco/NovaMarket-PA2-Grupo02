-- PA2 - NovaMarket | Mantenimiento controlado de datos
-- Responsable: Farid
-- Ejecutar despues de 00_esquema_y_datos_base.sql y 04_s07_datos_prueba.sql.
-- Ejecutar una vez en una base de prueba preparada para mostrar el ANTES y DESPUES.
-- IMPORTANTE: este archivo SI modifica datos (INSERT, UPDATE y DELETE).

USE PA2_NovaMarket;
GO

/* A. GUARDAR PEDIDOS CONFIRMADOS DE 2025 */

IF OBJECT_ID('dbo.PedidoHistorico2025', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PedidoHistorico2025 (
        PedidoID INT PRIMARY KEY,
        ClienteID INT,
        FechaPedido DATE,
        Estado VARCHAR(15),
        Canal VARCHAR(20)
    );
END;
GO

DECLARE @OrigenHistorico INT;
DECLARE @HistoricoAntes INT;
DECLARE @InsertadosPrimera INT;
DECLARE @HistoricoPrimera INT;
DECLARE @InsertadosSegunda INT;
DECLARE @HistoricoSegunda INT;

SELECT @OrigenHistorico = COUNT(*)
FROM dbo.Pedido
WHERE Estado = 'CONFIRMADO' AND FechaPedido < '20260101';

SELECT @HistoricoAntes = COUNT(*) FROM dbo.PedidoHistorico2025;

-- Primera carga: NOT EXISTS impide repetir los mismos PedidoID.
INSERT INTO dbo.PedidoHistorico2025 (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado, p.Canal
FROM dbo.Pedido AS p
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido < '20260101'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.PedidoHistorico2025 AS h
      WHERE h.PedidoID = p.PedidoID
  );
SET @InsertadosPrimera = @@ROWCOUNT;
SELECT @HistoricoPrimera = COUNT(*) FROM dbo.PedidoHistorico2025;

-- Segunda carga de comprobacion: no debe agregar pedidos nuevos.
INSERT INTO dbo.PedidoHistorico2025 (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado, p.Canal
FROM dbo.Pedido AS p
WHERE p.Estado = 'CONFIRMADO'
  AND p.FechaPedido < '20260101'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.PedidoHistorico2025 AS h
      WHERE h.PedidoID = p.PedidoID
  );
SET @InsertadosSegunda = @@ROWCOUNT;
SELECT @HistoricoSegunda = COUNT(*) FROM dbo.PedidoHistorico2025;

-- EVIDENCIA 1: origen, conteos antes/despues y segunda ejecucion sin duplicados.
SELECT @OrigenHistorico AS OrigenConfirmados2025,
       @HistoricoAntes AS HistoricoAntes,
       @InsertadosPrimera AS InsertadosPrimeraCarga,
       @HistoricoPrimera AS HistoricoDespuesPrimera,
       @InsertadosSegunda AS InsertadosSegundaCarga,
       @HistoricoSegunda AS HistoricoFinal,
       CASE WHEN @HistoricoSegunda = @OrigenHistorico
                     AND @InsertadosSegunda = 0
            THEN 'APROBADO' ELSE 'REVISAR' END AS Validacion;

SELECT PedidoID, ClienteID, FechaPedido, Estado, Canal
FROM dbo.PedidoHistorico2025
ORDER BY PedidoID;
GO

/* B. DESCUENTO SOLO A PRODUCTOS ACTIVOS DE REDES CON STOCK >= 10 */

IF OBJECT_ID('tempdb..#ProductosAntes') IS NOT NULL DROP TABLE #ProductosAntes;
SELECT p.ProductoID, p.PrecioLista, p.PrecioOferta,
       CASE WHEN c.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10
            THEN 1 ELSE 0 END AS AplicaDescuento
INTO #ProductosAntes
FROM dbo.Producto AS p
INNER JOIN dbo.Categoria AS c ON c.CategoriaID = p.CategoriaID;

-- Primera actualizacion: usa siempre PrecioLista, nunca PrecioOferta anterior.
UPDATE p
SET p.PrecioOferta = CAST(ROUND(p.PrecioLista * 0.90, 2) AS DECIMAL(10,2))
FROM dbo.Producto AS p
INNER JOIN dbo.Categoria AS c ON c.CategoriaID = p.CategoriaID
WHERE c.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10;

-- EVIDENCIA 2A: precios antes y despues, incluyendo productos fuera de alcance.
SELECT p.ProductoID, p.Nombre, c.Nombre AS Categoria,
       a.PrecioLista AS PrecioListaAntes, p.PrecioLista AS PrecioListaDespues,
       a.PrecioOferta AS OfertaAntes, p.PrecioOferta AS OfertaDespues,
       CASE
           WHEN a.AplicaDescuento = 1
                AND p.PrecioLista = a.PrecioLista
                AND p.PrecioOferta = CAST(ROUND(a.PrecioLista * 0.90, 2) AS DECIMAL(10,2))
                THEN 'DESCUENTO CORRECTO'
           WHEN a.AplicaDescuento = 0
                AND p.PrecioLista = a.PrecioLista
                AND ISNULL(p.PrecioOferta, -1) = ISNULL(a.PrecioOferta, -1)
                THEN 'SIN CAMBIOS'
           ELSE 'REVISAR'
       END AS Validacion
FROM dbo.Producto AS p
INNER JOIN dbo.Categoria AS c ON c.CategoriaID = p.CategoriaID
INNER JOIN #ProductosAntes AS a ON a.ProductoID = p.ProductoID
ORDER BY p.ProductoID;

-- Guardar el resultado de la primera actualizacion para comprobar la repeticion.
IF OBJECT_ID('tempdb..#ProductosPrimera') IS NOT NULL DROP TABLE #ProductosPrimera;
SELECT ProductoID, PrecioLista, PrecioOferta
INTO #ProductosPrimera
FROM dbo.Producto;

-- Repetir la actualizacion: debe dejar exactamente los mismos precios.
UPDATE p
SET p.PrecioOferta = CAST(ROUND(p.PrecioLista * 0.90, 2) AS DECIMAL(10,2))
FROM dbo.Producto AS p
INNER JOIN dbo.Categoria AS c ON c.CategoriaID = p.CategoriaID
WHERE c.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10;

-- EVIDENCIA 2B: el precio de lista no cambia; ninguna oferta cambia al repetir.
SELECT COUNT(*) AS ProductosRevisados,
       SUM(CASE WHEN a.AplicaDescuento = 1 THEN 1 ELSE 0 END) AS ProductosQueAplican,
       SUM(CASE WHEN a.AplicaDescuento = 0
                     AND (p.PrecioLista <> a.PrecioLista
                          OR ISNULL(p.PrecioOferta, -1) <> ISNULL(a.PrecioOferta, -1))
                THEN 1 ELSE 0 END) AS ProductosFueraDeAlcanceAlterados,
       SUM(CASE WHEN p.PrecioLista <> b.PrecioLista
                     OR ISNULL(p.PrecioOferta, -1) <> ISNULL(b.PrecioOferta, -1)
                THEN 1 ELSE 0 END) AS PreciosModificadosAlRepetir,
       CASE WHEN SUM(CASE WHEN a.AplicaDescuento = 0
                               AND (p.PrecioLista <> a.PrecioLista
                                    OR ISNULL(p.PrecioOferta, -1) <> ISNULL(a.PrecioOferta, -1))
                          THEN 1 ELSE 0 END) = 0
                      AND SUM(CASE WHEN p.PrecioLista <> b.PrecioLista
                                        OR ISNULL(p.PrecioOferta, -1) <> ISNULL(b.PrecioOferta, -1)
                                   THEN 1 ELSE 0 END) = 0
                THEN 'APROBADO' ELSE 'REVISAR' END AS Validacion
FROM dbo.Producto AS p
INNER JOIN #ProductosAntes AS a ON a.ProductoID = p.ProductoID
INNER JOIN #ProductosPrimera AS b ON b.ProductoID = p.ProductoID;

DROP TABLE #ProductosPrimera;
DROP TABLE #ProductosAntes;
GO

/* C. ELIMINAR SOLO BORRADORES SIN DETALLE */

IF OBJECT_ID('tempdb..#PedidosAntes') IS NOT NULL DROP TABLE #PedidosAntes;
SELECT p.PedidoID, p.Estado,
       CASE WHEN p.Estado = 'BORRADOR'
                     AND NOT EXISTS (SELECT 1 FROM dbo.DetallePedido AS d
                                     WHERE d.PedidoID = p.PedidoID)
            THEN 1 ELSE 0 END AS BorradorSinDetalle
INTO #PedidosAntes
FROM dbo.Pedido AS p;

DECLARE @DetallesAntes INT;
SELECT @DetallesAntes = COUNT(*) FROM dbo.DetallePedido;

-- EVIDENCIA 3A: identificadores de los borradores antes de eliminar.
SELECT a.PedidoID, a.Estado,
       CASE WHEN a.BorradorSinDetalle = 1 THEN 'SE ELIMINA'
            ELSE 'SE CONSERVA' END AS AccionEsperada
FROM #PedidosAntes AS a
WHERE a.Estado = 'BORRADOR' AND a.PedidoID IN (10, 32, 37, 33, 38)
ORDER BY a.PedidoID;

IF OBJECT_ID('tempdb..#BorradoresEliminados') IS NOT NULL DROP TABLE #BorradoresEliminados;
CREATE TABLE #BorradoresEliminados (PedidoID INT PRIMARY KEY);

DELETE p
OUTPUT deleted.PedidoID INTO #BorradoresEliminados (PedidoID)
FROM dbo.Pedido AS p
WHERE p.Estado = 'BORRADOR'
  AND NOT EXISTS (
      SELECT 1 FROM dbo.DetallePedido AS d WHERE d.PedidoID = p.PedidoID
  );

-- EVIDENCIA 3B: se muestra lo que se elimino y lo que se conservo.
SELECT a.PedidoID,
       CASE WHEN a.BorradorSinDetalle = 1 THEN 'DEBIA ELIMINARSE'
            ELSE 'DEBIA CONSERVARSE' END AS Esperado,
       CASE WHEN p.PedidoID IS NULL THEN 'ELIMINADO'
            ELSE 'CONSERVADO' END AS Obtenido
FROM #PedidosAntes AS a
LEFT JOIN dbo.Pedido AS p ON p.PedidoID = a.PedidoID
WHERE a.Estado = 'BORRADOR' AND a.PedidoID IN (10, 32, 37, 33, 38)
ORDER BY a.PedidoID;

-- EVIDENCIA 3C: ningun pedido ajeno al filtro fue eliminado ni modificado.
DECLARE @Inconsistencias INT;
SELECT @Inconsistencias = COUNT(*)
FROM #PedidosAntes AS a
LEFT JOIN dbo.Pedido AS p ON p.PedidoID = a.PedidoID
WHERE (a.BorradorSinDetalle = 1 AND p.PedidoID IS NOT NULL)
   OR (a.BorradorSinDetalle = 0 AND (p.PedidoID IS NULL OR p.Estado <> a.Estado));

SELECT (SELECT COUNT(*) FROM #PedidosAntes) AS PedidosAntes,
       (SELECT COUNT(*) FROM dbo.Pedido) AS PedidosDespues,
       (SELECT COUNT(*) FROM #PedidosAntes WHERE BorradorSinDetalle = 1) AS DebieronEliminarse,
       (SELECT COUNT(*) FROM #BorradoresEliminados) AS Eliminados,
       @Inconsistencias AS PedidosAjenosAfectados,
       @DetallesAntes AS DetallesAntes,
       (SELECT COUNT(*) FROM dbo.DetallePedido) AS DetallesDespues,
       CASE WHEN @Inconsistencias = 0
                     AND (SELECT COUNT(*) FROM #BorradoresEliminados) =
                         (SELECT COUNT(*) FROM #PedidosAntes WHERE BorradorSinDetalle = 1)
                     AND @DetallesAntes = (SELECT COUNT(*) FROM dbo.DetallePedido)
            THEN 'APROBADO' ELSE 'REVISAR' END AS Validacion;

DROP TABLE #BorradoresEliminados;
DROP TABLE #PedidosAntes;
GO
