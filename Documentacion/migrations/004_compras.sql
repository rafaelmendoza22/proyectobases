create table compra (
    id_compra integer generated always as identity,
    fecha_compra date not null,
    estado varchar(10) not null default 'pendiente',
    id_proveedor integer not null,
    constraint pk_compra primary key (id_compra),
    constraint fk_compra_proveedor foreign key (id_proveedor)
        references proveedor (id_proveedor) on delete restrict,
    constraint ck_compra_estado check (estado in ('pendiente', 'recibida', 'cancelada'))
);

create table detalle_compra (
    id_compra integer not null,
    id_repuesto integer not null,
    cantidad integer not null,
    costo_unitario numeric(10,2) not null,
    constraint pk_detalle_compra primary key (id_compra, id_repuesto),
    constraint fk_detalle_compra_compra foreign key (id_compra)
        references compra (id_compra) on delete cascade,
    constraint fk_detalle_compra_repuesto foreign key (id_repuesto)
        references repuesto (id_repuesto) on delete restrict,
    constraint ck_detalle_compra_cantidad check (cantidad > 0),
    constraint ck_detalle_compra_costo check (costo_unitario >= 0)
);