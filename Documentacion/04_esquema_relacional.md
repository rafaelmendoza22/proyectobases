# 04. Esquema Relacional — AutoRueda Taller Técnico (versión Entrega 2)

> Refleja las migraciones `migrations/001…006`. Convención de nombres de restricciones: `pk_` · `fk_` · `ck_` · `uq_`.

## 1. Tablas (15)

```
CLIENTE(**id_cliente**, nombre, telefono, email, direccion)
MECANICO(**id_mecanico**, nombre, especialidad, telefono, activo)
PROVEEDOR(**id_proveedor**, nit, razon_social, direccion, telefono, correo, activo)
REPUESTO(**id_repuesto**, nombre, descripcion, stock_actual, stock_minimo, precio_unitario)

VEHICULO(**id_vehiculo**, tipo, marca, modelo, placa_o_serie, anio, id_cliente FK)
BICICLETA(**id_vehiculo** FK, tipo, tipo_bicicleta, num_cambios, tipo_frenos)
MOTOCICLETA(**id_vehiculo** FK, tipo, cilindraje, num_motor, tipo_combustible)

CITA(**id_cita**, fecha, hora_inicio, hora_fin, motivo, id_mecanico FK, id_vehiculo FK)
ORDEN_SERVICIO(**id_orden**, fecha_recepcion, fecha_entrega, estado,
               id_vehiculo FK, id_mecanico FK, id_cita FK [nullable, único])
DETALLE_ORDEN_REPUESTO(**id_orden FK, id_repuesto FK**, cantidad, precio_unitario_aplicado)
HISTORIAL_ESTADO(**id_historial**, id_orden FK, id_mecanico FK [nullable],
                 estado_anterior, estado_nuevo, fecha_cambio)
GARANTIA(**id_garantia**, condiciones, dias_cobertura, fecha_inicio, id_orden FK)
ALERTAS_STOCK(**id_alerta**, fecha_alerta, stock_registrado, estado, id_repuesto FK)

COMPRA(**id_compra**, fecha_compra, estado, id_proveedor FK)
DETALLE_COMPRA(**id_compra FK, id_repuesto FK**, cantidad, costo_unitario)
```

**Mapeo:**
- Los dos M:N (`Utiliza` y `Incluye`) se resolvieron con `DETALLE_ORDEN_REPUESTO` y `DETALLE_COMPRA`, de clave primaria compuesta.
- La especialización disjunta de VEHICULO se mapeó con una tabla por subtipo, cuya clave primaria es a la vez FK al supertipo. La FK compuesta `(id_vehiculo, tipo)` y el `CHECK` sobre `tipo` impiden que un vehículo sea bicicleta y moto a la vez.
- Los atributos derivados `compra.total` y `garantia.fecha_vencimiento` **no se almacenan** (para respetar la 3FN): se calculan en las vistas `v_compra_total` y `v_garantia_vigencia`.

## 2. Claves foráneas y políticas de borrado

| FK (nombre) | Hija → Padre | Acción | Por qué, en términos del negocio |
|---|---|---|---|
| `fk_vehiculo_cliente` | VEHICULO → CLIENTE | **RESTRICT** | No se borra un cliente con vehículos: se perdería a quién se le hizo cada reparación. |
| `fk_cita_mecanico` | CITA → MECANICO | **RESTRICT** | Protege la agenda histórica. Los mecánicos no se borran, se marcan inactivos. |
| `fk_cita_vehiculo` | CITA → VEHICULO | **RESTRICT** | El historial de citas de un vehículo no debe desaparecer con él. |
| `fk_orden_vehiculo` | ORDEN → VEHICULO | **RESTRICT** | La orden es el expediente del vehículo; no puede quedar huérfana. |
| `fk_orden_mecanico` | ORDEN → MECANICO | **RESTRICT** | Cada orden tiene un mecánico responsable (S-02); quién la atendió es parte esencial del historial. |
| `fk_orden_cita` | ORDEN → CITA | **SET NULL** | La cita es solo el origen opcional de la orden (S-03). Si se borra, la orden se conserva y pierde esa referencia. |
| `fk_detalle_orden_orden` | DETALLE_ORDEN → ORDEN | **CASCADE** | Una línea de repuestos no existe sin su orden. |
| `fk_detalle_orden_repuesto` | DETALLE_ORDEN → REPUESTO | **RESTRICT** | No se borra un repuesto ya usado: se perdería lo que se cobró. |
| `fk_historial_orden` | HISTORIAL → ORDEN | **CASCADE** | El historial de estados no existe sin su orden. |
| `fk_historial_mecanico` | HISTORIAL → MECANICO | **SET NULL** | Quién registró el cambio es dato de apoyo; el cambio de estado debe conservarse. |
| `fk_garantia_orden` | GARANTIA → ORDEN | **RESTRICT** | Una garantía es un compromiso con el cliente; no se borra la orden que la respalda. |
| `fk_alertas_repuesto` | ALERTAS → REPUESTO | **CASCADE** | Una alerta no tiene sentido sin el repuesto al que avisa. |
| `fk_compra_proveedor` | COMPRA → PROVEEDOR | **RESTRICT** | No se borra un proveedor con compras; se desactiva. |
| `fk_detalle_compra_compra` | DETALLE_COMPRA → COMPRA | **CASCADE** | Una línea de compra no existe sin su compra. |
| `fk_detalle_compra_repuesto` | DETALLE_COMPRA → REPUESTO | **RESTRICT** | No se borra un repuesto que ya fue comprado. |
| `fk_bicicleta_vehiculo` | BICICLETA → VEHICULO | **CASCADE** | El subtipo no tiene sentido sin su vehículo. |
| `fk_motocicleta_vehiculo` | MOTOCICLETA → VEHICULO | **CASCADE** | Igual que el anterior. |

**Criterio general (para defender):**
- **RESTRICT** es la regla por defecto, porque casi todo es historial del negocio que no debe perderse. Para dar de baja personas o empresas se usa la columna `activo`.
- **CASCADE** solo cuando la tabla hija no tiene significado sin el padre (líneas de detalle, historial, alertas, subtipos).
- **SET NULL** solo cuando el dato relacionado es secundario y la fila hija vale por sí misma (cita de origen, quién registró un cambio).

## 3. Reglas del negocio y dónde se declaran

| Regla | Declaración | Nombre |
|---|---|---|
| El stock nunca es negativo | `CHECK` en REPUESTO | `ck_repuesto_stock_no_negativo` |
| Stock mínimo y precios no negativos | `CHECK` | `ck_repuesto_stock_minimo`, `ck_repuesto_precio` |
| Una cita termina después de empezar (y no cruza de día) | `CHECK` | `ck_cita_horas` |
| La orden solo tiene 4 estados | `CHECK` | `ck_orden_estado` |
| No se entrega antes de recibir | `CHECK` | `ck_orden_fechas` |
| Hay fecha de entrega si y solo si está entregada | `CHECK` | `ck_orden_entrega_coherente` |
| Una cita origina como máximo una orden | `UNIQUE` | `uq_orden_cita` |
| El vehículo es bicicleta o moto; la especialización es disjunta | `CHECK` + FK compuesta | `ck_vehiculo_tipo`, `fk_bicicleta_vehiculo`, `fk_motocicleta_vehiculo` |
| No hay dos vehículos con la misma placa o serie | `UNIQUE` | `uq_vehiculo_placa_serie` |
| No hay dos proveedores con el mismo NIT | `UNIQUE` | `uq_proveedor_nit` |
| No se usa un repuesto en cantidad cero o negativa | `CHECK` | `ck_detalle_orden_cantidad`, `ck_detalle_compra_cantidad` |
| El precio congelado de la orden no es negativo | `CHECK` | `ck_detalle_orden_precio` |
| Un repuesto no se repite en la misma orden o compra | PK compuesta | `pk_detalle_orden_repuesto`, `pk_detalle_compra` |
| Estados válidos de compra, alerta e historial | `CHECK` | `ck_compra_estado`, `ck_alertas_estado`, `ck_historial_estado_nuevo` |
| Especialidad del mecánico | `CHECK` | `ck_mecanico_especialidad` |

**Reglas que no se pueden declarar con restricciones** (lógica de servidor, para la entrega siguiente):
- Que un mecánico no tenga dos citas solapadas (se valida en la aplicación antes de registrar la cita).
- Descontar el stock automáticamente al usar un repuesto en una orden.
- Que los estados avancen en orden (recibido → en reparación → listo → entregado).
- Que todo vehículo tenga su fila en BICICLETA o MOTOCICLETA (especialización total).

## 4. Cambios respecto a la Entrega 1 (y por qué)

| Cambio | Motivo |
|---|---|
| Se agregó `PROVEEDOR` (con `COMPRA` y `DETALLE_COMPRA`) | Observación del profesor: ampliar el proyecto. La relación es por compra, no directa con el repuesto. |
| Se agregaron `GARANTIA`, `HISTORIAL_ESTADO` y `ALERTAS_STOCK` | Cubrir garantías, trazabilidad de estados y las alertas de stock bajo (RF-10). |
| `VEHICULO` pasa a tener especialización en `BICICLETA` y `MOTOCICLETA` | Los dos tipos tienen atributos propios (frenos y cambios vs. cilindraje y motor). |
| `ORDEN_SERVICIO.id_mecanico`: de `SET NULL` a `NOT NULL` + `RESTRICT` | Resolvía una contradicción: el EER dice que toda orden tiene mecánico (1,1). Los mecánicos no se borran, se desactivan. |
| La regla de citas solapadas pasa de "pendiente" a implementada con `EXCLUDE` | Ya es una restricción declarada y probada. |
| `total` y `fecha_vencimiento` no se guardan | Son derivados; guardarlos violaría la 3FN. Se calculan en vistas. |
