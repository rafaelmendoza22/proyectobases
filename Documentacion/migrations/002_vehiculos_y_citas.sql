create table vehiculo (
    id_vehiculo integer generated always as identity,
    tipo varchar(10) not null,
    marca varchar(60) not null,
    modelo varchar(60),
    placa_o_serie varchar(30),
    anio smallint,
    id_cliente integer not null,
    constraint pk_vehiculo primary key (id_vehiculo),
    constraint fk_vehiculo_cliente foreign key (id_cliente)
        references cliente (id_cliente) on delete restrict,
    constraint ck_vehiculo_tipo check (tipo in ('bicicleta', 'moto')),
    constraint ck_vehiculo_anio check (anio >= 1900),
    constraint uq_vehiculo_placa_serie unique (placa_o_serie),
    constraint uq_vehiculo_id_tipo unique (id_vehiculo, tipo)
);

create table bicicleta (
    id_vehiculo integer not null,
    tipo varchar(10) not null default 'bicicleta',
    tipo_bicicleta varchar(30) not null,
    num_cambios smallint not null,
    tipo_frenos varchar(30) not null,
    constraint pk_bicicleta primary key (id_vehiculo),
    constraint fk_bicicleta_vehiculo foreign key (id_vehiculo, tipo)
        references vehiculo (id_vehiculo, tipo) on delete cascade,
    constraint ck_bicicleta_tipo check (tipo = 'bicicleta'),
    constraint ck_bicicleta_cambios check (num_cambios >= 1)
);

create table motocicleta (
    id_vehiculo integer not null,
    tipo varchar(10) not null default 'moto',
    cilindraje smallint not null,
    num_motor varchar(30) not null,
    tipo_combustible varchar(20) not null,
    constraint pk_motocicleta primary key (id_vehiculo),
    constraint fk_motocicleta_vehiculo foreign key (id_vehiculo, tipo)
        references vehiculo (id_vehiculo, tipo) on delete cascade,
    constraint ck_motocicleta_tipo check (tipo = 'moto'),
    constraint ck_motocicleta_cilindraje check (cilindraje > 0),
    constraint uq_motocicleta_num_motor unique (num_motor)
);

create table cita (
    id_cita integer generated always as identity,
    fecha date not null,
    hora_inicio time not null,
    hora_fin time not null,
    motivo varchar(200),
    id_mecanico integer not null,
    id_vehiculo integer not null,
    constraint pk_cita primary key (id_cita),
    constraint fk_cita_mecanico foreign key (id_mecanico)
        references mecanico (id_mecanico) on delete restrict,
    constraint fk_cita_vehiculo foreign key (id_vehiculo)
        references vehiculo (id_vehiculo) on delete restrict,
    constraint ck_cita_horas check (hora_fin > hora_inicio)
);