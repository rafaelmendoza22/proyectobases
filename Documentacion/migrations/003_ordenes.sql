-- =====================================================================
-- migrations/003_ordenes.sql · AutoRueda Taller Técnico · Entrega 2
-- ORDEN_SERVICIO y las tablas que cuelgan de ella.
-- =====================================================================

-- ---------------------------------------------------------------------
-- ORDEN_SERVICIO
--  · id_vehiculo / id_mecanico: RESTRICT. La orden es el expediente del vehículo y quien
--    la atendió es parte esencial del historial; los mecánicos no se borran, se desactivan.
--  · id_cita: SET NULL + UNIQUE. La cita es solo el origen opcional (S-03, el cliente puede
--    llegar sin cita); si se borra, la orden se conserva. Una cita origina como máximo una orden.
--  · fecha_recepcion/fecha_entrega son TIMESTAMP (llevan hora); las demás fechas son DATE.
-- ---------------------------------------------------------------------
CREATE TABLE orden_servicio (
    id_orden         INTEGER GENERATED ALWAYS AS IDENTITY,
    fecha_recepcion  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega    TIMESTAMP,
    estado           VARCHAR(15) NOT NULL DEFAULT 'recibido',
    id_vehiculo      INTEGER     NOT NULL,
    id_mecanico      INTEGER     NOT NULL,
    id_cita          INTEGER,
    CONSTRAINT pk_orden_servicio PRIMARY KEY (id_orden),
    CONSTRAINT fk_orden_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo) ON DELETE RESTRICT,
    CONSTRAINT fk_orden_mecanico FOREIGN KEY (id_mecanico)
        REFERENCES mecanico (id_mecanico) ON DELETE RESTRICT,
    CONSTRAINT fk_orden_cita FOREIGN KEY (id_cita)
        REFERENCES cita (id_cita) ON DELETE SET NULL,
    CONSTRAINT uq_orden_cita UNIQUE (id_cita),
    CONSTRAINT ck_orden_estado
        CHECK (estado IN ('recibido', 'en_reparacion', 'listo', 'entregado')),
    CONSTRAINT ck_orden_fechas
        CHECK (fecha_entrega IS NULL OR fecha_entrega >= fecha_recepcion),
    CONSTRAINT ck_orden_entrega_coherente      -- hay fecha de entrega si y solo si la orden está entregada
        CHECK ((estado = 'entregado') = (fecha_entrega IS NOT NULL))
);

-- ---------------------------------------------------------------------
-- DETALLE_ORDEN_REPUESTO (resuelve el M:N Utiliza)
--  · id_orden: CASCADE. El detalle no existe sin su orden.
--  · id_repuesto: RESTRICT. No se borra un repuesto ya usado (se perdería lo que se cobró).
--  · precio_unitario_aplicado: precio congelado al momento del uso (S-06).
-- ---------------------------------------------------------------------
CREATE TABLE detalle_orden_repuesto (
    id_orden                  INTEGER       NOT NULL,
    id_repuesto               INTEGER       NOT NULL,
    cantidad                  INTEGER       NOT NULL,
    precio_unitario_aplicado  NUMERIC(10,2) NOT NULL,
    CONSTRAINT pk_detalle_orden_repuesto PRIMARY KEY (id_orden, id_repuesto),
    CONSTRAINT fk_detalle_orden_orden FOREIGN KEY (id_orden)
        REFERENCES orden_servicio (id_orden) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_orden_repuesto FOREIGN KEY (id_repuesto)
        REFERENCES repuesto (id_repuesto) ON DELETE RESTRICT,
    CONSTRAINT ck_detalle_orden_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_orden_precio   CHECK (precio_unitario_aplicado >= 0)
);

-- ---------------------------------------------------------------------
-- HISTORIAL_ESTADO
--  · id_orden: CASCADE (el historial no existe sin la orden).
--  · id_mecanico: SET NULL. Quién registró el cambio es dato de apoyo; si se borra
--    ese mecánico, el cambio de estado queda registrado igualmente.
-- ---------------------------------------------------------------------
CREATE TABLE historial_estado (
    id_historial     INTEGER GENERATED ALWAYS AS IDENTITY,
    id_orden         INTEGER     NOT NULL,
    id_mecanico      INTEGER,
    estado_anterior  VARCHAR(15),             -- NULL en el primer registro de la orden
    estado_nuevo     VARCHAR(15) NOT NULL,
    fecha_cambio     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_historial_estado PRIMARY KEY (id_historial),
    CONSTRAINT fk_historial_orden FOREIGN KEY (id_orden)
        REFERENCES orden_servicio (id_orden) ON DELETE CASCADE,
    CONSTRAINT fk_historial_mecanico FOREIGN KEY (id_mecanico)
        REFERENCES mecanico (id_mecanico) ON DELETE SET NULL,
    CONSTRAINT uq_historial_orden_fecha UNIQUE (id_orden, fecha_cambio),
    CONSTRAINT ck_historial_estado_nuevo
        CHECK (estado_nuevo IN ('recibido', 'en_reparacion', 'listo', 'entregado')),
    CONSTRAINT ck_historial_estado_anterior
        CHECK (estado_anterior IS NULL
               OR estado_anterior IN ('recibido', 'en_reparacion', 'listo', 'entregado')),
    CONSTRAINT ck_historial_cambio_real CHECK (estado_anterior IS DISTINCT FROM estado_nuevo)
);

-- ---------------------------------------------------------------------
-- GARANTIA. fecha_vencimiento NO se guarda (derivado, ver vista v_garantia_vigencia).
-- RESTRICT: una garantía es un compromiso con el cliente; no se borra la orden que la respalda.
-- ---------------------------------------------------------------------
CREATE TABLE garantia (
    id_garantia    INTEGER GENERATED ALWAYS AS IDENTITY,
    condiciones    VARCHAR(250) NOT NULL,
    dias_cobertura INTEGER      NOT NULL,
    fecha_inicio   DATE         NOT NULL,
    id_orden       INTEGER      NOT NULL,
    CONSTRAINT pk_garantia PRIMARY KEY (id_garantia),
    CONSTRAINT fk_garantia_orden FOREIGN KEY (id_orden)
        REFERENCES orden_servicio (id_orden) ON DELETE RESTRICT,
    CONSTRAINT ck_garantia_dias CHECK (dias_cobertura > 0)
);

-- ---------------------------------------------------------------------
-- ALERTAS_STOCK. stock_registrado es una foto histórica (no cambia con el inventario).
-- CASCADE: una alerta no tiene sentido sin el repuesto al que avisa.
-- ---------------------------------------------------------------------
CREATE TABLE alertas_stock (
    id_alerta         INTEGER GENERATED ALWAYS AS IDENTITY,
    fecha_alerta      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    stock_registrado  INTEGER     NOT NULL,
    estado            VARCHAR(10) NOT NULL DEFAULT 'activa',
    id_repuesto       INTEGER     NOT NULL,
    CONSTRAINT pk_alertas_stock PRIMARY KEY (id_alerta),
    CONSTRAINT fk_alertas_repuesto FOREIGN KEY (id_repuesto)
        REFERENCES repuesto (id_repuesto) ON DELETE CASCADE,
    CONSTRAINT ck_alertas_stock_registrado CHECK (stock_registrado >= 0),
    CONSTRAINT ck_alertas_estado CHECK (estado IN ('activa', 'atendida'))
);
