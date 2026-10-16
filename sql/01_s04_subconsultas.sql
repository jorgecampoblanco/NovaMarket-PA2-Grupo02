USE PA2_NovaMarket;
GO

/* ============================================================
A. Segmentacion: Redes CONFIRMADO 2026 y SIN Seguridad CONFIRMADO 2026
   EXISTS / NOT EXISTS
============================================================ */
SELECT
    c.ClienteID,
    c.Nombre,
    c.Ciudad
FROM dbo.Cliente AS c
WHERE EXISTS (
    SELECT 1
    FROM dbo.Pedido AS pe
    INNER JOIN dbo.DetallePedido AS dp
        ON dp.PedidoID = pe.PedidoID
    INNER JOIN dbo.Producto AS pr
        ON pr.ProductoID = dp.ProductoID
    INNER JOIN dbo.Categoria AS ca
        ON ca.CategoriaID = pr.CategoriaID
    WHERE pe.ClienteID = c.ClienteID
      AND pe.Estado = 'CONFIRMADO'
      AND pe.FechaPedido >= '20260101'
      AND pe.FechaPedido <  '20270101'
      AND ca.Nombre = 'Redes'
)
AND NOT EXISTS (
    SELECT 1
    FROM dbo.Pedido AS pe
    INNER JOIN dbo.DetallePedido AS dp
        ON dp.PedidoID = pe.PedidoID
    INNER JOIN dbo.Producto AS pr
        ON pr.ProductoID = dp.ProductoID
    INNER JOIN dbo.Categoria AS ca
        ON ca.CategoriaID = pr.CategoriaID
    WHERE pe.ClienteID = c.ClienteID
      AND pe.Estado = 'CONFIRMADO'
      AND pe.FechaPedido >= '20260101'
      AND pe.FechaPedido <  '20270101'
      AND ca.Nombre = 'Seguridad'
)
ORDER BY c.ClienteID;
GO

/* ============================================================
 B.Subconsulta correlacionada: PrecioLista > promedio de su categoria
   Criterio del promedio: AVG(PrecioLista) de TODOS los productos de la
   misma categoria (activos e inactivos), sin usar PrecioOferta.
   El promedio se compara sin redondear; ROUND solo se aplica al mostrarlo.
============================================================ */
SELECT   t.ProductoID,
         t.Nombre,
         t.Categoria,
         t.PrecioLista,
         t.PromedioCategoria
FROM     (SELECT p.ProductoID,
                 p.Nombre,
                 ca.Nombre AS Categoria,
                 p.PrecioLista,
                 ROUND (
                     (SELECT AVG (p2.PrecioLista)
                      FROM   dbo.Producto AS p2
                      WHERE  p2.CategoriaID = p.CategoriaID),
                     2
                 ) AS PromedioCategoria,
                 (SELECT AVG(p3.PrecioLista)
                  FROM   dbo.Producto AS p3
                  WHERE  p3.CategoriaID = p.CategoriaID) AS PromedioExacto
          FROM   dbo.Producto AS p
                 INNER JOIN
                 dbo.Categoria AS ca
                 ON ca.CategoriaID = p.CategoriaID) AS t
WHERE    t.PrecioLista > t.PromedioExacto 
ORDER BY t.ProductoID;
GO


/* ==========================================================
   C. Casos de prueba de la consulta A 
   Cada fila muestra cuantos pedidos CONFIRMADO 2026 tiene el
   cliente por categoria y si debe salir en A.
   ========================================================== */

SELECT c.ClienteID, c.Nombre,
       SUM(CASE WHEN ca.Nombre = 'Redes'     THEN 1 ELSE 0 END) AS LineasRedesConf2026,
       SUM(CASE WHEN ca.Nombre = 'Seguridad' THEN 1 ELSE 0 END) AS LineasSeguridadConf2026
FROM dbo.Cliente c
LEFT JOIN dbo.Pedido p
       ON p.ClienteID = c.ClienteID AND p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '2026-01-01' AND p.FechaPedido < '2027-01-01'
LEFT JOIN dbo.DetallePedido d  ON d.PedidoID = p.PedidoID
LEFT JOIN dbo.Producto pr      ON pr.ProductoID = d.ProductoID
LEFT JOIN dbo.Categoria ca     ON ca.CategoriaID = pr.CategoriaID
WHERE c.ClienteID IN (1, 2, 3, 7, 8, 10, 15)
GROUP BY c.ClienteID, c.Nombre
ORDER BY c.ClienteID;
GO
 
-- Detalle del caso 3: su pedido de Seguridad en 2026 es solo PENDIENTE (no cuenta)
SELECT p.PedidoID, p.ClienteID, p.FechaPedido, p.Estado, ca.Nombre AS Categoria
FROM dbo.Pedido p
JOIN dbo.DetallePedido d ON d.PedidoID = p.PedidoID
JOIN dbo.Producto pr     ON pr.ProductoID = d.ProductoID
JOIN dbo.Categoria ca    ON ca.CategoriaID = pr.CategoriaID
WHERE p.ClienteID = 3
ORDER BY p.PedidoID;
GO

/* ==========================================================
   Demostracion del riesgo de NOT IN con NULL
   ========================================================== */

   -- Sin NULL: devuelve los 14 clientes distintos de 2
SELECT COUNT(*) AS FilasSinNull
FROM dbo.Cliente
WHERE ClienteID NOT IN (SELECT 2);
 
-- Con un NULL en la lista: devuelve 0 filas (la comparacion da UNKNOWN)
SELECT COUNT(*) AS FilasConNull
FROM dbo.Cliente
WHERE ClienteID NOT IN (SELECT 2 UNION ALL SELECT CAST(NULL AS INT));
 
-- Version segura con NOT EXISTS: ignora el NULL y devuelve 14
SELECT COUNT(*) AS FilasNotExists
FROM dbo.Cliente c
WHERE NOT EXISTS (SELECT 1
                  FROM (SELECT 2 AS Id UNION ALL SELECT CAST(NULL AS INT)) v
                  WHERE v.Id = c.ClienteID);
GO