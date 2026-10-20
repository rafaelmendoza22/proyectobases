# 07. Banco de Consultas — AutoRueda Taller Técnico

> Consultas en SQL (PostgreSQL 16+) sobre el esquema de `04_esquema_relacional.md`, con los nombres de tabla y columna de `05_diccionario_datos.md` y `06_normalizacion.md`. Cada consulta indica la **pregunta de negocio** que responde, qué tablas usa y qué devuelve.
>
> Las consultas 6 y 8 usan las vistas `v_compra_total` y `v_garantia_vigencia` definidas en la sección 3 de `06_normalizacion.md`.

## Índice

| # | Pregunta de negocio | Técnica principal |
|---|---|---|
| 1 | ¿Cuántas órdenes de motos están actualmente en reparación? | `JOIN` + filtro |
| 2 | ¿Qué repuestos están por debajo del stock mínimo? | filtro entre columnas |
| 3 | ¿Qué mecánico tiene mayor carga de trabajo? | `LEFT JOIN` + `COUNT` |
| 4 | ¿Cuáles son los repuestos más utilizados? | `SUM` + `GROUP BY` |
| 5 | ¿Cuántas órdenes hay en cada estado? | `GROUP BY` |
| 6 | ¿Cuánto se ha comprado a cada proveedor? | vista + `JOIN` |
| 7 | ¿Hay mecánicos con citas solapadas? | autojoin |
| 8 | ¿Qué garantías están vigentes hoy y de quién son? | vista + `JOIN` |
| 9 | ¿Cuánto costó en repuestos cada orden entregada? | agregación sobre el precio histórico |
| 10 | ¿Cuánto tarda en promedio la entrega según el tipo de vehículo? | `AVG` sobre intervalos |

---

## Consulta 1 — Motos actualmente en reparación

**Pregunta:** ¿Cuántas órdenes de motocicletas están en reparación en este momento, y de qué clientes son?

**Tablas:** `orden_servicio`, `vehiculo`, `cliente`.

```sql
SELECT o.id_orden,
       c.nombre       AS cliente,
       v.marca,
       v.modelo,
       v.placa_o_serie,
       o.fecha_recepcion
FROM orden_servicio o
JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo
JOIN cliente  c ON c.id_cliente  = v.id_cliente
WHERE v.tipo   = 'moto'
  AND o.estado = 'en_reparacion'
ORDER BY o.fecha_recepcion;
```

**Resultado:** una fila por orden. Si solo se quiere el número, se cambia el `SELECT` por `COUNT(*)`.

---

## Consulta 2 — Repuestos por debajo del stock mínimo

**Pregunta:** ¿Qué repuestos hay que reponer porque su stock actual cayó por debajo del mínimo establecido?

**Tablas:** `repuesto`.

```sql
SELECT id_repuesto,
       nombre,
       stock_actual,
       stock_minimo,
       stock_minimo - stock_actual AS faltante
FROM repuesto
WHERE stock_actual < stock_minimo
ORDER BY faltante DESC;
```

**Resultado:** los repuestos más urgentes primero, con la cantidad que falta para llegar al mínimo.

---

## Consulta 3 — Carga de trabajo por mecánico

**Pregunta:** ¿Cuántas órdenes abiertas (recibidas o en reparación) tiene cada mecánico activo? Sirve para repartir mejor el trabajo.

**Tablas:** `mecanico`, `orden_servicio`.

```sql
SELECT m.id_mecanico,
       m.nombre,
       m.especialidad,
       COUNT(o.id_orden) AS ordenes_abiertas
FROM mecanico m
LEFT JOIN orden_servicio o
       ON o.id_mecanico = m.id_mecanico
      AND o.estado IN ('recibido', 'en_reparacion')
WHERE m.activo = TRUE
GROUP BY m.id_mecanico, m.nombre, m.especialidad
ORDER BY ordenes_abiertas DESC, m.nombre;
```

**Nota de diseño:** se usa `LEFT JOIN` con el filtro de estado dentro del `ON` (y no en el `WHERE`) para que los mecánicos sin órdenes abiertas también aparezcan, con 0.

---

## Consulta 4 — Repuestos más utilizados

**Pregunta:** ¿Qué repuestos se han usado más en las órdenes de servicio? Ayuda a decidir qué conviene tener siempre en inventario.

**Tablas:** `detalle_orden_repuesto`, `repuesto`.

```sql
SELECT r.id_repuesto,
       r.nombre,
       SUM(d.cantidad)         AS unidades_usadas,
       COUNT(DISTINCT d.id_orden) AS ordenes_distintas
FROM detalle_orden_repuesto d
JOIN repuesto r ON r.id_repuesto = d.id_repuesto
GROUP BY r.id_repuesto, r.nombre
ORDER BY unidades_usadas DESC
LIMIT 10;
```

**Resultado:** el top 10 de repuestos por unidades consumidas.

---

## Consulta 5 — Órdenes por estado

**Pregunta:** ¿Cuántas órdenes hay en cada estado del flujo `recibido → en_reparacion → listo → entregado`?

**Tablas:** `orden_servicio`.

```sql
SELECT estado,
       COUNT(*) AS total_ordenes
FROM orden_servicio
GROUP BY estado
ORDER BY CASE estado
           WHEN 'recibido'      THEN 1
           WHEN 'en_reparacion' THEN 2
           WHEN 'listo'         THEN 3
           WHEN 'entregado'     THEN 4
         END;
```

**Resultado:** un resumen del taller de un vistazo, ordenado según el flujo y no alfabéticamente.

---

## Consulta 6 — Total comprado a cada proveedor

**Pregunta:** ¿Cuánto dinero se ha gastado en compras con cada proveedor?

**Tablas:** `proveedor`, `compra`, vista `v_compra_total`.

```sql
SELECT p.id_proveedor,
       p.razon_social,
       COUNT(c.id_compra)          AS num_compras,
       COALESCE(SUM(t.total), 0)   AS total_comprado
FROM proveedor p
LEFT JOIN compra c         ON c.id_proveedor = p.id_proveedor
LEFT JOIN v_compra_total t ON t.id_compra    = c.id_compra
GROUP BY p.id_proveedor, p.razon_social
ORDER BY total_comprado DESC;
```

**Nota de diseño:** `compra.total` no existe como columna porque es un atributo derivado (ver `06_normalizacion.md`); se obtiene desde la vista. `COALESCE` evita `NULL` en proveedores sin compras.

---

## Consulta 7 — Citas solapadas de un mismo mecánico

**Pregunta:** ¿Existen citas que se traslapan para el mismo mecánico? Esta consulta sirve para **verificar** la regla de no solapamiento; si las restricciones funcionan, debe devolver 0 filas.

**Tablas:** `cita` (consigo misma).

```sql
SELECT c1.id_mecanico,
       c1.id_cita AS cita_a,
       c2.id_cita AS cita_b,
       c1.fecha,
       c1.hora_inicio AS inicio_a, c1.hora_fin AS fin_a,
       c2.hora_inicio AS inicio_b, c2.hora_fin AS fin_b
FROM cita c1
JOIN cita c2
  ON  c1.id_mecanico = c2.id_mecanico
  AND c1.fecha       = c2.fecha
  AND c1.id_cita     < c2.id_cita          -- evita duplicar el par (A,B) y (B,A)
  AND c1.hora_inicio < c2.hora_fin         -- dos intervalos se solapan si
  AND c2.hora_inicio < c1.hora_fin;        -- cada uno empieza antes de que termine el otro
```

**Resultado esperado:** vacío. Cualquier fila indica una violación de la regla de negocio del problema 3 del planteamiento (choques de agenda).

---

## Consulta 8 — Garantías vigentes hoy

**Pregunta:** ¿Qué garantías siguen vigentes a la fecha actual, a qué cliente y vehículo pertenecen, y cuándo vencen?

**Tablas:** vista `v_garantia_vigencia`, `orden_servicio`, `vehiculo`, `cliente`.

```sql
SELECT g.id_garantia,
       c.nombre            AS cliente,
       v.marca,
       v.modelo,
       g.fecha_inicio,
       g.fecha_vencimiento,
       g.fecha_vencimiento - CURRENT_DATE AS dias_restantes
FROM v_garantia_vigencia g
JOIN orden_servicio o ON o.id_orden    = g.id_orden
JOIN vehiculo v       ON v.id_vehiculo = o.id_vehiculo
JOIN cliente  c       ON c.id_cliente  = v.id_cliente
WHERE CURRENT_DATE BETWEEN g.fecha_inicio AND g.fecha_vencimiento
ORDER BY g.fecha_vencimiento;
```

**Nota de diseño:** `fecha_vencimiento` es derivado (`fecha_inicio + dias_cobertura`) y no se almacena para respetar la 3FN.

---

## Consulta 9 — Costo en repuestos por orden entregada

**Pregunta:** ¿Cuánto se cobró en repuestos en cada orden ya entregada? Usa el **precio histórico** cobrado en su momento, no el precio actual del catálogo.

**Tablas:** `orden_servicio`, `detalle_orden_repuesto`.

```sql
SELECT o.id_orden,
       o.fecha_entrega::date AS fecha_entrega,
       SUM(d.cantidad)       AS unidades,
       SUM(d.cantidad * d.precio_unitario_aplicado) AS total_repuestos
FROM orden_servicio o
JOIN detalle_orden_repuesto d ON d.id_orden = o.id_orden
WHERE o.estado = 'entregado'
GROUP BY o.id_orden, o.fecha_entrega
ORDER BY o.fecha_entrega DESC;
```

**Resultado:** el total por orden no cambia aunque luego suba o baje `repuesto.precio_unitario`, que es justo el propósito de `precio_unitario_aplicado`.

---

## Consulta 10 — Tiempo promedio de entrega por tipo de vehículo

**Pregunta:** ¿Cuánto tarda en promedio el taller entre recibir y entregar un vehículo, separando bicicletas de motos?

**Tablas:** `orden_servicio`, `vehiculo`.

```sql
SELECT v.tipo,
       COUNT(*) AS ordenes_entregadas,
       ROUND(AVG(EXTRACT(EPOCH FROM (o.fecha_entrega - o.fecha_recepcion)) / 86400)::numeric, 2)
           AS dias_promedio
FROM orden_servicio o
JOIN vehiculo v ON v.id_vehiculo = o.id_vehiculo
WHERE o.estado = 'entregado'
  AND o.fecha_entrega IS NOT NULL
GROUP BY v.tipo
ORDER BY dias_promedio DESC;
```

**Resultado:** días promedio (con decimales) por tipo. Sirve para ver si las motos, que suelen ser más urgentes, realmente salen más rápido.

---

## Resumen

| Tipo de pregunta | Consultas |
|---|---|
| Operación diaria | 1, 3, 5 |
| Inventario y compras | 2, 4, 6 |
| Integridad de reglas de negocio | 7 |
| Garantías e historial económico | 8, 9 |
| Indicadores de desempeño | 10 |

*Las consultas se probarán contra datos de ejemplo cuando el DDL y el script de inserción estén implementados (Entrega 2), y se ajustarán si algún nombre de columna cambia.*
