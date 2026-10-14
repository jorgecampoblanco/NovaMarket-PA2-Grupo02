# Datos base y casos preparados — PA2 NovaMarket

**Autor:** Andy Lescano · **Script:** `sql/00_esquema_y_datos_base.sql`

## Volumen cargado

| Tabla | Filas | Requisito del examen |
|---|---|---|
| Cliente | 15 | ≥ 15 |
| Categoria | 3 | Redes, Seguridad, Accesorios |
| Producto | 12 | ≥ 12 |
| Pedido | 40 | ≥ 40 |
| DetallePedido | 80 | ≥ 80 |

**Pedidos por año y estado**

| Año | CONFIRMADO | PENDIENTE | ANULADO | BORRADOR |
|---|---|---|---|---|
| 2025 | 7 | 1 | 1 | 1 |
| 2026 | 19 | 5 | 2 | 4 |

Los IDs son fijos porque el script recrea las tablas (IDENTITY empieza en 1).

## Casos preparados por actividad

| Actividad | Caso | IDs | Resultado esperado |
|---|---|---|---|
| S04-A | Redes CONFIRMADO 2026 y sin Seguridad CONFIRMADO 2026 | Clientes 1, 3, 7, 8, 12 | Aparecen, una sola vez cada uno |
| S04-A | Seguridad 2026 solo PENDIENTE (no cuenta) | Cliente 3 | Aparece |
| S04-A | Varios pedidos y líneas de Redes | Cliente 7 | Aparece una sola vez |
| S04-A | Seguridad comprada solo en 2025 | Cliente 8 | Aparece |
| S04-A | Compró Redes y Seguridad en 2026 | Clientes 2 y 10 | **Excluidos** |
| S04-A | Redes el 2025-12-31 (límite de fecha) | Cliente 15 | **Excluido** |
| S04-B | PrecioLista > promedio de su categoría | Productos 1, 3, 6, 10, 11 | Aparecen |
| S05-A | CONFIRMADO antes del 2026-01-01 | Pedidos 1, 2, 3, 4, 7, 8, 9 | 7 filas al histórico |
| S05-B | Redes activos con Stock ≥ 10 | Productos 1 y 2 | Oferta 350.91 y 143.91 |
| S05-B | Stock = 10 (límite, sí entra) | Producto 2 | Recibe oferta |
| S05-B | Stock 8 / producto inactivo | Productos 3 y 4 | Sin oferta |
| S05-C | BORRADOR sin detalle | Pedidos 10, 32, 37 | Se eliminan (3) |
| S05-C | BORRADOR con detalle | Pedidos 33, 38 | Permanecen |
| S06-B | Sin compras CONFIRMADO en 2026 | Clientes 5, 6, 9, 13, 14 | Aparecen |
| S07-B | Activos sin compra válida en 2026 | Clientes 5, 6, 9, 13, 14 | Pedidos 0 y monto 0 |
| S07-B | Cliente inactivo | Cliente 12 | No aparece en el reporte |

## Decisiones de diseño

- **Documento** acepta DNI (8) o RUC (11), solo dígitos (`CK_Cliente_Documento`), y es único.
- **PrecioOferta** es opcional (NULL); si existe, debe ser mayor que 0 y no superar `PrecioLista` (`CK_Producto_PrecioOferta`).
- **Estado** solo admite CONFIRMADO, PENDIENTE, ANULADO y BORRADOR; por defecto es BORRADOR.
- **Canal** solo admite WEB, TIENDA, APP y TELEFONO. Quien genere los datos de S07 debe usar estos valores.
- **PrecioUnitario** guarda el precio histórico de la venta: en 2025 es 95 % del precio actual, para demostrar que los reportes usan el precio de DetallePedido y no el de Producto.
