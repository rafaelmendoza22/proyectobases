-- =====================================================================
-- migrations/002_vehiculos_y_citas.sql · AutoRueda Taller Técnico · Entrega 2
-- VEHICULO con su especialización disjunta (BICICLETA / MOTOCICLETA) y CITA.
-- =====================================================================

-- ---------------------------------------------------------------------
-- VEHICULO (supertipo). tipo es el discriminador de la especialización.
-- ON DELETE RESTRICT hacia CLIENTE: no se borra un cliente que tenga vehículos
-- (se perdería a quién se le hizo cada reparación).
-- ---------------------------------------------------------------------
CREATE TABLE vehiculo (
    id_vehiculo    INTEGER GENERATED ALWAYS AS IDENTITY,
    tipo           VARCHAR(10) NOT NULL,
    marca          VARCHAR(60) NOT NULL,
    modelo         VARCHAR(60),
    placa_o_serie  VARCHAR(30),                -- opcional: hay bicicletas viejas sin serie conocida
    anio           SMALLINT,
    id_cliente     INTEGER     NOT NULL,
    CONSTRAINT pk_vehiculo PRIMARY KEY (id_vehiculo),
    CONSTRAINT fk_vehiculo_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente) ON DELETE RESTRICT,
    CONSTRAINT ck_vehiculo_tipo CHECK (tipo IN ('bicicleta', 'moto')),
    CONSTRAINT ck_vehiculo_anio CHECK (anio >= 1900),
    CONSTRAINT uq_vehiculo_placa_serie UNIQUE (placa_o_serie),   -- permite varios NULL, no repetidos
    CONSTRAINT uq_vehiculo_id_tipo UNIQUE (id_vehiculo, tipo)    -- permite a los subtipos referenciar (id, tipo)
);

-- ---------------------------------------------------------------------
-- Subtipos. La FK compuesta (id_vehiculo, tipo) + el CHECK sobre tipo garantizan la
-- especialización DISJUNTA: un vehículo 'moto' no puede aparecer en BICICLETA y viceversa.
-- CASCADE: el subtipo no tiene sentido sin su vehículo.
-- ---------------------------------------------------------------------
CREATE TABLE bicicleta (
    id_vehiculo     INTEGER     NOT NULL,
    tipo            VARCHAR(10) NOT NULL DEFAULT 'bicicleta',
    tipo_bicicleta  VARCHAR(30) NOT NULL,
    num_cambios     SMALLINT    NOT NULL,
    tipo_frenos     VARCHAR(30) NOT NULL,
    CONSTRAINT pk_bicicleta PRIMARY KEY (id_vehiculo),
    CONSTRAINT fk_bicicleta_vehiculo FOREIGN KEY (id_vehiculo, tipo)
        REFERENCES vehiculo (id_vehiculo, tipo) ON DELETE CASCADE,
    CONSTRAINT ck_bicicleta_tipo    CHECK (tipo = 'bicicleta'),
    CONSTRAINT ck_bicicleta_cambios CHECK (num_cambios >= 1)
);

CREATE TABLE motocicleta (
    id_vehiculo       INTEGER     NOT NULL,
    tipo              VARCHAR(10) NOT NULL DEFAULT 'moto',
    cilindraje        SMALLINT    NOT NULL,
    num_motor         VARCHAR(30) NOT NULL,
    tipo_combustible  VARCHAR(20) NOT NULL,
    CONSTRAINT pk_motocicleta PRIMARY KEY (id_vehiculo),
    CONSTRAINT fk_motocicleta_vehiculo FOREIGN KEY (id_vehiculo, tipo)
        REFERENCES vehiculo (id_vehiculo, tipo) ON DELETE CASCADE,
    CONSTRAINT ck_motocicleta_tipo       CHECK (tipo = 'moto'),
    CONSTRAINT ck_motocicleta_cilindraje CHECK (cilindraje > 0),
    CONSTRAINT uq_motocicleta_num_motor  UNIQUE (num_motor)
);

-- ---------------------------------------------------------------------
-- CITA. Las dos FK son RESTRICT: protegen la agenda histórica.
-- La regla "un mecánico no puede tener dos citas solapadas" se declara con EXCLUDE
-- (un CHECK no puede comparar filas distintas).
-- ---------------------------------------------------------------------
CREATE TABLE cita (
    id_cita      INTEGER GENERATED ALWAYS AS IDENTITY,
    fecha        DATE        NOT NULL,
    hora_inicio  TIME        NOT NULL,
    hora_fin     TIME        NOT NULL,
    motivo       VARCHAR(200),
    id_mecanico  INTEGER     NOT NULL,
    id_vehiculo  INTEGER     NOT NULL,
    CONSTRAINT pk_cita PRIMARY KEY (id_cita),
    CONSTRAINT fk_cita_mecanico FOREIGN KEY (id_mecanico)
        REFERENCES mecanico (id_mecanico) ON DELETE RESTRICT,
    CONSTRAINT fk_cita_vehiculo FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo) ON DELETE RESTRICT,
    CONSTRAINT ck_cita_horas CHECK (hora_fin > hora_inicio),   -- también garantiza que la cita no cruce de día (S-07)
    CONSTRAINT ex_cita_sin_solape_mecanico
        EXCLUDE USING gist (
            id_mecanico WITH =,
            tsrange(fecha + hora_inicio, fecha + hora_fin) WITH &&
        )
);
