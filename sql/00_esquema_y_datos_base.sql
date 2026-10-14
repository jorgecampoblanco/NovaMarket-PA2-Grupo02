-- PA2 - NovaMarket | 00: Esquema y datos base
-- Autor: Andy Lescano (modelo fisico + datos base)
-- Ejecutar completo (F5) sobre una instancia SQL Server. Recrea las tablas desde cero.

-- Crear la base si no existe
IF DB_ID('PA2_NovaMarket') IS NULL
    CREATE DATABASE PA2_NovaMarket;
GO

-- Propietario sa: evita error del diagrama al restaurar en otra PC
ALTER AUTHORIZATION ON DATABASE::PA2_NovaMarket TO sa;
GO

USE PA2_NovaMarket;
GO

-- Borrar en orden inverso por las FK (hijas primero)
IF OBJECT_ID('dbo.DetallePedido','U') IS NOT NULL DROP TABLE dbo.DetallePedido;
IF OBJECT_ID('dbo.Pedido','U')        IS NOT NULL DROP TABLE dbo.Pedido;
IF OBJECT_ID('dbo.Producto','U')      IS NOT NULL DROP TABLE dbo.Producto;
IF OBJECT_ID('dbo.Categoria','U')     IS NOT NULL DROP TABLE dbo.Categoria;
IF OBJECT_ID('dbo.Cliente','U')       IS NOT NULL DROP TABLE dbo.Cliente;
GO

/* =========================  ESQUEMA  ========================= */

-- Tablas maestras
CREATE TABLE dbo.Cliente (
    ClienteID   INT IDENTITY(1,1) NOT NULL,
    Documento   VARCHAR(11)  NOT NULL,
    Nombre      VARCHAR(100) NOT NULL,
    Ciudad      VARCHAR(50)  NULL,
    Activo      BIT          NOT NULL CONSTRAINT DF_Cliente_Activo DEFAULT (1),
    CONSTRAINT PK_Cliente           PRIMARY KEY (ClienteID),
    CONSTRAINT UQ_Cliente_Documento UNIQUE (Documento),
    -- DNI (8) o RUC (11), solo digitos
    CONSTRAINT CK_Cliente_Documento CHECK (LEN(Documento) IN (8, 11) AND Documento NOT LIKE '%[^0-9]%')
);
GO

CREATE TABLE dbo.Categoria (
    CategoriaID INT IDENTITY(1,1) NOT NULL,
    Nombre      VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Categoria        PRIMARY KEY (CategoriaID),
    CONSTRAINT UQ_Categoria_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE dbo.Producto (
    ProductoID   INT IDENTITY(1,1) NOT NULL,
    CategoriaID  INT            NOT NULL,
    Nombre       VARCHAR(100)   NOT NULL,
    PrecioLista  DECIMAL(10,2)  NOT NULL,
    PrecioOferta DECIMAL(10,2)  NULL,
    Stock        INT            NOT NULL CONSTRAINT DF_Producto_Stock  DEFAULT (0),
    Activo       BIT            NOT NULL CONSTRAINT DF_Producto_Activo DEFAULT (1),
    CONSTRAINT PK_Producto           PRIMARY KEY (ProductoID),
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (CategoriaID) REFERENCES dbo.Categoria (CategoriaID),
    CONSTRAINT CK_Producto_PrecioLista  CHECK (PrecioLista > 0),
    CONSTRAINT CK_Producto_Stock        CHECK (Stock >= 0),
    -- La oferta es opcional, pero si existe no puede superar el precio de lista
    CONSTRAINT CK_Producto_PrecioOferta CHECK (PrecioOferta IS NULL OR (PrecioOferta > 0 AND PrecioOferta <= PrecioLista))
);
GO

-- Tablas de pedidos
CREATE TABLE dbo.Pedido (
    PedidoID    INT IDENTITY(1,1) NOT NULL,
    ClienteID   INT          NOT NULL,
    FechaPedido DATE         NOT NULL CONSTRAINT DF_Pedido_FechaPedido DEFAULT (GETDATE()),
    Estado      VARCHAR(15)  NOT NULL CONSTRAINT DF_Pedido_Estado      DEFAULT ('BORRADOR'),
    Canal       VARCHAR(20)  NOT NULL,
    CONSTRAINT PK_Pedido         PRIMARY KEY (PedidoID),
    CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (ClienteID) REFERENCES dbo.Cliente (ClienteID),
    CONSTRAINT CK_Pedido_Estado  CHECK (Estado IN ('CONFIRMADO','PENDIENTE','ANULADO','BORRADOR')),
    CONSTRAINT CK_Pedido_Canal   CHECK (Canal IN ('WEB','TIENDA','APP','TELEFONO'))
);
GO

-- Detalle: guarda el precio historico de la venta (no el precio actual del producto)
CREATE TABLE dbo.DetallePedido (
    DetalleID      INT IDENTITY(1,1) NOT NULL,
    PedidoID       INT            NOT NULL,
    ProductoID     INT            NOT NULL,
    Cantidad       INT            NOT NULL,
    PrecioUnitario DECIMAL(10,2)  NOT NULL,
    CONSTRAINT PK_DetallePedido          PRIMARY KEY (DetalleID),
    CONSTRAINT FK_DetallePedido_Pedido   FOREIGN KEY (PedidoID)   REFERENCES dbo.Pedido (PedidoID),
    CONSTRAINT FK_DetallePedido_Producto FOREIGN KEY (ProductoID) REFERENCES dbo.Producto (ProductoID),
    CONSTRAINT CK_DetallePedido_Cantidad       CHECK (Cantidad > 0),
    CONSTRAINT CK_DetallePedido_PrecioUnitario CHECK (PrecioUnitario > 0)
);
GO

/* =======================  DATOS BASE  ======================== */
-- Las tablas se recrean arriba, por eso los IDs IDENTITY son fijos (1, 2, 3...).

INSERT INTO dbo.Categoria (Nombre) VALUES ('Redes'), ('Seguridad'), ('Accesorios');
GO

-- 15 clientes (ID 12 inactivo; IDs 5 y 14 sin pedidos)
INSERT INTO dbo.Cliente (Documento, Nombre, Ciudad, Activo) VALUES
    ('70123451', 'Ana Torres', 'Lima', 1),   -- 1
    ('70123452', 'Bruno Diaz', 'Arequipa', 1),   -- 2
    ('70123453', 'Carla Rios', 'Trujillo', 1),   -- 3
    ('70123454', 'Diego Salas', 'Cusco', 1),   -- 4
    ('70123455', 'Elena Vargas', 'Lima', 1),   -- 5
    ('70123456', 'Fabio Rojas', 'Piura', 1),   -- 6
    ('70123457', 'Gabriela Medina', 'Lima', 1),   -- 7
    ('70123458', 'Hugo Paredes', 'Chiclayo', 1),   -- 8
    ('70123459', 'Irene Castillo', 'Lima', 1),   -- 9
    ('20601234561', 'Jorge Mendoza SAC', 'Arequipa', 1),   -- 10
    ('70123461', 'Karen Huaman', 'Huancayo', 1),   -- 11
    ('70123462', 'Luis Quispe', 'Lima', 0),   -- 12
    ('70123463', 'Maria Flores', 'Ica', 1),   -- 13
    ('70123464', 'Nicolas Vega', 'Tacna', 1),   -- 14
    ('70123465', 'Olga Ramos', 'Lima', 1);   -- 15
GO

-- 12 productos (4 por categoria). PrecioOferta inicia en NULL
INSERT INTO dbo.Producto (CategoriaID, Nombre, PrecioLista, Stock, Activo) VALUES
    (1, 'Router WiFi 6 AX3000', 389.90, 25, 1),
    (1, 'Switch 8 puertos Gigabit', 159.90, 10, 1),
    (1, 'Access Point Mesh', 549.00, 8, 1),
    (1, 'Cable UTP Cat6 305 m', 289.00, 40, 0),
    (2, 'Camara IP Domo 4MP', 279.90, 18, 1),
    (2, 'Kit DVR 8 camaras', 1299.00, 5, 1),
    (2, 'Cerradura inteligente', 459.00, 10, 1),
    (2, 'Sensor de movimiento WiFi', 89.90, 30, 1),
    (3, 'Mouse inalambrico', 59.90, 50, 1),
    (3, 'Teclado mecanico', 219.00, 20, 1),
    (3, 'Audifonos Bluetooth', 149.90, 15, 1),
    (3, 'Hub USB-C 7 en 1', 129.00, 9, 1);
GO

-- 40 pedidos 2025-2026 (PedidoID = orden de insercion)
INSERT INTO dbo.Pedido (ClienteID, FechaPedido, Estado, Canal) VALUES
    (9, '2025-02-10', 'CONFIRMADO', 'WEB'),
    (9, '2025-05-15', 'CONFIRMADO', 'TIENDA'),
    (8, '2025-06-20', 'CONFIRMADO', 'WEB'),
    (2, '2025-08-03', 'CONFIRMADO', 'APP'),
    (4, '2025-09-12', 'PENDIENTE', 'WEB'),
    (10, '2025-10-25', 'ANULADO', 'TIENDA'),
    (11, '2025-11-30', 'CONFIRMADO', 'WEB'),
    (15, '2025-12-31', 'CONFIRMADO', 'TIENDA'),
    (7, '2025-12-15', 'CONFIRMADO', 'APP'),
    (13, '2025-07-07', 'BORRADOR', 'WEB'),
    (15, '2026-01-01', 'CONFIRMADO', 'WEB'),
    (1, '2026-01-15', 'CONFIRMADO', 'WEB'),
    (1, '2026-03-02', 'CONFIRMADO', 'TIENDA'),
    (2, '2026-01-20', 'CONFIRMADO', 'APP'),
    (2, '2026-02-11', 'CONFIRMADO', 'WEB'),
    (3, '2026-02-05', 'CONFIRMADO', 'WEB'),
    (3, '2026-02-18', 'PENDIENTE', 'TIENDA'),
    (4, '2026-03-10', 'CONFIRMADO', 'TIENDA'),
    (4, '2026-04-22', 'CONFIRMADO', 'WEB'),
    (6, '2026-03-15', 'PENDIENTE', 'WEB'),
    (6, '2026-04-01', 'ANULADO', 'APP'),
    (7, '2026-01-28', 'CONFIRMADO', 'WEB'),
    (7, '2026-05-09', 'CONFIRMADO', 'TIENDA'),
    (7, '2026-06-14', 'CONFIRMADO', 'APP'),
    (8, '2026-02-27', 'CONFIRMADO', 'WEB'),
    (8, '2026-07-03', 'PENDIENTE', 'WEB'),
    (10, '2026-03-21', 'CONFIRMADO', 'TIENDA'),
    (10, '2026-08-08', 'CONFIRMADO', 'WEB'),
    (11, '2026-04-05', 'CONFIRMADO', 'APP'),
    (11, '2026-09-17', 'CONFIRMADO', 'WEB'),
    (12, '2026-05-20', 'CONFIRMADO', 'TIENDA'),
    (13, '2026-06-01', 'BORRADOR', 'WEB'),
    (13, '2026-06-02', 'BORRADOR', 'APP'),
    (9, '2026-07-19', 'PENDIENTE', 'WEB'),
    (9, '2026-08-30', 'ANULADO', 'TIENDA'),
    (2, '2026-09-09', 'CONFIRMADO', 'WEB'),
    (3, '2026-10-02', 'BORRADOR', 'WEB'),
    (1, '2026-10-05', 'BORRADOR', 'APP'),
    (4, '2026-10-10', 'CONFIRMADO', 'TIENDA'),
    (12, '2026-10-12', 'PENDIENTE', 'WEB');
GO

-- 80 detalles. Pedidos 10, 32 y 37 son BORRADOR sin detalle. Precio 2025 = precio historico (95% del actual)
INSERT INTO dbo.DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario) VALUES
    (1, 9, 2, 56.90),
    (1, 10, 1, 208.05),
    (2, 1, 1, 370.40),
    (2, 5, 1, 265.90),
    (3, 5, 2, 265.90),
    (3, 8, 3, 85.41),
    (4, 2, 1, 151.91),
    (4, 11, 1, 142.41),
    (5, 6, 1, 1234.05),
    (5, 9, 1, 56.90),
    (6, 3, 1, 521.55),
    (6, 12, 2, 122.55),
    (7, 10, 1, 208.05),
    (7, 11, 1, 142.41),
    (8, 1, 1, 370.40),
    (8, 4, 1, 274.55),
    (9, 2, 2, 151.91),
    (9, 9, 1, 56.90),
    (11, 9, 1, 59.90),
    (11, 12, 1, 129.00),
    (12, 1, 1, 389.90),
    (12, 9, 2, 59.90),
    (12, 11, 1, 149.90),
    (13, 2, 1, 159.90),
    (13, 11, 1, 149.90),
    (14, 3, 1, 549.00),
    (14, 10, 1, 219.00),
    (15, 5, 2, 279.90),
    (15, 8, 1, 89.90),
    (16, 1, 1, 389.90),
    (16, 12, 1, 129.00),
    (17, 6, 1, 1299.00),
    (17, 9, 1, 59.90),
    (18, 5, 1, 279.90),
    (18, 7, 1, 459.00),
    (19, 8, 2, 89.90),
    (19, 11, 1, 149.90),
    (20, 1, 1, 389.90),
    (20, 9, 1, 59.90),
    (21, 2, 1, 159.90),
    (21, 10, 1, 219.00),
    (22, 1, 1, 389.90),
    (22, 2, 1, 159.90),
    (22, 9, 1, 59.90),
    (22, 11, 1, 149.90),
    (23, 3, 1, 549.00),
    (23, 12, 1, 129.00),
    (24, 2, 2, 159.90),
    (24, 10, 1, 219.00),
    (25, 3, 1, 549.00),
    (25, 9, 1, 59.90),
    (26, 10, 1, 219.00),
    (26, 11, 1, 149.90),
    (27, 1, 1, 389.90),
    (27, 5, 1, 279.90),
    (27, 9, 1, 59.90),
    (28, 7, 1, 459.00),
    (28, 12, 1, 129.00),
    (29, 9, 3, 59.90),
    (29, 10, 1, 219.00),
    (29, 12, 1, 129.00),
    (30, 11, 2, 149.90),
    (30, 12, 1, 129.00),
    (31, 2, 1, 159.90),
    (31, 11, 1, 149.90),
    (33, 1, 1, 389.90),
    (33, 9, 1, 59.90),
    (34, 5, 1, 279.90),
    (34, 10, 1, 219.00),
    (35, 1, 1, 389.90),
    (35, 8, 1, 89.90),
    (36, 6, 1, 1299.00),
    (36, 9, 1, 59.90),
    (36, 8, 1, 89.90),
    (38, 12, 1, 129.00),
    (38, 10, 1, 219.00),
    (39, 11, 1, 149.90),
    (39, 9, 2, 59.90),
    (40, 5, 1, 279.90),
    (40, 8, 1, 89.90);
GO

/* ======================  VERIFICACION  ====================== */

-- Conteo por tabla (esperado: 15 / 3 / 12 / 40 / 80)
SELECT 'Cliente' AS Tabla, COUNT(*) AS Filas FROM dbo.Cliente UNION ALL
SELECT 'Categoria',        COUNT(*) FROM dbo.Categoria       UNION ALL
SELECT 'Producto',         COUNT(*) FROM dbo.Producto        UNION ALL
SELECT 'Pedido',           COUNT(*) FROM dbo.Pedido          UNION ALL
SELECT 'DetallePedido',    COUNT(*) FROM dbo.DetallePedido;

-- Distribucion de pedidos por anio y estado
SELECT YEAR(FechaPedido) AS Anio, Estado, COUNT(*) AS Pedidos
FROM dbo.Pedido
GROUP BY YEAR(FechaPedido), Estado
ORDER BY Anio, Estado;
GO

/* =================  CASOS PREPARADOS (guia del equipo)  =================
S04-A  Redes CONFIRMADO 2026 y sin Seguridad CONFIRMADO 2026 -> esperado: clientes 1, 3, 7, 8, 12
       - 3: tiene Seguridad 2026 solo PENDIENTE (debe salir)
       - 7: varios pedidos y lineas de Redes (debe salir una sola vez)
       - 8: compro Seguridad solo en 2025 (debe salir)
       - 2 y 10: compraron Redes y Seguridad en 2026 (excluidos)
       - 15: Redes el 2025-12-31 (limite, excluido)
S04-B  PrecioLista > promedio de su categoria -> esperado: productos 1, 3, 6, 10, 11
S05-A  CONFIRMADO antes de 2026-01-01 -> 7 pedidos (1, 2, 3, 4, 7, 8, 9)
S05-B  Oferta 90%: Redes activos con Stock >= 10 -> productos 1 (350.91) y 2 (143.91)
       - 2 tiene Stock = 10 (limite, entra); 3 tiene Stock 8 y 4 esta inactivo (no entran)
S05-C  BORRADOR sin detalle -> pedidos 10, 32 y 37; BORRADOR con detalle 33 y 38 deben quedar
S06-B  Sin compras CONFIRMADO 2026 -> clientes 5, 6, 9, 13, 14
S07-B  Clientes activos sin compra valida 2026 deben salir en 0: 5, 6, 9, 13, 14 (12 es inactivo)
========================================================================== */
