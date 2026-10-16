# Pruebas del reporte de ventas por cliente

Se verifica que el reporte incluya a todos los clientes activos y considere solamente pedidos confirmados de 2026. Los importes se calculan con `Cantidad * PrecioUnitario`, utilizando el precio guardado al momento de la venta.

## Casos utilizados

| Caso | Registro de referencia | Resultado esperado con los datos actuales | ¿Qué se comprueba? |
|---|---|---|---|
| Pedido con varias líneas | Cliente 3; pedido 41 (5 líneas por 1,375.60) | 13 pedidos; monto 7,702.00 | Las cinco líneas del pedido 41 se suman, pero ese pedido cuenta una sola vez. |
| Cliente sin compras confirmadas | Cliente 5 | 0 pedidos; monto 0.00 | Se muestra al cliente activo aunque no tenga ventas. |
| Pedido pendiente | Cliente 1; pedido 42 (848.80) | 18 pedidos; monto 10,683.80 | No se añade el pedido pendiente al número de ventas ni al importe. |
| Pedido anulado | Cliente 1; pedido 43 (998.80) | 18 pedidos; monto 10,683.80 | No se añade el pedido anulado al número de ventas ni al importe. |

## Cómo se valida

1. Ejecutar la carga de datos del proyecto y, después, `sql/05_S07_reporte_ventas_clientes.sql`.
2. Ejecutar `evidencias/PruebasReporteClientes.sql`. El último resultado es una matriz que muestra pedidos y montos **esperados**, **obtenidos** y el estado **APROBADO/FALLIDO** de cada prueba.
3. Conservar una captura de esa matriz en la carpeta `evidencias/`; los valores de la tabla anterior provienen de los datos del repositorio.

## Decisiones utilizadas

- `LEFT JOIN` permite conservar clientes activos aunque no tengan pedidos confirmados. Colocar el filtro de estado y fecha en el `WHERE` de una consulta con `LEFT JOIN` directo sobre `Pedido` podría eliminar a esos clientes; por eso se filtran los pedidos antes de unirlos al listado de clientes.
- `COALESCE` convierte el total `NULL` de un cliente sin ventas en `0.00`.
- El reporte suma primero las líneas de cada pedido y después cuenta los pedidos, para evitar repeticiones. Las pruebas contrastan este resultado con `COUNT(DISTINCT PedidoID)` y los importes obtenidos directamente de las tablas.
- Los pedidos `PENDIENTE` y `ANULADO` no representan ventas confirmadas y no deben sumarse.

Si cambian los datos de prueba, la matriz SQL calcula de nuevo los valores esperados. Los importes fijos de esta hoja corresponden al segundo avance del repositorio.
