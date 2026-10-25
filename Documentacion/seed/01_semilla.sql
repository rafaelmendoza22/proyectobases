-- =====================================================================
-- seed/01_semilla.sql  ·  AutoRueda Taller Técnico  ·  Entrega 2 (Persona 4)
--
-- Semilla coherente y con volumen. Se corre UNA vez sobre la base vacía,
-- DESPUÉS de las migraciones (001_...sql en adelante) y ANTES de las consultas.
-- Es determinista: setseed(0.42) hace que todos obtengan los mismos datos.
--
-- Datos 100 % ficticios (supuesto S-11). Nada de cliente1 / cliente2.
--
-- Volumen:  proveedor 15 · mecanico 8 · cliente 2.000 · vehiculo 3.000
--           repuesto 300 · cita 5.000 · orden_servicio 20.000
--           detalle_orden_repuesto ≈ 60.000 · compra 400 · detalle_compra 1.200
--           garantia ≈ 5.000 · historial_estado ≈ 58.000 · alertas_stock ≈ 190
--
-- Reglas de coherencia que respeta (y que se verifican al final):
--   · Ninguna cita de un mismo mecánico se solapa (cumple el EXCLUDE).
--   · Orden con cita: recepción = fecha/hora de la cita, mismo vehículo y mecánico.
--   · fecha_entrega solo existe si estado = 'entregado' y es >= recepción.
--   · El estado de la orden = estado_nuevo del último historial_estado (ver 06_normalizacion).
--   · precio_unitario_aplicado es el precio congelado: más barato en órdenes viejas
--     que el precio actual del catálogo (no es una copia de repuesto.precio_unitario).
--   · Órdenes 'recibido' aún no tienen repuestos cargados.
--   · Repuestos 281-300 NUNCA se usan en una orden (sirven al LEFT JOIN "los que no tienen").
--   · Algunos repuestos quedan por debajo del stock mínimo (alertas activas).
--   · Distribución sesgada: pocos vehículos concentran muchas órdenes (sirve al HAVING).
--   · Mecánico 8 está inactivo y solo atiende hasta 2025-12-31; proveedor 15 inactivo
--     y solo con compras hasta 2025-12-31.
-- Fecha de referencia ("hoy" de la semilla): 2026-10-20.
-- =====================================================================

SELECT setseed(0.42);

-- ---------------------------------------------------------------------
-- 1. PROVEEDOR (15)
-- ---------------------------------------------------------------------
INSERT INTO proveedor (nit, razon_social, direccion, telefono, correo, activo)
SELECT
  '900' || lpad((100000 + g * 137)::text, 6, '0') || '-' || (g % 10),
  (ARRAY['Distribuidora Bicirepuestos SAS','Motopartes del Caribe Ltda','Importadora Ruedas y Cadenas',
         'Lubricantes La Sabana','Frenos y Suspensión del Cesar','Repuestos Vallenatos SAS',
         'Biciparts Colombia','Moto Insumos del Norte','Tornillos y Accesorios Valledupar',
         'Llantas Express','Cadenas y Piñones Ltda','Eléctricos Moto Caribe','Pedales y Componentes SAS',
         'Aceites y Filtros del Cesar','Todo Cicla Mayorista'])[g],
  'Calle ' || (10 + g) || ' # ' || (5 + g) || '-' || (20 + g) || ', ' ||
    (ARRAY['Valledupar','Barranquilla','Bogotá','Medellín','Santa Marta'])[1 + g % 5],
  '30' || (g % 10) || lpad((2000000 + g * 7919)::text, 7, '0'),
  'ventas' || g || '@proveedor' || g || '.co',
  g <> 15
FROM generate_series(1, 15) g;

-- ---------------------------------------------------------------------
-- 2. MECANICO (8)
-- ---------------------------------------------------------------------
INSERT INTO mecanico (nombre, especialidad, telefono, activo)
SELECT
  (ARRAY['Edwin Maestre','Yeison Rangel','Luis Carlos Daza','Fabián Orozco',
         'Wilmer Cuello','Jairo Peñaloza','Omar Villazón','Henry Barrios'])[g],
  (ARRAY['ambos','motos','motos','bicicletas','ambos','motos','bicicletas','motos'])[g],
  '31' || (g % 10) || lpad((3100000 + g * 4421)::text, 7, '0'),
  g <> 8
FROM generate_series(1, 8) g;

-- ---------------------------------------------------------------------
-- 3. CLIENTE (2.000)
-- ---------------------------------------------------------------------
WITH c AS (
  SELECT g,
    (ARRAY['Carlos','María','Luis','Ana','Jorge','Laura','Andrés','Camila','Juan','Valentina',
           'Miguel','Sofía','David','Daniela','José','Paola','Santiago','Karen','Felipe','Natalia',
           'Alejandro','Yuliana','Hernán','Marcela','Jhon','Liliana','Óscar','Katherine','Ricardo','Diana']
    )[1 + floor(random() * 30)::int] AS f,
    (ARRAY['Pérez','Gómez','Rodríguez','Mendoza','Fuentes','Ortiz','Daza','Maestre','Cuello','Araújo',
           'Zuleta','Molina','Castro','Peñaloza','Villazón','Orozco','Barrios','Ovalle','Acosta','Pumarejo',
           'Mejía','Quintero','Ramos','Lacouture','Jiménez','Torres','Díaz','Márquez','Sierra','Rangel']
    )[1 + floor(random() * 30)::int] AS s1,
    (ARRAY['Pérez','Gómez','Rodríguez','Mendoza','Fuentes','Ortiz','Daza','Maestre','Cuello','Araújo',
           'Zuleta','Molina','Castro','Peñaloza','Villazón','Orozco','Barrios','Ovalle','Acosta','Pumarejo',
           'Mejía','Quintero','Ramos','Lacouture','Jiménez','Torres','Díaz','Márquez','Sierra','Rangel']
    )[1 + floor(random() * 30)::int] AS s2
  FROM generate_series(1, 2000) g
)
INSERT INTO cliente (nombre, telefono, email, direccion)
SELECT
  f || ' ' || s1 || ' ' || s2,
  '3' || lpad(floor(random() * 25)::int::text, 2, '0') || lpad(floor(random() * 10000000)::bigint::text, 7, '0'),
  CASE WHEN g % 10 = 0 THEN NULL   -- 10 % sin correo (campo opcional)
       ELSE lower(translate(f || '.' || s1, 'ÁÉÍÓÚÑáéíóúñ', 'AEIOUNaeioun')) || g ||
            (ARRAY['@gmail.com','@hotmail.com','@outlook.com','@yahoo.com'])[1 + g % 4] END,
  CASE WHEN g % 10 < 3 THEN NULL   -- 30 % sin dirección (campo opcional)
       ELSE 'Cra ' || (1 + g % 30) || ' # ' || (2 + g % 45) || '-' || (1 + (g * 7) % 90) || ', Barrio ' ||
            (ARRAY['Los Mayales','Villa Corelca','Novalito','Simón Bolívar','Cañaguate','Los Fundadores',
                   'Dangond','Alfonso López','Garupal','Panamá','Sicarare','El Carmen'])[1 + g % 12] END
FROM c
ORDER BY g;

-- ---------------------------------------------------------------------
-- 4. VEHICULO (3.000) + subtipos BICICLETA / MOTOCICLETA
--    40 % bicicletas, 60 % motos. Los primeros 2.000 vehículos: uno por cliente;
--    los otros 1.000 se reparten entre clientes (algunos tienen varios).
-- ---------------------------------------------------------------------
WITH v AS (
  SELECT g,
    CASE WHEN g % 100 < 40 THEN 'bicicleta' ELSE 'moto' END AS tipo,
    1 + floor(random() * 10)::int AS pick,
    CASE WHEN g <= 2000 THEN g ELSE 1 + floor(power(random(), 1.3) * 2000)::int END AS id_cliente,
    random() AS r
  FROM generate_series(1, 3000) g
)
INSERT INTO vehiculo (tipo, marca, modelo, placa_o_serie, anio, id_cliente)
SELECT
  tipo,
  CASE WHEN tipo = 'bicicleta'
       THEN split_part((ARRAY['Trek|Marlin 5','Specialized|Rockhopper','GW|Alaska','Scott|Aspect 950','Giant|Talon 3',
                              'Venzo|Thorn','Orbea|Alma H30','BH|Expert','Cannondale|Trail 7','Trek|FX 2'])[pick], '|', 1)
       ELSE split_part((ARRAY['Yamaha|FZ 2.0|149','Honda|CB 125F|125','AKT|NKD 125|125','Bajaj|Pulsar NS200|200',
                              'Suzuki|Gixxer 150|150','TVS|Apache RTR 160|160','Yamaha|XTZ 125|125',
                              'Bajaj|Boxer CT100|100','Honda|XR 150L|150','KTM|Duke 200|200'])[pick], '|', 1) END,
  CASE WHEN tipo = 'bicicleta'
       THEN split_part((ARRAY['Trek|Marlin 5','Specialized|Rockhopper','GW|Alaska','Scott|Aspect 950','Giant|Talon 3',
                              'Venzo|Thorn','Orbea|Alma H30','BH|Expert','Cannondale|Trail 7','Trek|FX 2'])[pick], '|', 2)
       ELSE split_part((ARRAY['Yamaha|FZ 2.0|149','Honda|CB 125F|125','AKT|NKD 125|125','Bajaj|Pulsar NS200|200',
                              'Suzuki|Gixxer 150|150','TVS|Apache RTR 160|160','Yamaha|XTZ 125|125',
                              'Bajaj|Boxer CT100|100','Honda|XR 150L|150','KTM|Duke 200|200'])[pick], '|', 2) END,
  CASE WHEN tipo = 'moto'
       THEN chr(65 + g % 26) || chr(65 + (g / 26) % 26) || chr(65 + (g / 676) % 26) ||
            lpad(((g * 7) % 100)::text, 2, '0') || chr(65 + (g * 3) % 26)
       WHEN g % 20 = 0 THEN NULL            -- bicicletas viejas sin serie conocida
       ELSE 'SN' || lpad(((g * 7919) % 1000000)::text, 6, '0') END,
  (CASE WHEN tipo = 'moto' THEN 2012 ELSE 2008 END) + floor(r * (CASE WHEN tipo = 'moto' THEN 14 ELSE 18 END))::int,
  id_cliente
FROM v
ORDER BY g;

INSERT INTO bicicleta (id_vehiculo, tipo_bicicleta, num_cambios, tipo_frenos)
SELECT id_vehiculo,
  (ARRAY['montaña','ruta','urbana','BMX','híbrida'])[1 + id_vehiculo % 5],
  (ARRAY[1, 7, 18, 21, 24, 27])[1 + (id_vehiculo / 5) % 6],
  (ARRAY['V-brake','disco mecánico','disco hidráulico','contrapedal'])[1 + (id_vehiculo / 3) % 4]
FROM vehiculo WHERE tipo = 'bicicleta';

INSERT INTO motocicleta (id_vehiculo, cilindraje, num_motor, tipo_combustible)
SELECT v.id_vehiculo,
  split_part((ARRAY['Yamaha|FZ 2.0|149','Honda|CB 125F|125','AKT|NKD 125|125','Bajaj|Pulsar NS200|200',
                    'Suzuki|Gixxer 150|150','TVS|Apache RTR 160|160','Yamaha|XTZ 125|125',
                    'Bajaj|Boxer CT100|100','Honda|XR 150L|150','KTM|Duke 200|200']
             )[array_position(ARRAY['FZ 2.0','CB 125F','NKD 125','Pulsar NS200','Gixxer 150','Apache RTR 160',
                                    'XTZ 125','Boxer CT100','XR 150L','Duke 200'], v.modelo)], '|', 3)::smallint,
  upper(left(md5('motor' || v.id_vehiculo), 10)),
  'gasolina'
FROM vehiculo v WHERE v.tipo = 'moto';

-- ---------------------------------------------------------------------
-- 5. REPUESTO (300) = 30 tipos de repuesto x 10 variantes
-- ---------------------------------------------------------------------
INSERT INTO repuesto (nombre, descripcion, stock_actual, stock_minimo, precio_unitario)
WITH p AS (
  SELECT g,
    (ARRAY['Pastillas de freno','Cadena de transmisión','Llanta','Bujía','Aceite 20W-50 1L','Filtro de aire',
           'Cable de freno','Cable de cambios','Cámara de aire','Piñón','Plato','Pedal','Manubrio','Sillín',
           'Disco de freno','Kit de arrastre','Amortiguador trasero','Batería 12V','Bombillo de faro',
           'Guaya de acelerador','Empaque de culata','Kit de embrague','Espejo retrovisor','Cadena de moto',
           'Neumático de moto','Rodamiento','Grasa multipropósito','Líquido de frenos','Radio de rueda',
           'Cinta de manubrio'])[1 + (g - 1) % 30] AS parte,
    (ARRAY[25000,45000,90000,12000,28000,22000,9000,9500,15000,38000,85000,30000,60000,50000,70000,
           120000,180000,110000,8000,14000,35000,95000,18000,65000,160000,20000,16000,18000,3000,12000]
    )[1 + (g - 1) % 30] AS base,
    (ARRAY['estándar','reforzado','económico','premium','universal','importado','nacional','OEM',
           'alto rendimiento','kit x2'])[1 + (g - 1) / 30] AS variante,
    (g - 1) / 30 AS vi
  FROM generate_series(1, 300) g
), s AS (
  SELECT *, 3 + floor(random() * 10)::int AS minimo, random() AS r FROM p
)
SELECT
  parte || ' ' || variante,
  'Repuesto ' || lower(parte) || ' (' || variante || ')',
  CASE WHEN r < 0.12 THEN floor(random() * minimo)::int           -- ~12 % bajo el mínimo
       ELSE minimo + floor(random() * 50)::int END,
  minimo,
  round(base * (0.80 + 0.05 * vi) / 100) * 100
FROM s ORDER BY g;

-- ---------------------------------------------------------------------
-- 6. CITA (5.000): rejilla por mecánico (8) x día hábil (lun-sáb) x 4 franjas.
--    Cada cita dura 60 o 90 min dentro de una franja de 2 h => nunca se solapan.
-- ---------------------------------------------------------------------
INSERT INTO cita (fecha, hora_inicio, hora_fin, motivo, id_mecanico, id_vehiculo)
WITH s AS (
  SELECT g, g % 8 + 1 AS m, (g / 8) AS k FROM generate_series(0, 4999) g
), t AS (
  SELECT g, m,
    DATE '2025-01-06' + (k / 4) + ((k / 4) / 6) AS fecha,
    (ARRAY['08:00','10:00','14:00','16:00'])[1 + k % 4]::time AS ini,
    CASE WHEN g % 3 = 0 THEN 90 ELSE 60 END AS dur
  FROM s
)
SELECT fecha, ini, ini + dur * interval '1 minute',
  (ARRAY['Revisión de frenos','Cambio de aceite','Ajuste de cambios','Cambio de llanta','Mantenimiento preventivo',
         'Revisión eléctrica','Cambio de kit de arrastre','Diagnóstico de ruido en motor','Alineación de rueda',
         'Pinchazo / cámara de aire'])[1 + g % 10],
  m,
  1 + floor(power(random(), 1.3) * 3000)::int
FROM t ORDER BY g;

-- ---------------------------------------------------------------------
-- 7. ORDEN_SERVICIO (20.000)
--    a) 4.000 órdenes que nacen de una cita (80 % de las citas)
--    b) 16.000 órdenes sin cita (walk-in)
--    "Hoy" de la semilla = 2026-10-20. Lo reciente (últimos 15 días) está en curso;
--    ~1 % de lo viejo quedó sin retirar ('listo').
-- ---------------------------------------------------------------------
INSERT INTO orden_servicio (fecha_recepcion, fecha_entrega, estado, id_vehiculo, id_mecanico, id_cita)
WITH base AS (
  SELECT (c.fecha + c.hora_inicio) AS rec, c.id_vehiculo, c.id_mecanico, c.id_cita, random() AS r1, random() AS r2
  FROM cita c WHERE c.id_cita % 5 <> 0
  ORDER BY c.id_cita
), est AS (
  SELECT *,
    CASE WHEN rec >= TIMESTAMP '2026-10-05' THEN (ARRAY['recibido','en_reparacion','listo'])[1 + floor(r1 * 3)::int]
         WHEN r1 < 0.01 THEN 'listo'
         ELSE 'entregado' END AS estado
  FROM base
)
SELECT rec,
  CASE WHEN estado = 'entregado'
       THEN rec + floor(r2 * 7)::int * interval '1 day' + interval '2 hours' + r1 * interval '6 hours' END,
  estado, id_vehiculo, id_mecanico, id_cita
FROM est;

INSERT INTO orden_servicio (fecha_recepcion, fecha_entrega, estado, id_vehiculo, id_mecanico, id_cita)
WITH w AS (
  SELECT g,
    (DATE '2025-01-06' + floor(random() * 652)::int) AS d0,
    random() AS rh, random() AS r1, random() AS r2, random() AS r3,
    1 + floor(power(random(), 1.3) * 3000)::int AS id_vehiculo
  FROM generate_series(1, 16000) g
), w2 AS (
  SELECT *,
    CASE WHEN extract(dow FROM d0) = 0 THEN d0 + 1 ELSE d0 END
      + (time '08:00' + floor(rh * 540)::int * interval '1 minute') AS rec
  FROM w
), est AS (
  SELECT *,
    CASE WHEN rec >= TIMESTAMP '2026-10-05' THEN (ARRAY['recibido','en_reparacion','listo'])[1 + floor(r1 * 3)::int]
         WHEN r1 < 0.01 THEN 'listo'
         ELSE 'entregado' END AS estado
  FROM w2
)
SELECT rec,
  CASE WHEN estado = 'entregado'
       THEN rec + floor(r2 * 7)::int * interval '1 day' + interval '2 hours' + r1 * interval '6 hours' END,
  estado,
  id_vehiculo,
  CASE WHEN rec < TIMESTAMP '2026-01-01' THEN 1 + floor(r3 * 8)::int      -- mecánico 8 solo hasta 2025
       ELSE 1 + floor(r3 * 7)::int END,
  NULL
FROM est ORDER BY g;

-- ---------------------------------------------------------------------
-- 8. DETALLE_ORDEN_REPUESTO (≈ 60.000)
--    1 a 5 repuestos por orden, distintos entre sí. Solo repuestos 1-280.
--    Las órdenes 'recibido' todavía no tienen repuestos.
--    Precio congelado: sube de ~88 % a 100 % del catálogo actual entre ene-2025 y oct-2026.
-- ---------------------------------------------------------------------
INSERT INTO detalle_orden_repuesto (id_orden, id_repuesto, cantidad, precio_unitario_aplicado)
SELECT o.id_orden,
  ((o.base + k * 37 - 1) % 280) + 1,
  1 + floor(random() * 3)::int,
  round(r.precio_unitario
        * (0.88 + 0.12 * least(1.0, extract(epoch FROM (o.fecha_recepcion - TIMESTAMP '2025-01-06'))
                                     / (651 * 86400.0))) / 100) * 100
FROM (
  SELECT id_orden, fecha_recepcion, 1 + floor(power(random(), 1.5) * 280)::int AS base
  FROM orden_servicio WHERE estado <> 'recibido' OFFSET 0
) o
CROSS JOIN LATERAL generate_series(1, 1 + o.id_orden % 5) k
JOIN repuesto r ON r.id_repuesto = ((o.base + k * 37 - 1) % 280) + 1;

-- ---------------------------------------------------------------------
-- 9. HISTORIAL_ESTADO: una fila por cada transición hasta el estado actual.
--    El estado_nuevo de la última fila coincide con orden_servicio.estado.
-- ---------------------------------------------------------------------
INSERT INTO historial_estado (id_orden, id_mecanico, estado_anterior, estado_nuevo, fecha_cambio)
WITH est AS (SELECT ARRAY['recibido','en_reparacion','listo','entregado'] AS e)
SELECT o.id_orden, o.id_mecanico,
  est.e[i - 1], est.e[i],
  CASE WHEN o.estado = 'entregado'
       THEN o.fecha_recepcion + (o.fecha_entrega - o.fecha_recepcion) * ((i - 1) / 3.0)::float8
       ELSE o.fecha_recepcion + (i - 1) * interval '6 hours' END
FROM orden_servicio o
CROSS JOIN est
CROSS JOIN LATERAL generate_series(
  2, array_position(est.e, o.estado)) i
WHERE o.estado <> 'recibido';

-- ---------------------------------------------------------------------
-- 10. GARANTIA: ~25 % de las órdenes entregadas; algunas con una segunda garantía.
-- ---------------------------------------------------------------------
INSERT INTO garantia (condiciones, dias_cobertura, fecha_inicio, id_orden)
SELECT
  (ARRAY['Cubre mano de obra y repuestos instalados','Cubre solo defectos de fábrica del repuesto',
         'Cubre mano de obra; no cubre mal uso'])[1 + id_orden % 3],
  (ARRAY[30, 60, 90])[1 + id_orden % 3],
  fecha_entrega::date,
  id_orden
FROM orden_servicio WHERE estado = 'entregado' AND id_orden % 4 = 0;

INSERT INTO garantia (condiciones, dias_cobertura, fecha_inicio, id_orden)
SELECT 'Garantía extendida sobre repuesto de alto valor', 180, fecha_entrega::date, id_orden
FROM orden_servicio WHERE estado = 'entregado' AND id_orden % 40 = 0;

-- ---------------------------------------------------------------------
-- 11. COMPRA (400) + DETALLE_COMPRA (1.200)
-- ---------------------------------------------------------------------
INSERT INTO compra (fecha_compra, estado, id_proveedor)
WITH c AS (
  SELECT g, DATE '2025-01-02' + floor(random() * 660)::int AS f, random() AS r1, random() AS r2
  FROM generate_series(1, 400) g
)
SELECT f,
  CASE WHEN f >= DATE '2026-10-10' THEN 'pendiente'
       WHEN r1 < 0.03 THEN 'cancelada'
       ELSE 'recibida' END,
  CASE WHEN f < DATE '2026-01-01' THEN 1 + floor(r2 * 15)::int
       ELSE 1 + floor(r2 * 14)::int END
FROM c ORDER BY f, g;

INSERT INTO detalle_compra (id_compra, id_repuesto, cantidad, costo_unitario)
SELECT c.id_compra,
  ((c.base + k * 89 - 1) % 300) + 1,
  5 + floor(random() * 36)::int,
  round(r.precio_unitario * (0.60 + 0.15 * random()) / 100) * 100
FROM (SELECT id_compra, 1 + floor(random() * 300)::int AS base FROM compra OFFSET 0) c
CROSS JOIN generate_series(1, 3) k
JOIN repuesto r ON r.id_repuesto = ((c.base + k * 89 - 1) % 300) + 1;

-- ---------------------------------------------------------------------
-- 12. ALERTAS_STOCK: una alerta activa por cada repuesto hoy bajo el mínimo
--     + 150 alertas históricas ya atendidas.
-- ---------------------------------------------------------------------
INSERT INTO alertas_stock (fecha_alerta, stock_registrado, estado, id_repuesto)
SELECT TIMESTAMP '2026-10-01' + floor(random() * 19)::int * interval '1 day' + interval '9 hours',
       stock_actual, 'activa', id_repuesto
FROM repuesto WHERE stock_actual < stock_minimo ORDER BY id_repuesto;

INSERT INTO alertas_stock (fecha_alerta, stock_registrado, estado, id_repuesto)
SELECT TIMESTAMP '2025-01-10' + floor(random() * 600)::int * interval '1 day' + interval '9 hours',
       floor(random() * r.stock_minimo)::int, 'atendida', r.id_repuesto
FROM generate_series(1, 150) g
JOIN repuesto r ON r.id_repuesto = 1 + (g * 7) % 300;

-- ---------------------------------------------------------------------
-- Estadísticas frescas para que el planificador decida bien
-- ---------------------------------------------------------------------
ANALYZE;
