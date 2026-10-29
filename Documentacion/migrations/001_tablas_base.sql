create table proveedor (
    id_proveedor integer generated always as identity,
    nit varchar(20) not null,
    razon_social varchar(120) not null,
    direccion varchar(200),
    telefono varchar(20),
    correo varchar(150),
    activo boolean not null default true,
    constraint pk_proveedor primary key (id_proveedor),
    constraint uq_proveedor_nit unique (nit)
);

create table mecanico (
    id_mecanico integer generated always as identity,
    nombre varchar(120) not null,
    especialidad varchar(60),
    telefono varchar(20),
    activo boolean not null default true,
    constraint pk_mecanico primary key (id_mecanico),
    constraint ck_mecanico_especialidad
        check (especialidad in ('bicicletas', 'motos', 'ambos'))
);

create table cliente (
    id_cliente integer generated always as identity,
    nombre varchar(120) not null,
    telefono varchar(20) not null,
    email varchar(150),
    direccion varchar(200),
    constraint pk_cliente primary key (id_cliente)
);

create table repuesto (
    id_repuesto integer generated always as identity,
    nombre varchar(120) not null,
    descripcion varchar(250),
    stock_actual integer not null default 0,
    stock_minimo integer not null default 0,
    precio_unitario numeric(10,2) not null,
    constraint pk_repuesto primary key (id_repuesto),
    constraint uq_repuesto_nombre unique (nombre),
    constraint ck_repuesto_stock_no_negativo check (stock_actual >= 0),
    constraint ck_repuesto_stock_minimo check (stock_minimo >= 0),
    constraint ck_repuesto_precio check (precio_unitario >= 0)
);