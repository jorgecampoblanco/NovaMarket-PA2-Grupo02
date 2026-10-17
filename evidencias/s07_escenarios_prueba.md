# S07-A — Datos de prueba y escenarios identificados

**Autor:** Andy Lescano · **Script:** `sql/04_s07_datos_prueba.sql`

## Cómo se ejecuta

1. `00_esquema_y_datos_base.sql` una sola vez, al inicio (recrea las tablas).
2. `04_s07_datos_prueba.sql` agrega los pedidos 41–210 y los detalles 81–433 con IDs explícitos.
   - No borra ni modifica datos. Si se ejecuta dos veces, no duplica: detecta que ya existen y omite los INSERT.
   - No altera los resultados esperados de S04-A, S05-A, S05-C ni S06-B, así que puede correrse antes o después de esas actividades.

## Volumen (COUNT(*) por tabla)

| Tabla | Base (00) | Agregado (04) | Total | Mínimo examen |
|---|---|---|---|---|
| Cliente | 15 | 0 | 15 | — |
| Categoria | 3 | 0 | 3 | — |
| Producto | 12 | 0 | 12 | — |
| Pedido | 40 | 170 | **210** (207 si ya se ejecutó S05-C) | 200 |
| DetallePedido | 80 | 353 | **433** | 400 |

## Distribución por estado y año

| Año | CONFIRMADO | PENDIENTE | ANULADO | BORRADOR | Total |
|---|---|---|---|---|---|
| 2025 | 7 | 7 | 9 | 7 | 30 |
| 2026 | 120 | 29 | 17 | 14 | 180 |

S05-C elimina los borradores sin detalle 10 (2025), 32 y 37 (2026); después de ejecutarlo, BORRADOR queda en 6 y 12. Todos los pedidos nuevos tienen detalle.

## Integridad (el script lo comprueba; todo debe salir 0)

| Control | Esperado |
|---|---|
| Detalles sin pedido | 0 |
| Detalles sin producto | 0 |
| Pedidos sin cliente | 0 |
| Pedidos nuevos sin detalle | 0 |

## Escenarios de prueba para S07-B / S07-C

| # | Escenario | IDs | Resultado esperado en el reporte |
|---|---|---|---|
| E1 | Cliente con varias líneas en un pedido | Pedido 41 (cliente 3): 5 líneas, 1375.60 | El pedido cuenta 1 vez. Cliente 3 = **13 pedidos / 7702.00** |
| E2 | Cliente sin compras confirmadas | Cliente 5 (sin pedidos) y cliente 6 (solo PENDIENTE/ANULADO, ej. pedido 44) | Ambos aparecen con **0 / 0.00** |
| E3 | Pedido PENDIENTE | Pedido 42 (cliente 1): 848.80 | No suma |
| E4 | Pedido ANULADO | Pedido 43 (cliente 1): 998.80 | No suma. Cliente 1 = **18 pedidos / 10683.80** |
| E5 | Límite de fecha | Pedido 8 (2025-12-31) y pedido 11 (2026-01-01), cliente 15 | 8 no cuenta; 11 sí cuenta |
| E6 | Cliente inactivo | Cliente 12 | No aparece |

## Reporte esperado (solo CONFIRMADO entre 2026-01-01 y 2026-12-31, clientes activos)

| ClienteID | Nombre | TotalPedidos2026 | MontoVendido2026 |
|---|---|---|---|
| 1 | Ana Torres | 18 | 10683.80 |
| 2 | Bruno Diaz | 17 | 14337.60 |
| 3 | Carla Rios | 13 | 7702.00 |
| 4 | Diego Salas | 11 | 9446.50 |
| 5 | Elena Vargas | 0 | 0.00 |
| 6 | Fabio Rojas | 0 | 0.00 |
| 7 | Gabriela Medina | 14 | 9251.00 |
| 8 | Hugo Paredes | 9 | 5685.60 |
| 9 | Irene Castillo | 0 | 0.00 |
| 10 | Jorge Mendoza SAC | 17 | 11828.30 |
| 11 | Karen Huaman | 9 | 7741.70 |
| 13 | Maria Flores | 0 | 0.00 |
| 14 | Nicolas Vega | 0 | 0.00 |
| 15 | Olga Ramos | 11 | 17256.20 |

Los clientes 5, 6, 9, 13 y 14 deben aparecer con 0 y 0.00. Si no aparecen, el filtro de estado o de fecha se puso en el `WHERE` en lugar del `ON` del `LEFT JOIN`, y eso elimina a los clientes sin ventas.

Quien ejecute `05_S07_reporte_ventas_clientes.sql` completa la columna "Obtenido" de la matriz con estos valores como referencia.

## Diseño de los datos nuevos

- 2025: solo PENDIENTE, ANULADO y BORRADOR (con detalle). El histórico de S05-A sigue en 7 pedidos.
- CONFIRMADO 2026 solo para los clientes 1, 2, 3, 4, 7, 8, 10, 11 y 15:
  - 1, 3, 7 y 8 compran solo Redes y Accesorios, así S04-A sigue dando 1, 3, 7, 8 y 12.
  - 4, 11 y 15 compran solo Seguridad y Accesorios, sin Redes.
- Los clientes 5 y 14 siguen sin pedidos. El 12 (inactivo) no recibe pedidos nuevos.
- PrecioUnitario guarda el precio histórico de la venta: en 2025 es el 95 % del precio de lista. El producto 4 (inactivo) solo aparece en 2025.
