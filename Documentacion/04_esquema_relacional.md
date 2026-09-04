# 04. Esquema Relacional — Taller "AutoRueda Taller Técnico"

## Notación
`TABLA(atributo_pk, atributo, atributo_fk)` — la clave primaria va **subrayada** (aquí en **negrita**), las claves foráneas se marcan con `FK →`.

---

## 1. Mapeo de entidades a relaciones

```
CLIENTE(**id_cliente**, nombre, telefono, email, direccion)

VEHICULO(**id_vehiculo**, tipo, marca, modelo, placa_o_serie, anio,
         id_cliente FK → CLIENTE)

MECANICO(**id_mecanico**, nombre, especialidad, telefono, activo)

CITA(**id_cita**, fecha, hora_inicio, hora_fin, motivo,
     id_mecanico FK → MECANICO,
     id_vehiculo FK → VEHICULO)

ORDEN_SERVICIO(**id_orden**, fecha_recepcion, fecha_entrega, estado,
               id_vehiculo FK → VEHICULO,
               id_mecanico FK → MECANICO  [nullable],
               id_cita FK → CITA  [nullable])

REPUESTO(**id_repuesto**, nombre, descripcion, stock_actual,
         stock_minimo, precio_unitario)

DETALLE_ORDEN_REPUESTO(**id_orden FK → ORDEN_SERVICIO**,
               **id_repuesto FK → REPUESTO**,
               cantidad, precio_unitario_aplicado)
```

**Total: 7 tablas** (cumple el mínimo de 6–8 exigido por la guía).

### Notas de mapeo
- `DETALLE_ORDEN_REPUESTO` es la tabla intermedia que resuelve la relación M:N entre `ORDEN_SERVICIO` y `REPUESTO` (una orden usa varios repuestos, un repuesto se usa en varias órdenes). Su clave primaria es **compuesta** (`id_orden`, `id_repuesto`).
- `CITA` es opcional para una orden (supuesto documentado en la Entrega 1: "no es obligatorio agendar cita"), por eso `id_cita` en `ORDEN_SERVICIO` es **nullable**.
- El atributo `tipo` en `VEHICULO` (bicicleta/moto) se modela como columna con `CHECK`, **no** como especialización en el esquema relacional, siguiendo el supuesto ya definido de que bicicletas y motos "casi" se tratan igual y solo difieren en ese atributo.
- `precio_unitario_aplicado` en `DETALLE_ORDEN_REPUESTO` es una **copia congelada** del precio del repuesto al momento de usarlo (supuesto de la Entrega 1: el precio se congela). No se recalcula desde `REPUESTO.precio_unitario`.

---

## 2. Claves foráneas y políticas de borrado

| FK | Tabla hija → Tabla padre | Política | Justificación |
|---|---|---|---|
| `VEHICULO.id_cliente` | Vehículo → Cliente | **RESTRICT** | No se permite borrar un cliente si tiene vehículos registrados: se perdería la trazabilidad de todas sus órdenes históricas. Si el negocio necesita "dar de baja" un cliente, se recomienda un atributo `activo` en vez de borrado físico (fuera de alcance de esta entrega). |
| `CITA.id_mecanico` | Cita → Mecánico | **RESTRICT** | Una cita sin mecánico no tiene sentido de negocio; si un mecánico se retira, sus citas futuras deben reasignarse o cancelarse explícitamente antes de poder borrarlo. |
| `CITA.id_vehiculo` | Cita → Vehículo | **RESTRICT** | Igual razón: preserva la coherencia del historial de citas del vehículo. |
| `ORDEN_SERVICIO.id_vehiculo` | Orden → Vehículo | **RESTRICT** | Una orden de servicio es un registro contable/histórico; no debe poder desaparecer el vehículo detrás de una orden ya facturada. |
| `ORDEN_SERVICIO.id_mecanico` | Orden → Mecánico | **SET NULL** | La orden es información histórica valiosa y no debe perderse por la baja de un registro administrativo secundario. Si el mecánico se elimina, la orden conserva todo su detalle (fechas, estado, repuestos usados) y solo pierde la referencia a quién la atendió. Por eso la columna es nullable. (Nota: para mecánicos que simplemente dejan de trabajar en el taller sin querer perder el dato, se recomienda usar `activo = false` en vez de un borrado físico — el `SET NULL` es la salvaguarda para cuando sí se borra.) |
| `ORDEN_SERVICIO.id_cita` | Orden → Cita | **SET NULL** | Misma razón que con el mecánico: la cita es solo el dato de agendamiento que originó la orden; si se borra, la orden ya creada debe conservarse y simplemente pierde esa referencia. Por eso la columna es nullable. |
| `DETALLE_ORDEN_REPUESTO.id_orden` | Orden_Repuesto → Orden_Servicio | **CASCADE** | El detalle de repuestos usados no tiene sentido sin su orden; si (en un caso excepcional, por ejemplo una orden creada por error) se borra la orden, sus líneas de detalle deben borrarse con ella. |
| `DETALLE_ORDEN_REPUESTO.id_repuesto` | Orden_Repuesto → Repuesto | **RESTRICT** | No se puede borrar un repuesto que ya fue usado en órdenes históricas — se perdería el detalle de qué se cobró. Para repuestos que el taller deja de manejar, se recomienda un atributo `descontinuado` en vez de borrado físico. |

**Principio general aplicado:** en este dominio casi todo es historial contable/operativo (órdenes, citas, uso de repuestos), así que la política por defecto es `RESTRICT`. Se usa `CASCADE` únicamente cuando el hijo no tiene significado de negocio independiente del padre (`DETALLE_ORDEN_REPUESTO` sin su `ORDEN_SERVICIO`). Se usa `SET NULL` específicamente en las dos referencias que salen de `ORDEN_SERVICIO` hacia registros administrativos secundarios (`MECANICO` y `CITA`): la orden en sí es el historial valioso y nunca debe desaparecer ni bloquear el borrado de esos registros — solo pierde la referencia puntual.

---

## 3. Restricciones CHECK principales

| Tabla | Restricción | Motivo |
|---|---|---|
| `VEHICULO` | `tipo IN ('bicicleta', 'moto')` | Supuesto de Entrega 1: solo esos dos valores son válidos. |
| `ORDEN_SERVICIO` | `estado IN ('recibido', 'en_reparacion', 'listo', 'entregado')` | Flujo de estados cerrado, definido explícitamente en el planteamiento. |
| `ORDEN_SERVICIO` | `fecha_entrega IS NULL OR fecha_entrega >= fecha_recepcion` | Una orden no puede entregarse antes de haberse recibido. |
| `REPUESTO` | `stock_actual >= 0` | Impide que el descuento automático de inventario deje stock negativo (regla explícita del planteamiento). |
| `REPUESTO` | `stock_minimo >= 0` | Coherencia del dato usado para las alertas de stock bajo. |
| `DETALLE_ORDEN_REPUESTO` | `cantidad > 0` | No tiene sentido registrar el uso de 0 o menos unidades de un repuesto. |
| `DETALLE_ORDEN_REPUESTO` | `precio_unitario_aplicado >= 0` | Un precio congelado no puede ser negativo. |
| `CITA` | `hora_fin > hora_inicio` | Restricción estructural básica de un intervalo de tiempo válido. |

> **Nota:** la regla "un mecánico no puede tener dos citas solapadas" es una restricción de **integridad entre filas** (no una restricción de una sola fila), por lo que no se implementa con `CHECK` sino con un mecanismo a nivel de servidor (constraint `EXCLUDE` con `btree_gist`, o un trigger de validación). Eso corresponde a la Entrega 2/3 de implementación; aquí solo se documenta como regla de negocio pendiente de aplicar.

---

## 4. Resumen de cardinalidades implementadas

| Relación | Cardinalidad | Cómo se representa en el esquema |
|---|---|---|
| Cliente – Vehículo | 1:N | FK `id_cliente` en `VEHICULO` |
| Mecánico – Cita | 1:N | FK `id_mecanico` en `CITA` |
| Vehículo – Cita | 1:N | FK `id_vehiculo` en `CITA` |
| Vehículo – Orden_Servicio | 1:N | FK `id_vehiculo` en `ORDEN_SERVICIO` |
| Mecánico – Orden_Servicio | 1:N | FK `id_mecanico` en `ORDEN_SERVICIO` (mecánico responsable único, según supuesto) |
| Cita – Orden_Servicio | 1:0..1 (opcional) | FK `id_cita` nullable en `ORDEN_SERVICIO` |
| Orden_Servicio – Repuesto | M:N | Tabla intermedia `DETALLE_ORDEN_REPUESTO` |
