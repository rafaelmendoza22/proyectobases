-- =====================================================================
-- seed/02_rechazos.sql · AutoRueda Taller Técnico · Entrega 2
-- Demostración: el servidor RECHAZA datos que rompen las reglas del negocio.
-- Se corre DESPUÉS de las migraciones y de la semilla. Cada sentencia debe fallar
-- con un ERROR (no modifica nada). Ejecutar SIN -v ON_ERROR_STOP para ver todos.
--   psql -d autorueda -f seed/02_rechazos.sql
-- =====================================================================

\echo '--- 1. Stock negativo (regla S-05) -> ck_repuesto_stock_no_negativo'
UPDATE repuesto SET stock_actual = -5 WHERE id_repuesto = 1;

\echo '--- 2. Un mecánico con dos citas solapadas -> ex_cita_sin_solape_mecanico'
INSERT INTO cita (fecha, hora_inicio, hora_fin, motivo, id_mecanico, id_vehiculo)
SELECT fecha, hora_inicio, hora_fin, 'Cita solapada de prueba', id_mecanico, 1
FROM cita WHERE id_cita = 1;

\echo '--- 3. Estado de orden fuera del flujo -> ck_orden_estado'
INSERT INTO orden_servicio (estado, id_vehiculo, id_mecanico) VALUES ('cancelado', 1, 1);

\echo '--- 4. Borrar un cliente que tiene vehículos -> fk_vehiculo_cliente (RESTRICT)'
DELETE FROM cliente WHERE id_cliente = 1;

\echo '--- 5. Borrar un mecánico que tiene órdenes y citas -> RESTRICT'
DELETE FROM mecanico WHERE id_mecanico = 1;

\echo '--- 6. Una moto registrada como bicicleta (especialización disjunta) -> fk_bicicleta_vehiculo'
INSERT INTO bicicleta (id_vehiculo, tipo_bicicleta, num_cambios, tipo_frenos)
SELECT id_vehiculo, 'urbana', 7, 'V-brake' FROM vehiculo WHERE tipo = 'moto' LIMIT 1;

\echo '--- 7. Repuesto con cantidad cero en una orden -> ck_detalle_orden_cantidad'
INSERT INTO detalle_orden_repuesto (id_orden, id_repuesto, cantidad, precio_unitario_aplicado)
VALUES (1, 299, 0, 1000);

-- =====================================================================
-- Acciones referenciales que SÍ se ejecutan (dentro de una transacción que se deshace)
-- =====================================================================
\echo ''
\echo '--- A. SET NULL: borrar una cita NO borra la orden, solo pierde la referencia'
BEGIN;
SELECT id_orden, id_cita FROM orden_servicio WHERE id_cita IS NOT NULL ORDER BY id_orden LIMIT 1 \gset
SELECT :id_orden AS orden, :id_cita AS cita_antes;
DELETE FROM cita WHERE id_cita = :id_cita;
SELECT id_orden, id_cita AS cita_despues FROM orden_servicio WHERE id_orden = :id_orden;
ROLLBACK;

\echo '--- B. CASCADE: borrar una orden borra sus líneas de repuestos'
BEGIN;
SELECT count(*) AS lineas_antes FROM detalle_orden_repuesto WHERE id_orden = 2;
DELETE FROM orden_servicio WHERE id_orden = 2;
SELECT count(*) AS lineas_despues FROM detalle_orden_repuesto WHERE id_orden = 2;
ROLLBACK;
