# 08. Índices con evidencia — AutoRueda Taller Técnico

## 1. Cómo se midió

- **Motor:** PostgreSQL 16 en una base local, con el esquema de las 15 tablas del EER y la semilla `seed/01_semilla.sql` (≈ 20.000 órdenes, 59.556 líneas de repuestos, 3.000 vehículos, 2.000 clientes).
- **Antes:** solo los índices que PostgreSQL crea solo (PK, UNIQUE y, si existe, el `EXCLUDE` de citas). **Ninguna FK indexada.**
- **Método por caso:** `ANALYZE` → `EXPLAIN (ANALYZE, BUFFERS)` → crear el índice → `ANALYZE` → mismo `EXPLAIN`. Cada medición se ejecutó dos veces y se reporta la segunda (caché caliente) con `SET jit = off`.
- Los milisegundos son de una máquina de pruebas y **cambian de equipo en equipo**; lo que importa es el tipo de plan y las páginas leídas (*Buffers*).
- Los índices están en `migrations/005_indices.sql` (se aplica después de las migraciones de tablas).

## 2. Resumen

| # | Caso | Tipo de índice | Plan antes | Plan después | Tiempo | Páginas leídas |
|---|------|----------------|-----------|--------------|--------|----------------|
| 1 | Historial de órdenes de un cliente | FK en join (2 índices) | Seq Scan | Bitmap Index Scan | 3.31 → 0.169 ms | 219 → 57 |
| 2 | Órdenes que usaron un repuesto | FK fuera de la PK compuesta | Seq Scan | Bitmap Index Scan | 4.12 → 2.4 ms | 566 → 322 |
| 3 | Órdenes de un mecánico en un rango de fechas | Compuesto (igualdad + rango) | Seq Scan | Bitmap Index Scan | 1.06 → 0.163 ms | 189 → 72 |
| 4 | Órdenes activas, tablero del taller | Parcial | Seq Scan | Bitmap Index Scan | 1.13 → 0.402 ms | 189 → 180 |
| 5 | Caso negativo: índice sobre una columna de baja selectividad | B-tree sobre `estado` (descartado) | Seq Scan | Seq Scan (no usa el índice) | 2.08 → 2.14 ms | 186 → 186 |

## 3. Casos en detalle

### Caso 1: Historial de órdenes de un cliente (join de 3 tablas)

**Pregunta de negocio:** ¿Qué órdenes de servicio ha tenido el cliente 2, de la más reciente a la más antigua?  
**Filas devueltas:** 42

**Consulta:**
```sql
SELECT o.id_orden, o.fecha_recepcion, o.estado, v.tipo, v.placa_o_serie
FROM cliente c
JOIN vehiculo v        ON v.id_cliente  = c.id_cliente
JOIN orden_servicio o  ON o.id_vehiculo = v.id_vehiculo
WHERE c.id_cliente = 2
ORDER BY o.fecha_recepcion DESC;
```

**Plan antes** (sin el índice):
```
Sort  (cost=508.04..508.09 rows=20 width=35) (actual time=3.252..3.257 rows=42 loops=1)
  Sort Key: o.fecha_recepcion DESC
  Sort Method: quicksort  Memory: 27kB
  Buffers: shared hit=219
  ->  Nested Loop  (cost=64.81..507.61 rows=20 width=35) (actual time=0.283..3.220 rows=42 loops=1)
        Buffers: shared hit=216
        ->  Index Only Scan using cliente_pkey on cliente c  (cost=0.28..4.29 rows=1 width=4) (actual time=0.014..0.016 rows=1 loops=1)
              Index Cond: (id_cliente = 2)
              Heap Fetches: 0
              Buffers: shared hit=3
        ->  Hash Join  (cost=64.54..503.12 rows=20 width=39) (actual time=0.267..3.197 rows=42 loops=1)
              Hash Cond: (o.id_vehiculo = v.id_vehiculo)
              Buffers: shared hit=213
              ->  Seq Scan on orden_servicio o  (cost=0.00..386.00 rows=20000 width=25) (actual time=0.005..1.270 rows=20000 loops=1)
                    Buffers: shared hit=186
              ->  Hash  (cost=64.50..64.50 rows=3 width=22) (actual time=0.225..0.226 rows=3 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 9kB
                    Buffers: shared hit=27
                    ->  Seq Scan on vehiculo v  (cost=0.00..64.50 rows=3 width=22) (actual time=0.005..0.219 rows=3 loops=1)
                          Filter: (id_cliente = 2)
                          Rows Removed by Filter: 2997
                          Buffers: shared hit=27
Planning:
  Buffers: shared hit=274
Planning Time: 0.616 ms
Execution Time: 3.310 ms
```

**Índice:**
```sql
CREATE INDEX idx_vehiculo_cliente ON vehiculo (id_cliente);
CREATE INDEX idx_orden_vehiculo ON orden_servicio (id_vehiculo);
```

**Plan después:**
```
Sort  (cost=103.37..103.42 rows=20 width=35) (actual time=0.118..0.120 rows=42 loops=1)
  Sort Key: o.fecha_recepcion DESC
  Sort Method: quicksort  Memory: 27kB
  Buffers: shared hit=57
  ->  Nested Loop  (cost=8.92..102.94 rows=20 width=35) (actual time=0.029..0.097 rows=42 loops=1)
        Buffers: shared hit=54
        ->  Nested Loop  (cost=4.58..17.67 rows=3 width=18) (actual time=0.018..0.022 rows=3 loops=1)
              Buffers: shared hit=8
              ->  Index Only Scan using cliente_pkey on cliente c  (cost=0.28..4.29 rows=1 width=4) (actual time=0.008..0.008 rows=1 loops=1)
                    Index Cond: (id_cliente = 2)
                    Heap Fetches: 0
                    Buffers: shared hit=3
              ->  Bitmap Heap Scan on vehiculo v  (cost=4.30..13.34 rows=3 width=22) (actual time=0.008..0.012 rows=3 loops=1)
                    Recheck Cond: (id_cliente = 2)
                    Heap Blocks: exact=3
                    Buffers: shared hit=5
                    ->  Bitmap Index Scan on idx_vehiculo_cliente  (cost=0.00..4.30 rows=3 width=0) (actual time=0.005..0.005 rows=3 loops=1)
                          Index Cond: (id_cliente = 2)
                          Buffers: shared hit=2
        ->  Bitmap Heap Scan on orden_servicio o  (cost=4.34..28.36 rows=7 width=25) (actual time=0.006..0.023 rows=14 loops=3)
              Recheck Cond: (v.id_vehiculo = id_vehiculo)
              Heap Blocks: exact=40
              Buffers: shared hit=46
              ->  Bitmap Index Scan on idx_orden_vehiculo  (cost=0.00..4.34 rows=7 width=0) (actual time=0.002..0.002 rows=14 loops=3)
                    Index Cond: (id_vehiculo = v.id_vehiculo)
                    Buffers: shared hit=6
Planning:
  Buffers: shared hit=306
Planning Time: 0.427 ms
Execution Time: 0.169 ms
```

**Tamaño del índice:** idx_vehiculo_cliente: 80 kB, idx_orden_vehiculo: 224 kB

**Conclusión:** Sin índices, el plan recorre completas `vehiculo` (3.000 filas) y `orden_servicio` (20.000) y descarta casi todo. Con `idx_vehiculo_cliente` e `idx_orden_vehiculo` pasa a dos *Bitmap Index Scan*: baja de 3.31 ms a 0.169 ms y de 219 a 57 páginas leídas. Estas dos FK son el camino de casi todo "historial de un cliente", así que se quedan.

### Caso 2: Órdenes que usaron un repuesto (FK fuera de la PK compuesta)

**Pregunta de negocio:** ¿En qué órdenes se usó el repuesto 15 y cuántas unidades?  
**Filas devueltas:** 163

**Consulta:**
```sql
SELECT o.id_orden, o.fecha_recepcion, d.cantidad, d.precio_unitario_aplicado
FROM detalle_orden_repuesto d
JOIN orden_servicio o ON o.id_orden = d.id_orden
WHERE d.id_repuesto = 15;
```

**Plan antes** (sin el índice):
```
Hash Join  (cost=1126.75..1565.26 rows=184 width=22) (actual time=2.000..4.080 rows=163 loops=1)
  Hash Cond: (o.id_orden = d.id_orden)
  Buffers: shared hit=566
  ->  Seq Scan on orden_servicio o  (cost=0.00..386.00 rows=20000 width=12) (actual time=0.002..0.932 rows=20000 loops=1)
        Buffers: shared hit=186
  ->  Hash  (cost=1124.45..1124.45 rows=184 width=14) (actual time=1.969..1.970 rows=163 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 16kB
        Buffers: shared hit=380
        ->  Seq Scan on detalle_orden_repuesto d  (cost=0.00..1124.45 rows=184 width=14) (actual time=0.023..1.944 rows=163 loops=1)
              Filter: (id_repuesto = 15)
              Rows Removed by Filter: 59393
              Buffers: shared hit=380
Planning:
  Buffers: shared hit=228
Planning Time: 0.385 ms
Execution Time: 4.117 ms
```

**Índice:**
```sql
CREATE INDEX idx_detalle_repuesto ON detalle_orden_repuesto (id_repuesto);
```

**Plan después:**
```
Hash Join  (cost=323.96..762.47 rows=182 width=22) (actual time=0.242..2.355 rows=163 loops=1)
  Hash Cond: (o.id_orden = d.id_orden)
  Buffers: shared hit=322
  ->  Seq Scan on orden_servicio o  (cost=0.00..386.00 rows=20000 width=12) (actual time=0.002..0.956 rows=20000 loops=1)
        Buffers: shared hit=186
  ->  Hash  (cost=321.69..321.69 rows=182 width=14) (actual time=0.211..0.212 rows=163 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 16kB
        Buffers: shared hit=136
        ->  Bitmap Heap Scan on detalle_orden_repuesto d  (cost=5.70..321.69 rows=182 width=14) (actual time=0.025..0.190 rows=163 loops=1)
              Recheck Cond: (id_repuesto = 15)
              Heap Blocks: exact=134
              Buffers: shared hit=136
              ->  Bitmap Index Scan on idx_detalle_repuesto  (cost=0.00..5.66 rows=182 width=0) (actual time=0.012..0.012 rows=163 loops=1)
                    Index Cond: (id_repuesto = 15)
                    Buffers: shared hit=2
Planning:
  Buffers: shared hit=240
Planning Time: 0.425 ms
Execution Time: 2.402 ms
```

**Tamaño del índice:** idx_detalle_repuesto: 432 kB

**Conclusión:** `PRIMARY KEY (id_orden, id_repuesto)` solo ayuda a buscar por `id_orden`; filtrar por `id_repuesto` obligaba a leer las 59.556 líneas (*Rows Removed by Filter: 59393*). Con `idx_detalle_repuesto` esa lectura pasa a un *Bitmap Index Scan* y el tiempo baja de 4.12 ms a 2.4 ms (566 → 322 páginas). **Límite honesto:** `orden_servicio` sigue en *Seq Scan* porque el planificador prefiere un *Hash Join* a hacer 163 búsquedas por PK; la mejora es solo en la tabla de detalle. Como el repuesto 15 devuelve ~0,3 % de las filas, el índice rinde; para un repuesto muy popular rendiría menos.

### Caso 3: Órdenes de un mecánico en un rango de fechas (índice compuesto)

**Pregunta de negocio:** ¿Qué órdenes recibió el mecánico 3 en marzo de 2026?  
**Filas devueltas:** 96

**Consulta:**
```sql
SELECT id_orden, fecha_recepcion, estado
FROM orden_servicio
WHERE id_mecanico = 3
  AND fecha_recepcion >= '2026-03-01' AND fecha_recepcion < '2026-04-01'
ORDER BY fecha_recepcion;
```

**Plan antes** (sin el índice):
```
Sort  (cost=539.20..539.44 rows=97 width=21) (actual time=1.030..1.034 rows=96 loops=1)
  Sort Key: fecha_recepcion
  Sort Method: quicksort  Memory: 30kB
  Buffers: shared hit=189
  ->  Seq Scan on orden_servicio  (cost=0.00..536.00 rows=97 width=21) (actual time=0.204..1.001 rows=96 loops=1)
        Filter: ((fecha_recepcion >= '2026-03-01 00:00:00'::timestamp without time zone) AND (fecha_recepcion < '2026-04-01 00:00:00'::timestamp without time zone) AND (id_mecanico = 3))
        Rows Removed by Filter: 19904
        Buffers: shared hit=186
Planning:
  Buffers: shared hit=114
Planning Time: 0.203 ms
Execution Time: 1.059 ms
```

**Índice:**
```sql
CREATE INDEX idx_orden_mecanico_fecha ON orden_servicio (id_mecanico, fecha_recepcion);
```

**Plan después:**
```
Sort  (cost=169.79..170.04 rows=97 width=21) (actual time=0.122..0.126 rows=96 loops=1)
  Sort Key: fecha_recepcion
  Sort Method: quicksort  Memory: 30kB
  Buffers: shared hit=72
  ->  Bitmap Heap Scan on orden_servicio  (cost=5.52..166.59 rows=97 width=21) (actual time=0.021..0.099 rows=96 loops=1)
        Recheck Cond: ((id_mecanico = 3) AND (fecha_recepcion >= '2026-03-01 00:00:00'::timestamp without time zone) AND (fecha_recepcion < '2026-04-01 00:00:00'::timestamp without time zone))
        Heap Blocks: exact=66
        Buffers: shared hit=69
        ->  Bitmap Index Scan on idx_orden_mecanico_fecha  (cost=0.00..5.50 rows=97 width=0) (actual time=0.009..0.010 rows=96 loops=1)
              Index Cond: ((id_mecanico = 3) AND (fecha_recepcion >= '2026-03-01 00:00:00'::timestamp without time zone) AND (fecha_recepcion < '2026-04-01 00:00:00'::timestamp without time zone))
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=137
Planning Time: 0.252 ms
Execution Time: 0.163 ms
```

**Tamaño del índice:** idx_orden_mecanico_fecha: 632 kB

**Conclusión:** Consulta de igualdad (`id_mecanico`) más rango de fechas. El índice compuesto `(id_mecanico, fecha_recepcion)` deja el *Seq Scan* de 20.000 filas en un *Bitmap Index Scan*: de 1.06 ms a 0.163 ms y de 189 a 72 páginas. El orden de columnas importa: igualdad primero, rango después; al revés no serviría para filtrar por mecánico solo. Además cubre la FK `id_mecanico`, por eso no se crea un índice aparte para ella.

### Caso 4: Órdenes activas, tablero del taller (índice parcial)

**Pregunta de negocio:** ¿Cuáles órdenes no han sido entregadas, de la más antigua a la más reciente?  
**Filas devueltas:** 610

**Consulta:**
```sql
SELECT id_orden, fecha_recepcion, estado, id_mecanico
FROM orden_servicio
WHERE estado <> 'entregado'
ORDER BY fecha_recepcion;
```

**Plan antes** (sin el índice):
```
Sort  (cost=464.22..465.75 rows=610 width=25) (actual time=1.066..1.088 rows=610 loops=1)
  Sort Key: fecha_recepcion
  Sort Method: quicksort  Memory: 59kB
  Buffers: shared hit=189
  ->  Seq Scan on orden_servicio  (cost=0.00..436.00 rows=610 width=25) (actual time=0.015..0.959 rows=610 loops=1)
        Filter: ((estado)::text <> 'entregado'::text)
        Rows Removed by Filter: 19390
        Buffers: shared hit=186
Planning:
  Buffers: shared hit=131
Planning Time: 0.221 ms
Execution Time: 1.127 ms
```

**Índice:**
```sql
CREATE INDEX idx_orden_activas ON orden_servicio (fecha_recepcion) WHERE estado <> 'entregado';
```

**Plan después:**
```
Sort  (cost=241.32..242.85 rows=610 width=25) (actual time=0.336..0.359 rows=610 loops=1)
  Sort Key: fecha_recepcion
  Sort Method: quicksort  Memory: 59kB
  Buffers: shared hit=180
  ->  Bitmap Heap Scan on orden_servicio  (cost=19.48..213.10 rows=610 width=25) (actual time=0.037..0.234 rows=610 loops=1)
        Recheck Cond: ((estado)::text <> 'entregado'::text)
        Heap Blocks: exact=174
        Buffers: shared hit=177
        ->  Bitmap Index Scan on idx_orden_activas  (cost=0.00..19.32 rows=610 width=0) (actual time=0.020..0.020 rows=610 loops=1)
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=143
Planning Time: 0.241 ms
Execution Time: 0.402 ms
```

**Tamaño del índice:** idx_orden_activas: 32 kB

**Conclusión:** Solo el 3 % de las órdenes (610 de 20.000) está sin entregar, y esas son las que el taller consulta a diario. El índice parcial pesa 32 kB (frente a un índice completo sobre toda la tabla) y elimina el *Seq Scan*: de 1.13 ms a 0.402 ms. Ojo: las páginas leídas casi no cambian (189 → 180) porque las órdenes sin entregar están repartidas por toda la tabla; la ganancia viene de no leer ni filtrar las 19.390 filas descartadas, y es un caso pequeño. Con tablas más grandes la ventaja crece.

### Caso 5: Caso negativo: índice sobre una columna de baja selectividad

**Pregunta de negocio:** ¿Cuántas órdenes ya fueron entregadas y con qué ids? (≈97 % de la tabla)  
**Filas devueltas:** 19390

**Consulta:**
```sql
SELECT id_orden, fecha_entrega
FROM orden_servicio
WHERE estado = 'entregado';
```

**Plan antes** (sin el índice):
```
Seq Scan on orden_servicio  (cost=0.00..436.00 rows=19390 width=12) (actual time=0.005..1.467 rows=19390 loops=1)
  Filter: ((estado)::text = 'entregado'::text)
  Rows Removed by Filter: 610
  Buffers: shared hit=186
Planning:
  Buffers: shared hit=137
Planning Time: 0.215 ms
Execution Time: 2.077 ms
```

**Índice:**
```sql
CREATE INDEX idx_orden_estado ON orden_servicio (estado);
```

**Plan después:**
```
Seq Scan on orden_servicio  (cost=0.00..436.00 rows=19390 width=12) (actual time=0.005..1.520 rows=19390 loops=1)
  Filter: ((estado)::text = 'entregado'::text)
  Rows Removed by Filter: 610
  Buffers: shared hit=186
Planning:
  Buffers: shared hit=157
Planning Time: 0.255 ms
Execution Time: 2.141 ms
```

**Tamaño del índice:** idx_orden_estado: 152 kB

**Conclusión:** El índice **no se usa**: `estado = 'entregado'` coincide con el 97 % de las filas, así que el planificador sigue con *Seq Scan* (el tiempo no mejora: 2.08 → 2.14 ms, ruido de medición). Un índice así solo costaría espacio y escrituras más lentas. **Se descartó y no está en la migración.** Este caso demuestra por qué no se indexa por costumbre.

## 4. FK de joins frecuentes (el resto)

PostgreSQL no indexa las claves foráneas por sí solo. Un índice en la FK acelera los joins y también las comprobaciones de `ON DELETE RESTRICT` / `CASCADE` / `SET NULL` sobre la tabla padre (sin él, borrar o cambiar un padre obliga a recorrer toda la tabla hija). Estado de las FK del esquema:

| FK | Cómo queda cubierta | Medida en este documento |
|----|---------------------|--------------------------|
| `vehiculo.id_cliente` | `idx_vehiculo_cliente` | Sí (caso 1) |
| `orden_servicio.id_vehiculo` | `idx_orden_vehiculo` | Sí (caso 1) |
| `orden_servicio.id_mecanico` | primera columna de `idx_orden_mecanico_fecha` | Sí (caso 3) |
| `orden_servicio.id_cita` | índice del `UNIQUE` | No hace falta |
| `detalle_orden_repuesto.id_orden` | primera columna de la PK compuesta | No hace falta |
| `detalle_orden_repuesto.id_repuesto` | `idx_detalle_repuesto` | Sí (caso 2) |
| `cita.id_mecanico` | `idx_cita_mecanico` (b-tree propio, útil para búsquedas por igualdad) | No (por analogía con el caso 1) |
| `cita.id_vehiculo` | `idx_cita_vehiculo` | No (por analogía con el caso 1) |
| `compra.id_proveedor` | `idx_compra_proveedor` | No (por analogía) |
| `detalle_compra.id_compra` | primera columna de la PK compuesta | No hace falta |
| `detalle_compra.id_repuesto` | `idx_detalle_compra_repuesto` | No (por analogía con el caso 2) |
| `garantia.id_orden` | `idx_garantia_orden` | No (por analogía) |
| `historial_estado.id_orden` | primera columna de `UNIQUE (id_orden, fecha_cambio)` | No hace falta |
| `historial_estado.id_mecanico` | `idx_historial_mecanico` | No (por analogía) |
| `alertas_stock.id_repuesto` | `idx_alertas_repuesto` | No (por analogía) |
| `bicicleta.id_vehiculo` / `motocicleta.id_vehiculo` | son la PK | No hace falta |

Los índices marcados "No (por analogía)" no tienen plan antes/después propio: se crean por la misma razón estructural que los casos 1 y 2, pero **sin evidencia medida**. Si el profesor pide evidencia de alguno, se mide con el mismo método.

## 5. Conclusiones

1. **Medir antes de indexar.** De 5 casos, 4 mejoraron y 1 (el de `estado`) se descartó con evidencia.
2. **Orden de las columnas en índices compuestos:** igualdad primero, rango después (caso 3).
3. **Parcial cuando lo que se consulta es una minoría** (órdenes sin entregar, caso 4).
4. **No indexar columnas de baja selectividad** (caso 5): el planificador no las usa y cada índice encarece los `INSERT`/`UPDATE`.
5. **Volumen del experimento:** con 20.000 órdenes los tiempos son de milisegundos; la diferencia se nota más en páginas leídas y crecerá con el tamaño de las tablas.
