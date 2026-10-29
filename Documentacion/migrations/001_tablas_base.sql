-- =====================================================================
-- migrations/001_tablas_base.sql · AutoRueda Taller Técnico · Entrega 2
-- Tablas que no dependen de ninguna otra: PROVEEDOR, MECANICO, CLIENTE, REPUESTO.
-- Convención de nombres de restricciones:
--   pk_<tabla> · fk_<hija>_<padre> · ck_<tabla>_<regla> · uq_<tabla>_<campo> · ex_<tabla>_<regla>
-- Una migración aplicada no se edita: los cambios van en una migración nueva.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;   -- la usa el EXCLUDE de CITA (migración 002)

-- ---------------------------------------------------------------------
-- PROVEEDOR: quien nos vende repuestos. Se desactiva, no se borra (activo).
-- ---------------------------------------------------------------------
CREATE TABLE proveedor (
    id_proveedor  INTEGER GENERATED ALWAYS AS IDENTITY,
    nit           VARCHAR(20)  NOT NULL,
    razon_social  VARCHAR(120) NOT NULL,
    direccion     VARCHAR(200),
    telefono      VARCHAR(20),
    correo        VARCHAR(150),
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_proveedor     PRIMARY KEY (id_proveedor),
    CONSTRAINT uq_proveedor_nit UNIQUE (nit)          -- un NIT identifica una sola empresa
);

-- ---------------------------------------------------------------------
-- MECANICO: nunca se borra, se marca inactivo (conserva su historial).
-- ---------------------------------------------------------------------
CREATE TABLE mecanico (
    id_mecanico   INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre        VARCHAR(120) NOT NULL,
    especialidad  VARCHAR(60),
    telefono      VARCHAR(20),
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_mecanico PRIMARY KEY (id_mecanico),
    CONSTRAINT ck_mecanico_especialidad
        CHECK (especialidad IN ('bicicletas', 'motos', 'ambos'))   -- el taller atiende solo esos dos tipos
);

-- ---------------------------------------------------------------------
-- CLIENTE
-- ---------------------------------------------------------------------
CREATE TABLE cliente (
    id_cliente  INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre      VARCHAR(120) NOT NULL,
    telefono    VARCHAR(20)  NOT NULL,      -- único dato obligatorio de contacto (avisos por llamada/WhatsApp)
    email       VARCHAR(150),
    direccion   VARCHAR(200),
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente)
);

-- ---------------------------------------------------------------------
-- REPUESTO: catálogo e inventario.
-- ---------------------------------------------------------------------
CREATE TABLE repuesto (
    id_repuesto      INTEGER GENERATED ALWAYS AS IDENTITY,
    nombre           VARCHAR(120)  NOT NULL,
    descripcion      VARCHAR(250),
    stock_actual     INTEGER       NOT NULL DEFAULT 0,
    stock_minimo     INTEGER       NOT NULL DEFAULT 0,
    precio_unitario  NUMERIC(10,2) NOT NULL,           -- dinero siempre en NUMERIC, nunca FLOAT
    CONSTRAINT pk_repuesto PRIMARY KEY (id_repuesto),
    CONSTRAINT uq_repuesto_nombre        UNIQUE (nombre),
    CONSTRAINT ck_repuesto_stock_no_negativo CHECK (stock_actual >= 0),   -- regla S-05: nunca stock negativo
    CONSTRAINT ck_repuesto_stock_minimo      CHECK (stock_minimo >= 0),
    CONSTRAINT ck_repuesto_precio            CHECK (precio_unitario >= 0)
);
