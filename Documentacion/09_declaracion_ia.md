# 09. Declaración de uso de IA — AutoRueda Taller Técnico

> Documento de la Entrega 2. Describe qué herramientas de IA se usaron, para qué, y **cómo verificamos** lo que generaron.

## 1. Integrantes y participación

| Integrante | Parte del proyecto |
|---|---|
| Cristhian Santiago Paba Galindo | Esquema relacional y políticas de borrado, normalización, migraciones (DDL) `001–004` y `006`, script de rechazos `02_rechazos.sql`, declaración de IA y cierre de la entrega |
| Jimmy Andrés Huertas Novoa | Diagrama EER actualizado |
| Kevin Arbey Pinzon Sierra | Datos de prueba (semilla) e índices |
| Jhoan Pereira | Banco de consultas |
| Rafael Mendoza | Participó en la Entrega 1; se retiró del curso antes de la Entrega 2 |

## 2. Herramienta usada
- **Claude** (Anthropic), como asistente de conversación para revisar, redactar borradores y explicar conceptos.
- Otras herramientas de IA: [COMPLETAR: ninguna / cuáles].

## 3. Para qué se usó, por parte

| Parte | Responsable | Uso de la IA |
|---|---|---|
| Esquema relacional y políticas de borrado (`04`) | Cristhian | Claude redactó un borrador del mapeo del EER y de la justificación de cada política; revisó inconsistencias entre diagrama, esquema y supuestos |
| Migraciones `001–004` y `006` | Cristhian | Claude escribió el borrador a partir del EER y de la semilla; Cristhian lo revisó y lo probó |
| Script de rechazos `02_rechazos.sql` | Cristhian | Borrador generado por Claude |
| Auditoría de normalización (`06`) | Cristhian | Borrador de dependencias funcionales y verificación por tabla |
| Declaración de IA, README y guion de sustentación | Cristhian | Borradores redactados con Claude |
| Diagrama EER (`03`) | Jimmy | [COMPLETAR por Jimmy: sin IA / cómo la usó] |
| Datos semilla e índices (`01_semilla.sql`, `005_indices.sql`, `08`) | Kevin | [COMPLETAR por Kevin: sin IA / cómo la usó] |
| Banco de consultas (`07`) | Jhoan | [COMPLETAR por Jhoan: sin IA / cómo la usó] |

## 4. Cómo verificamos lo generado

1. **Ejecución real.** Las migraciones se ejecutaron en orden (`001` a `006`) sobre una base de PostgreSQL 16 **vacía**, y luego se cargó la semilla. Claude lo probó primero en su propio entorno y reportó que corrían sin errores; **después nosotros lo repetimos en nuestros equipos** el [COMPLETAR: fecha] con resultado [COMPLETAR: sin errores / errores y cómo se corrigieron].
2. **Prueba de las restricciones.** Corrimos `seed/02_rechazos.sql` y comprobamos que el servidor rechaza datos inválidos (stock negativo, estado de orden fuera del flujo, borrar un cliente con vehículos, borrar un mecánico con registros, una moto registrada como bicicleta, cantidad cero en una orden) y que `SET NULL` y `CASCADE` se comportan como se documentó.
3. **Coherencia entre documentos.** Contrastamos el diagrama EER con el esquema relacional, el DDL y los supuestos. Esa revisión detectó discrepancias reales, que corregimos:
   - `id_mecanico` en la orden era `SET NULL` en el esquema, pero (1,1) en el diagrama: se resolvió con `NOT NULL` + `RESTRICT`.
   - Nombres de columnas distintos entre documentos (por ejemplo, `precio_unitario_aplicado` frente a `precio_unitario_cobrado`).
   - Atributos derivados (`total`, `fecha_vencimiento`) que no debían guardarse por violar la 3FN; se calculan en vistas.
4. **Contraste con la rúbrica.** Cada criterio de la rúbrica del profesor se comparó con lo que entregamos: esquema, restricciones con nombre propio y acción referencial justificada, datos de prueba, demostración y repositorio. [COMPLETAR: quién lo revisó].
5. **Comprensión del grupo.** Cada integrante repasó el guion de sustentación y puede explicar las decisiones del esquema (políticas de borrado, claves, restricciones) sin ayuda de la IA. [COMPLETAR: confirmar que es cierto, uno por uno].

## 5. Limitaciones y lo que no se delegó
- Las decisiones de diseño (qué tablas existen, qué política de borrado usar y por qué) las toma y las justifica el grupo; la IA propuso opciones.
- La IA cometió errores durante el trabajo (nombres inconsistentes entre documentos, un reparto de porcentajes mal calculado, una contradicción de cardinalidad que hubo que señalar dos veces), que detectamos al revisar y corregimos.
- Los datos de la semilla son ficticios; no se usó información personal real.
- La lógica de servidor (descuento automático de stock, transiciones de estado, especialización total) queda para la entrega siguiente.
- El repositorio no contiene credenciales ni contraseñas.
