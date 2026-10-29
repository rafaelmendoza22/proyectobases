update repuesto set stock_actual = -5 where id_repuesto = 1;

insert into orden_servicio (estado, id_vehiculo, id_mecanico) values ('cancelado', 1, 1);

delete from cliente where id_cliente = 1;

delete from mecanico where id_mecanico = 1;

insert into bicicleta (id_vehiculo, tipo_bicicleta, num_cambios, tipo_frenos)
select id_vehiculo, 'urbana', 7, 'V-brake' from vehiculo where tipo = 'moto' limit 1;

insert into detalle_orden_repuesto (id_orden, id_repuesto, cantidad, precio_unitario_aplicado)
values (1, 299, 0, 1000);

begin;
select id_orden, id_cita from orden_servicio order by id_orden limit 3;
delete from cita where id_cita = (select id_cita from orden_servicio where id_cita is not null order by id_orden limit 1);
select id_orden, id_cita from orden_servicio order by id_orden limit 3;
rollback;

begin;
select count(*) as lineas_antes from detalle_orden_repuesto where id_orden = 2;
delete from orden_servicio where id_orden = 2;
select count(*) as lineas_despues from detalle_orden_repuesto where id_orden = 2;
rollback;