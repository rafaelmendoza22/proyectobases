-- =====================================================================
-- migrations/006_vistas.sql · AutoRueda Taller Técnico · Entrega 2
-- Vistas para los atributos derivados que NO se almacenan (para respetar la 3FN).
-- Van después de 005_indices.sql.
-- =====================================================================

-- Total de cada compra = suma de sus líneas
CREATE VIEW v_compra_total AS
SELECT c.id_compra,
       COALESCE(SUM(d.cantidad * d.costo_unitario), 0) AS total
FROM compra c
LEFT JOIN detalle_compra d ON d.id_compra = c.id_compra
GROUP BY c.id_compra;

-- Vencimiento de cada garantía = fecha_inicio + dias_cobertura
CREATE VIEW v_garantia_vigencia AS
SELECT id_garantia,
       id_orden,
       fecha_inicio,
       dias_cobertura,
       fecha_inicio + dias_cobertura AS fecha_vencimiento
FROM garantia;
