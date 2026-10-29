create view v_compra_total as
select c.id_compra,
       coalesce(sum(d.cantidad * d.costo_unitario), 0) as total
from compra c
left join detalle_compra d on d.id_compra = c.id_compra
group by c.id_compra;

create view v_garantia_vigencia as
select id_garantia,
       id_orden,
       fecha_inicio,
       dias_cobertura,
       fecha_inicio + dias_cobertura as fecha_vencimiento
from garantia;