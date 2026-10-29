create index idx_vehiculo_cliente on vehiculo (id_cliente);
create index idx_orden_vehiculo on orden_servicio (id_vehiculo);
create index idx_detalle_repuesto on detalle_orden_repuesto (id_repuesto);
create index idx_orden_mecanico_fecha on orden_servicio (id_mecanico, fecha_recepcion);
create index idx_orden_activas on orden_servicio (fecha_recepcion)
    where estado <> 'entregado';

create index idx_cita_mecanico on cita (id_mecanico);
create index idx_cita_vehiculo on cita (id_vehiculo);
create index idx_compra_proveedor on compra (id_proveedor);
create index idx_detalle_compra_repuesto on detalle_compra (id_repuesto);
create index idx_garantia_orden on garantia (id_orden);
create index idx_historial_mecanico on historial_estado (id_mecanico);
create index idx_alertas_repuesto on alertas_stock (id_repuesto);