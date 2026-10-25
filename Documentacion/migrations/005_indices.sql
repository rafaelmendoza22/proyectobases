-- =====================================================================
-- migrations/0XX_indices.sql  (renombrar con el número que siga, p. ej. 005_indices.sql)
-- Índices de la Entrega 2 (Persona 4). Evidencia de plan antes/después en Documentacion/08_indices.md.
-- Va DESPUÉS de las migraciones de tablas. Una migración aplicada no se edita:
-- si hay que cambiar un índice, se hace en la siguiente migración.
-- PostgreSQL NO crea índices automáticamente sobre las FK; las PK y UNIQUE ya tienen el suyo.
-- =====================================================================

-- --- Con evidencia medida (casos 1 a 4 de Documentacion/08_indices.md) ---------
CREATE INDEX idx_vehiculo_cliente      ON vehiculo (id_cliente);                -- caso 1: cliente -> vehículos
CREATE INDEX idx_orden_vehiculo        ON orden_servicio (id_vehiculo);         -- caso 1: vehículo -> órdenes
CREATE INDEX idx_detalle_repuesto      ON detalle_orden_repuesto (id_repuesto); -- caso 2: la PK empieza por id_orden
CREATE INDEX idx_orden_mecanico_fecha  ON orden_servicio (id_mecanico, fecha_recepcion); -- caso 3: igualdad + rango (también cubre la FK id_mecanico)
CREATE INDEX idx_orden_activas         ON orden_servicio (fecha_recepcion)
                                       WHERE estado <> 'entregado';             -- caso 4: índice parcial

-- --- FK de joins frecuentes restantes (justificadas en Documentacion/08_indices.md, sección 4) ---
CREATE INDEX idx_cita_vehiculo         ON cita (id_vehiculo);
CREATE INDEX idx_compra_proveedor      ON compra (id_proveedor);
CREATE INDEX idx_detalle_compra_repuesto ON detalle_compra (id_repuesto);
CREATE INDEX idx_garantia_orden        ON garantia (id_orden);
CREATE INDEX idx_historial_mecanico    ON historial_estado (id_mecanico);
CREATE INDEX idx_alertas_repuesto      ON alertas_stock (id_repuesto);

-- Ya cubiertas, NO se duplican:
--   cita.id_mecanico            -> primera columna del EXCLUDE (índice GiST cita_id_mecanico_tsrange_excl)
--   orden_servicio.id_cita      -> UNIQUE
--   historial_estado.id_orden   -> UNIQUE (id_orden, fecha_cambio)
--   bicicleta/motocicleta.id_vehiculo -> son PK
-- Descartado con evidencia (caso 5): índice sobre orden_servicio.estado.
