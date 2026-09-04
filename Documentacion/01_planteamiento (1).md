# Planteamiento del Problema

## "AutoRueda Taller Técnico" – Sistema de Gestión de Órdenes de Servicio e Inventario

### 1. Contexto del negocio

El taller **AutoRueda Taller Técnico**, ubicado en Valledupar, es un negocio familiar que se dedica al mantenimiento y reparación de bicicletas y motocicletas. Atiende dos tipos de clientes: ciclistas recreativos y deportivos que buscan mantenimiento preventivo y ajustes de precisión, y motociclistas de uso diario que necesitan reparaciones más frecuentes y urgentes. Cuenta con un equipo reducido de mecánicos especializados y maneja un inventario constante de repuestos (frenos, cadenas, llantas, bujías, aceites, entre otros).

Con el crecimiento del negocio, la cantidad de clientes, vehículos y órdenes de servicio ha aumentado bastante, pero la forma de gestionar la información no ha evolucionado al mismo ritmo.

### 2. Situación actual

Hoy en día el taller opera con un sistema de información completamente manual y fragmentado:

- **Órdenes de servicio:** se anotan en cuadernos físicos, sin un formato estandarizado. No hay forma de saber con certeza en qué estado se encuentra una orden sin buscarla físicamente o preguntarle directamente al mecánico encargado.
- **Inventario:** se lleva en una hoja de Excel compartida, actualizada de forma manual y con frecuencia desactualizada. No refleja el stock real disponible en el momento.
- **Citas:** se coordinan por WhatsApp y se anotan en una agenda de papel, sin ningún mecanismo que impida que un mismo mecánico quede agendado en dos citas al mismo tiempo.
- **Historial:** no existe un registro estructurado de qué repuestos se usaron en cada orden, en qué cantidad, ni a qué precio se cobraron en su momento.

### 3. Problemas identificados

1. **Falta de control de inventario en tiempo real.** Es común que un mecánico abra una orden de servicio y solo hasta ese momento descubra que no hay stock del repuesto necesario, lo que genera demoras y reprocesos.
2. **Pérdida de trazabilidad de las órdenes.** Al no existir un estado formal y centralizado, se presentan confusiones sobre si una orden ya fue recibida, está en reparación, está lista o ya fue entregada al cliente.
3. **Sobrecarga y choques de agenda.** La ausencia de un control de disponibilidad provoca que un mecánico sea asignado a dos citas que se traslapan en el tiempo, afectando la puntualidad del servicio.
4. **Ausencia de historial confiable.** No es posible reconstruir con precisión qué repuestos se usaron en una reparación específica ni el precio al que se cobraron, lo cual dificulta auditorías, garantías y análisis de rentabilidad.
5. **Imposibilidad de responder preguntas básicas del negocio.** Preguntas operativas simples —como cuántas órdenes de motos están actualmente en reparación, qué repuestos están por debajo del stock mínimo, o qué mecánico tiene mayor carga de trabajo— no se pueden responder sin una revisión manual larga y propensa a errores.

### 4. Alcance del sistema propuesto

Se plantea el diseño e implementación de una base de datos relacional que centralice toda la información operativa del taller y sirva como única fuente de verdad del negocio. El sistema deberá permitir:

- Registrar clientes y los vehículos (bicicletas o motocicletas) asociados a cada uno.
- Gestionar la información de los mecánicos del taller (especialidad, disponibilidad, contacto).
- Agendar citas con control de disponibilidad, evitando el solapamiento de horarios para un mismo mecánico.
- Crear y dar seguimiento a órdenes de servicio a través de un flujo de estados definido: `recibido → en_reparación → listo → entregado`.
- Registrar el uso de repuestos en cada orden, descontando automáticamente del inventario disponible.
- Mantener el inventario de repuestos actualizado, con alertas de stock bajo cuando la cantidad disponible caiga por debajo del mínimo establecido.
- Generar consultas de negocio útiles para la toma de decisiones diaria (carga de trabajo por mecánico, repuestos más utilizados, órdenes por estado, etc.).

### 5. Fuera del alcance (por ahora)

Con el fin de mantener un alcance realista para esta primera entrega, quedan explícitamente fuera:

- Facturación electrónica o integración con sistemas contables.
- Historial de auditoría detallado de cada cambio de estado de una orden (se podrá incorporar en una versión posterior).
- Gestión de nómina o pagos a los mecánicos.
- Aplicación móvil o interfaz web (esta entrega se centra en el modelo de datos, no en el desarrollo de interfaz).

### 6. Resultado esperado

Al finalizar el proyecto, AutoRueda Taller Técnico contará con una base de datos relacional bien diseñada, normalizada y con reglas de integridad claras, capaz de sostener las operaciones diarias del taller y de crecer junto con el negocio sin comprometer la consistencia de la información.
