# 05. Diccionario de Datos Inicial — Taller "AutoRueda Taller Técnico"

> Diccionario correspondiente al esquema descrito en `04_esquema_relacional.md`. Tipos propuestos pensando en PostgreSQL 16+ (se ajustarán, si hace falta, en la Entrega 2 al escribir el DDL).

---

## CLIENTE

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_cliente | `SERIAL / INTEGER` (PK) | No | Identificador único del cliente. |
| nombre | `VARCHAR(120)` | No | Nombre completo del cliente. |
| telefono | `VARCHAR(20)` | No | Teléfono principal de contacto (para avisos por WhatsApp/llamada). |
| email | `VARCHAR(150)` | Sí | Correo del cliente, si lo tiene. |
| direccion | `VARCHAR(200)` | Sí | Dirección de referencia, opcional. |

---

## VEHICULO

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_vehiculo | `SERIAL / INTEGER` (PK) | No | Identificador único del vehículo. |
| tipo | `VARCHAR(10)` `CHECK IN ('bicicleta','moto')` | No | Distingue bicicleta de motocicleta; determina qué campos aplican en la práctica. |
| marca | `VARCHAR(60)` | No | Marca del vehículo. |
| modelo | `VARCHAR(60)` | Sí | Modelo o línea del vehículo. |
| placa_o_serie | `VARCHAR(30)` | Sí | Placa (motos) o número de serie/cuadro (bicicletas). Puede no conocerse en bicicletas viejas. |
| anio | `SMALLINT` | Sí | Año del vehículo, si se conoce. |
| id_cliente | `INTEGER` (FK → CLIENTE) | No | Dueño actual del vehículo. |

---

## MECANICO

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_mecanico | `SERIAL / INTEGER` (PK) | No | Identificador único del mecánico. |
| nombre | `VARCHAR(120)` | No | Nombre completo del mecánico. |
| especialidad | `VARCHAR(60)` | Sí | Ej: "bicicletas", "motos", "ambos". Útil para asignar órdenes. |
| telefono | `VARCHAR(20)` | Sí | Contacto interno del mecánico. |
| activo | `BOOLEAN` | No (default `true`) | Indica si el mecánico sigue trabajando en el taller. Se usa para "dar de baja" sin borrar su historial de órdenes/citas. |

---

## CITA

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_cita | `SERIAL / INTEGER` (PK) | No | Identificador único de la cita. |
| fecha | `DATE` | No | Día de la cita (inicio y fin son siempre el mismo día, según supuesto). |
| hora_inicio | `TIME` | No | Hora de inicio de la cita. |
| hora_fin | `TIME` | No | Hora de fin; debe ser mayor a `hora_inicio` (`CHECK`). |
| motivo | `VARCHAR(200)` | Sí | Breve descripción de por qué se agenda (ej: "revisión de frenos"). |
| id_mecanico | `INTEGER` (FK → MECANICO) | No | Mecánico asignado a la cita. No puede solaparse con otra cita del mismo mecánico (regla de negocio a validar con trigger/EXCLUDE en Entrega 2/3). |
| id_vehiculo | `INTEGER` (FK → VEHICULO) | No | Vehículo para el que se agenda la cita. |

---

## ORDEN_SERVICIO

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_orden | `SERIAL / INTEGER` (PK) | No | Identificador único de la orden de servicio. |
| fecha_recepcion | `TIMESTAMP` | No | Fecha/hora en que se recibió el vehículo y se abrió la orden. |
| fecha_entrega | `TIMESTAMP` | Sí | Fecha/hora en que se entregó el vehículo al cliente; nula mientras la orden no está en estado `entregado`. |
| estado | `VARCHAR(15)` `CHECK IN ('recibido','en_reparacion','listo','entregado')` | No (default `'recibido'`) | Estado actual de la orden en el flujo de trabajo del taller. |
| id_vehiculo | `INTEGER` (FK → VEHICULO) | No | Vehículo sobre el que se abre la orden. |
| id_mecanico | `INTEGER` (FK → MECANICO) | **Sí** | Mecánico responsable principal de la orden (una orden = un solo mecánico responsable, según supuesto). Nullable porque la FK usa política `ON DELETE SET NULL`: si el mecánico se borra, la orden conserva su historial y solo pierde esta referencia. |
| id_cita | `INTEGER` (FK → CITA) | **Sí** | Cita que originó la orden, si la hubo. Es opcional porque un cliente puede llegar sin cita previa. |

---

## REPUESTO

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_repuesto | `SERIAL / INTEGER` (PK) | No | Identificador único del repuesto. |
| nombre | `VARCHAR(120)` | No | Nombre comercial del repuesto (ej: "pastillas de freno delanteras"). |
| descripcion | `VARCHAR(250)` | Sí | Detalle adicional (compatibilidad, marca, etc.). |
| stock_actual | `INTEGER` `CHECK (>= 0)` | No (default `0`) | Unidades disponibles actualmente en inventario. Se descuenta automáticamente al usarse en una orden. |
| stock_minimo | `INTEGER` `CHECK (>= 0)` | No (default `0`) | Umbral bajo el cual el sistema debe generar una alerta de stock bajo. |
| precio_unitario | `NUMERIC(10,2)` | No | Precio de venta vigente del repuesto (puede cambiar con el tiempo; no afecta órdenes ya facturadas). |

---

## DETALLE_ORDEN_REPUESTO *(tabla de detalle / resuelve la relación M:N)*

| Columna | Tipo | Nulo | Descripción de negocio |
|---|---|---|---|
| id_orden | `INTEGER` (PK compuesta, FK → ORDEN_SERVICIO) | No | Orden en la que se usó el repuesto. |
| id_repuesto | `INTEGER` (PK compuesta, FK → REPUESTO) | No | Repuesto usado. |
| cantidad | `INTEGER` `CHECK (> 0)` | No | Unidades del repuesto usadas en esa orden. |
| precio_unitario_aplicado | `NUMERIC(10,2)` `CHECK (>= 0)` | No | Precio unitario **congelado** al momento de usar el repuesto (no cambia si luego cambia `REPUESTO.precio_unitario`). |

---

## Resumen de tipos usados

| Tipo lógico | Tipo PostgreSQL propuesto |
|---|---|
| Identificador autoincremental | `SERIAL` / `INTEGER` |
| Texto corto (nombres, categorías) | `VARCHAR(n)` |
| Texto libre más largo | `VARCHAR(200–250)` |
| Fecha sin hora | `DATE` |
| Hora sin fecha | `TIME` |
| Fecha y hora | `TIMESTAMP` |
| Cantidades enteras | `INTEGER` / `SMALLINT` |
| Dinero | `NUMERIC(10,2)` (nunca `FLOAT`, para evitar errores de redondeo) |
| Verdadero/falso | `BOOLEAN` |

*Este diccionario se actualizará en la Entrega 2 conforme al DDL realmente implementado, como exige la rúbrica.*
