-- =====================================================================
-- migrations/004_compras.sql · AutoRueda Taller Técnico · Entrega 2
-- COMPRA y DETALLE_COMPRA (resuelve el M:N Incluye). Total NO se guarda (ver vista).
-- =====================================================================

-- RESTRICT hacia PROVEEDOR: no se borra un proveedor que ya tiene compras (se desactiva).
CREATE TABLE compra (
    id_compra     INTEGER GENERATED ALWAYS AS IDENTITY,
    fecha_compra  DATE        NOT NULL,
    estado        VARCHAR(10) NOT NULL DEFAULT 'pendiente',
    id_proveedor  INTEGER     NOT NULL,
    CONSTRAINT pk_compra PRIMARY KEY (id_compra),
    CONSTRAINT fk_compra_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_proveedor) ON DELETE RESTRICT,
    CONSTRAINT ck_compra_estado CHECK (estado IN ('pendiente', 'recibida', 'cancelada'))
);

-- id_compra: CASCADE (las líneas no existen sin su compra).
-- id_repuesto: RESTRICT (no se borra un repuesto que ya fue comprado).
-- costo_unitario es lo que se pagó al proveedor; no es el precio de venta del repuesto.
CREATE TABLE detalle_compra (
    id_compra       INTEGER       NOT NULL,
    id_repuesto     INTEGER       NOT NULL,
    cantidad        INTEGER       NOT NULL,
    costo_unitario  NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_detalle_compra PRIMARY KEY (id_compra, id_repuesto),
    CONSTRAINT fk_detalle_compra_compra FOREIGN KEY (id_compra)
        REFERENCES compra (id_compra) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_compra_repuesto FOREIGN KEY (id_repuesto)
        REFERENCES repuesto (id_repuesto) ON DELETE RESTRICT,
    CONSTRAINT ck_detalle_compra_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_compra_costo    CHECK (costo_unitario >= 0)
);
