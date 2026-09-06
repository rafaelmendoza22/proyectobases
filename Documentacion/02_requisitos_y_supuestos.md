# Requisitos de Información y Supuestos de Diseño

## "AutoRueda Taller Técnico" – Sistema de Gestión de Órdenes de Servicio e Inventario

### 1. Requisitos funcionales de información

El sistema debe permitir registrar, mantener y consultar la siguiente información:

| # | Requisito | Descripción |
|---|-----------|-------------|
| RF-01 | Gestión de clientes | Registrar y consultar clientes con sus datos de contacto. |
| RF-02 | Gestión de vehículos | Registrar vehículos (bicicleta o moto) asociados a un cliente: marca, modelo, año, placa o número de serie. |
| RF-03 | Gestión de mecánicos | Registrar mecánicos con su especialidad, contacto y estado (activo/inactivo). |
| RF-04 | Agendamiento de citas | Agendar citas indicando fecha/hora de inicio y fin, mecánico asignado, vehículo y motivo. |
| RF-05 | Control de disponibilidad | Impedir que un mismo mecánico tenga dos citas que se solapen en el tiempo. |
| RF-06 | Órdenes de servicio | Crear órdenes de servicio con seguimiento mediante estados: `recibido`, `en_reparacion`, `listo`, `entregado`. |
| RF-07 | Uso de repuestos en órdenes | Asociar repuestos a una orden de servicio, indicando cantidad y precio aplicado al momento del uso. |
| RF-08 | Gestión de inventario | Mantener el inventario de repuestos: stock actual, stock mínimo y precio unitario vigente. |
| RF-09 | Descuento automático de stock | Descontar automáticamente del inventario la cantidad de repuestos usados en una orden. |
| RF-10 | Alertas de stock bajo | Identificar repuestos cuyo stock actual esté por debajo del stock mínimo definido. |
| RF-11 | Consultas de negocio | Responder preguntas operativas: órdenes por estado, carga de trabajo por mecánico, repuestos más usados, historial de un cliente o vehículo, etc. |

### 2. Preguntas de interrogatorio y supuestos adoptados

Durante el levantamiento de requisitos surgieron varias preguntas sobre reglas de negocio que no eran evidentes a partir de la descripción inicial del taller. A continuación se documentan las preguntas planteadas y la decisión (supuesto) que se adoptó para poder avanzar con el modelado, junto con su justificación.

| # | Pregunta | Decisión / Supuesto | Justificación |
|---|----------|---------------------|----------------|
| S-01 | ¿Un vehículo puede cambiar de dueño a lo largo del tiempo? | Sí, pero en esta versión el vehículo pertenece a un único cliente actual (relación 1:N). Si cambia de dueño, se actualiza la clave foránea. | Simplifica el modelo para la Entrega 1. Un historial de propietarios se puede modelar como tabla adicional en una fase posterior si el negocio lo requiere. |
| S-02 | ¿Una orden de servicio puede tener más de un mecánico asignado? | No. Cada orden tiene exactamente un mecánico responsable principal. | Refleja la operación real del taller: un mecánico "toma" la orden de principio a fin. Evita ambigüedad sobre quién responde por el trabajo. |
| S-03 | ¿Es obligatorio tener una cita previa para crear una orden de servicio? | No. La cita es opcional; un cliente puede llegar sin cita (walk-in) y generarse la orden directamente. | En un taller de este tipo, gran parte de los clientes llega sin agendar. Forzar la cita como obligatoria no reflejaría la realidad del negocio. |
| S-04 | ¿Qué valores puede tomar el estado de una orden? | Únicamente cuatro valores controlados: `recibido`, `en_reparacion`, `listo`, `entregado`. | Un dominio cerrado y pequeño se modela mejor como atributo restringido (CHECK) que como entidad aparte, evitando complejidad innecesaria. |
| S-05 | ¿Se puede registrar el uso de más repuestos de los que hay en stock? | No. El sistema debe impedir que una operación deje el stock en un valor negativo. | Es una regla de integridad crítica para el negocio: evita inconsistencias entre el inventario físico y el registrado. |
| S-06 | ¿El precio de un repuesto se "congela" cuando se usa en una orden? | Sí. Se almacena el precio unitario aplicado al momento del uso, independiente del precio actual del repuesto. | Los precios de los repuestos cambian con el tiempo. Sin este histórico, no sería posible reconstruir correctamente lo cobrado en órdenes pasadas. |
| S-07 | ¿Una cita puede extenderse por más de un día? | No. Toda cita inicia y finaliza el mismo día. | Es coherente con la duración típica de un servicio de mantenimiento o reparación en este tipo de taller. |
| S-08 | ¿Se gestionan bicicletas y motocicletas de forma distinta en el modelo? | No de forma estructural. Se diferencian mediante el atributo `tipo_vehiculo`, ya que comparten el mismo conjunto de atributos y reglas de negocio. | Evita duplicar tablas para dos tipos de entidad que en la práctica se gestionan igual dentro del taller. |
| S-09 | ¿Se requiere un historial detallado de cada cambio de estado de una orden? | No en esta versión. Solo se almacena el estado actual. | Mantiene el alcance de la Entrega 1 realista. Un historial de auditoría (tabla de bitácora) queda propuesto como mejora futura. |
| S-10 | ¿Qué pasa si se elimina un mecánico o una cita que ya está referenciada por una orden? | La orden no se elimina: la referencia al mecánico o a la cita se pone en `NULL`, preservando el registro histórico de la orden. | El historial de servicio de un vehículo es información valiosa del negocio y no debe perderse por cambios administrativos (por ejemplo, que un mecánico deje de trabajar en el taller). |
| S-11 | ¿Se manejan datos personales reales de clientes para el proyecto? | No. Todos los datos de prueba serán ficticios pero coherentes con el dominio. | Buena práctica de manejo de datos y requisito habitual de este tipo de entregas académicas. |
| S-12 | ¿Puede un cliente tener varios vehículos registrados? | Sí, un cliente puede tener cero o varios vehículos (relación 1:N). | Es común que un mismo cliente lleve más de una bicicleta o moto al taller a lo largo del tiempo. |

### 3. Justificación de decisiones de diseño principales

**a) Entidad asociativa para el detalle de repuestos por orden.**  
La relación entre `ORDEN_SERVICIO` y `REPUESTO` es de muchos a muchos: una orden puede usar varios repuestos, y un mismo repuesto puede usarse en muchas órdenes distintas. Esta relación no se puede representar directamente en un modelo relacional, y además necesita atributos propios (`cantidad`, `precio_unitario_aplicado`) que no pertenecen ni a la orden ni al repuesto individualmente. Por eso se modela como una entidad asociativa (`DETALLE_ORDEN_REPUESTO`) con clave primaria compuesta.

**b) El estado de la orden como atributo, no como entidad.**  
Se evaluó modelar los estados de una orden como una tabla independiente (`ESTADO`), pero se descartó porque el conjunto de valores es pequeño, cerrado y estable en el tiempo. Modelarlo como atributo con restricción `CHECK` es más simple y suficiente para las necesidades actuales del negocio, sin sacrificar integridad.

**c) La regla de no solapamiento de citas no se modela con cardinalidad.**  
Aunque es una regla de negocio central, la restricción de que un mecánico no puede tener dos citas que se crucen en el tiempo no puede expresarse mediante cardinalidades del modelo EER. Se documenta explícitamente como regla de negocio en este documento y se implementará a nivel de base de datos (constraint de exclusión o trigger) en una entrega posterior, cuando se trabaje la capa de implementación física.

**d) Políticas de borrado diferenciadas por tipo de relación.**  
Se usó `ON DELETE RESTRICT` como política general para preservar la integridad del historial operativo (no se puede borrar un cliente, vehículo, mecánico o repuesto que ya tenga movimientos asociados). Se usó `ON DELETE CASCADE` únicamente en `DETALLE_ORDEN_REPUESTO`, ya que las líneas de detalle no tienen sentido sin su orden asociada. Se usó `ON DELETE SET NULL` en las referencias de la orden hacia mecánico y cita, para que la orden —que es información histórica valiosa— nunca se pierda por la eliminación de registros administrativos secundarios.

**e) Precio histórico en el detalle de la orden.**  
Se decidió almacenar el precio unitario aplicado en el momento del uso del repuesto, en lugar de depender del precio vigente en la tabla `REPUESTO`. Esto evita que cambios futuros en los precios alteren retroactivamente el valor de órdenes ya cerradas, lo cual sería un error grave de integridad histórica para cualquier sistema de este tipo.
