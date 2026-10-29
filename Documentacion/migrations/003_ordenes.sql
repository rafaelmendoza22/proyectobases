create table orden_servicio (
    id_orden integer generated always as identity,
    fecha_recepcion timestamp not null default current_timestamp,
    fecha_entrega timestamp,
    estado varchar(15) not null default 'recibido',
    id_vehiculo integer not null,
    id_mecanico integer not null,
    id_cita integer,
    constraint pk_orden_servicio primary key (id_orden),
    constraint fk_orden_vehiculo foreign key (id_vehiculo)
        references vehiculo (id_vehiculo) on delete restrict,
    constraint fk_orden_mecanico foreign key (id_mecanico)
        references mecanico (id_mecanico) on delete restrict,
    constraint fk_orden_cita foreign key (id_cita)
        references cita (id_cita) on delete set null,
    constraint uq_orden_cita unique (id_cita),
    constraint ck_orden_estado
        check (estado in ('recibido', 'en_reparacion', 'listo', 'entregado')),
    constraint ck_orden_fechas
        check (fecha_entrega is null or fecha_entrega >= fecha_recepcion),
    constraint ck_orden_entrega_coherente
        check ((estado = 'entregado') = (fecha_entrega is not null))
);

create table detalle_orden_repuesto (
    id_orden integer not null,
    id_repuesto integer not null,
    cantidad integer not null,
    precio_unitario_aplicado numeric(10,2) not null,
    constraint pk_detalle_orden_repuesto primary key (id_orden, id_repuesto),
    constraint fk_detalle_orden_orden foreign key (id_orden)
        references orden_servicio (id_orden) on delete cascade,
    constraint fk_detalle_orden_repuesto foreign key (id_repuesto)
        references repuesto (id_repuesto) on delete restrict,
    constraint ck_detalle_orden_cantidad check (cantidad > 0),
    constraint ck_detalle_orden_precio check (precio_unitario_aplicado >= 0)
);

create table historial_estado (
    id_historial integer generated always as identity,
    id_orden integer not null,
    id_mecanico integer,
    estado_anterior varchar(15),
    estado_nuevo varchar(15) not null,
    fecha_cambio timestamp not null default current_timestamp,
    constraint pk_historial_estado primary key (id_historial),
    constraint fk_historial_orden foreign key (id_orden)
        references orden_servicio (id_orden) on delete cascade,
    constraint fk_historial_mecanico foreign key (id_mecanico)
        references mecanico (id_mecanico) on delete set null,
    constraint uq_historial_orden_fecha unique (id_orden, fecha_cambio),
    constraint ck_historial_estado_nuevo
        check (estado_nuevo in ('recibido', 'en_reparacion', 'listo', 'entregado')),
    constraint ck_historial_estado_anterior
        check (estado_anterior is null
               or estado_anterior in ('recibido', 'en_reparacion', 'listo', 'entregado')),
    constraint ck_historial_cambio_real check (estado_anterior is distinct from estado_nuevo)
);

create table garantia (
    id_garantia integer generated always as identity,
    condiciones varchar(250) not null,
    dias_cobertura integer not null,
    fecha_inicio date not null,
    id_orden integer not null,
    constraint pk_garantia primary key (id_garantia),
    constraint fk_garantia_orden foreign key (id_orden)
        references orden_servicio (id_orden) on delete restrict,
    constraint ck_garantia_dias check (dias_cobertura > 0)
);

create table alertas_stock (
    id_alerta integer generated always as identity,
    fecha_alerta timestamp not null default current_timestamp,
    stock_registrado integer not null,
    estado varchar(10) not null default 'activa',
    id_repuesto integer not null,
    constraint pk_alertas_stock primary key (id_alerta),
    constraint fk_alertas_repuesto foreign key (id_repuesto)
        references repuesto (id_repuesto) on delete cascade,
    constraint ck_alertas_stock_registrado check (stock_registrado >= 0),
    constraint ck_alertas_estado check (estado in ('activa', 'atendida'))
);