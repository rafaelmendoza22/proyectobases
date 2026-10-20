# 06. Auditoría de Normalización — AutoRueda Taller Técnico

## 1. Método

Para cada tabla se hace lo siguiente:
1. Se identifican la clave primaria y las claves candidatas.
2. Se listan las **dependencias funcionales (DF)** relevantes del dominio.
3. Se verifica:
   - **1FN:** todos los atributos son atómicos y no hay grupos repetidos.
   - **2FN:** ningún atributo no clave depende de solo una parte de una clave compuesta.
   - **3FN:** no hay dependencias transitivas (un atributo no clave que determina a otro no clave).
   - **BCNF:** todo determinante de una DF es una superclave.
4. Si algo no se cumple, se corrige o se **documenta la excepción** con su justificación.

**1FN en todo el esquema:** todos los atributos son atómicos. `direccion` y `condiciones` se tratan como texto único de negocio, sin partes que se consulten por separado. No hay atributos multivaluados ni grupos repetidos. Los M:N se resolvieron con tablas intermedias.

## 2. Auditoría tabla por tabla

### CLIENTE
Clave: `id_cliente`.
- DF: `id_cliente → nombre, telefono, correo, direccion`.
- **Resultado: BCNF.** El único determinante es la clave. El teléfono no es único (puede repetirse en una familia), por eso no es clave candidata.

### VEHICULO
Clave: `id_vehiculo`. Clave candidata: `placa_o_serie` (`UNIQUE`).
- DF: `id_vehiculo → marca, modelo, anio, tipo, placa_o_serie, id_cliente`.
- DF: `placa_o_serie → id_vehiculo` (y, por ende, todos los demás atributos).
- **Resultado: BCNF.** Ambos determinantes son claves.
- **Nota (`tipo`):** coincide con el subtipo en el que aparece el `id_vehiculo`. Es una redundancia deliberada: el discriminador de la especialización disjunta. Se protege con `CHECK (tipo IN ('bicicleta','moto'))`.

### BICICLETA y MOTOCICLETA (subtipos de VEHICULO)
Clave: `id_vehiculo` (PK y FK a `VEHICULO`, heredada del supertipo).
- DF BICICLETA: `id_vehiculo → tipo_bicicleta, num_cambios, tipo_frenos`.
- DF MOTOCICLETA: `id_vehiculo → cilindraje, num_motor, tipo_combustible`.
- **Resultado: BCNF.** Cada subtipo guarda solo los atributos que no comparten. Esto evita una tabla única con muchas columnas nulas, que mezclaría atributos que solo aplican a un tipo.

### MECANICO
Clave: `id_mecanico`.
- DF: `id_mecanico → nombre, especialidad, telefono, activo`.
- **Resultado: BCNF.**

### CITA
Clave: `id_cita`. Clave candidata: `(id_mecanico, fecha, hora_inicio)`, única por la regla de no solapamiento.
- DF: `id_cita → fecha, hora_inicio, hora_fin, motivo, id_vehiculo, id_mecanico`.
- DF: `(id_mecanico, fecha, hora_inicio) → id_cita` (y los demás atributos).
- **Resultado: BCNF.** Ambos determinantes son superclaves.

### ORDEN_SERVICIO
Clave: `id_orden`. Clave candidata: `id_cita` (`UNIQUE`, admite nulos), porque una cita origina como máximo una orden.
- DF: `id_orden → fecha_recepcion, fecha_entrega, estado, id_vehiculo, id_mecanico, id_cita`.
- DF: `id_cita → id_orden` (cuando no es nula).
- **Resultado: BCNF.**
- **Excepción justificada (`estado`):** repite el valor más reciente de `HISTORIAL_ESTADO` para esa orden. Es una redundancia deliberada para consultar el estado actual sin recorrer el historial. Se mantiene consistente al registrar cada cambio.

### REPUESTO
Clave: `id_repuesto`.
- DF: `id_repuesto → nombre, descripcion, stock_actual, stock_minimo, precio_unitario`.
- **Resultado: BCNF.**

### DETALLE_ORDEN_REPUESTO (resuelve el M:N `Utiliza`)
Clave compuesta: `(id_orden, id_repuesto)`.
- DF: `(id_orden, id_repuesto) → cantidad, precio_unitario_aplicado`.
- **2FN:** se cumple. `cantidad` y `precio_unitario_aplicado` dependen de la pareja completa, no de una sola de sus partes.
- **Excepción justificada (`precio_unitario_aplicado`):** podría parecer redundante con `REPUESTO.precio_unitario`, pero es un **hecho histórico deliberado**. El precio de catálogo cambia con el tiempo y lo cobrado en una orden no debe cambiar retroactivamente. Por eso depende de la pareja (orden, repuesto) y no solo del repuesto. Si dependiera solo de `id_repuesto`, sería una dependencia parcial que violaría la 2FN.
- **Resultado: BCNF.**

### PROVEEDOR
Clave: `id_proveedor`. Clave candidata: `nit` (`UNIQUE`).
- DF: `id_proveedor → nit, razon_social, direccion, telefono, correo, activo`.
- DF: `nit → id_proveedor` (y los demás atributos).
- **Resultado: BCNF.**

### COMPRA
Clave: `id_compra`.
- DF: `id_compra → fecha_compra, estado, id_proveedor`.
- **`total` no se almacena:** el diagrama lo marca como atributo derivado, igual a la suma de `cantidad × costo_unitario` de sus líneas en `DETALLE_COMPRA`. Guardarlo crearía riesgo de inconsistencia si una línea cambia. Se calcula con una vista (ver sección 3).
- **Resultado: BCNF.**

### DETALLE_COMPRA (resuelve el M:N `Incluye`)
Clave compuesta: `(id_compra, id_repuesto)`.
- DF: `(id_compra, id_repuesto) → cantidad, costo_unitario`.
- **2FN:** se cumple. Ambos atributos dependen de la pareja completa. `costo_unitario` es el costo pagado en esa compra y no el precio de venta del repuesto.
- **Resultado: BCNF.**

### GARANTIA
Clave: `id_garantia`.
- DF: `id_garantia → condiciones, dias_cobertura, fecha_inicio, id_orden`.
- **Hallazgo corregido (`fecha_vencimiento`):** si se guardara, existiría la DF `(fecha_inicio, dias_cobertura) → fecha_vencimiento`, cuyo determinante no es superclave y cuyo dependiente no es atributo primo. Eso es una **dependencia transitiva que viola la 3FN**. Por eso, igual que el diagrama (óvalo punteado), no se almacena: se calcula como `fecha_inicio + dias_cobertura` en una vista.
- **Resultado (sin el atributo derivado): BCNF.**

### HISTORIAL_ESTADO
Clave: `id_historial`. Clave candidata: `(id_orden, fecha_cambio)`.
- DF: `id_historial → id_orden, id_mecanico, estado_anterior, estado_nuevo, fecha_cambio`.
- **Resultado: BCNF.**
- **Nota (`estado_anterior`):** podría deducirse de la fila previa de la misma orden. Es una dependencia entre filas, no dentro de la tabla, por lo que no viola formalmente ninguna forma normal. Se conserva porque facilita auditar cada cambio sin recorrer toda la secuencia.

### ALERTAS_STOCK
Clave: `id_alerta`.
- DF: `id_alerta → fecha_alerta, stock_registrado, estado, id_repuesto`.
- **Resultado: BCNF.**
- **Excepción justificada (`stock_registrado`):** es una foto histórica del stock en el momento de la alerta. Es un hecho distinto de `REPUESTO.stock_actual`, que cambia con el tiempo.

## 3. Cómo se obtienen los atributos derivados (vistas)

```sql
-- Total de cada compra
CREATE VIEW v_compra_total AS
SELECT c.id_compra, SUM(d.cantidad * d.costo_unitario) AS total
FROM compra c
LEFT JOIN detalle_compra d ON d.id_compra = c.id_compra
GROUP BY c.id_compra;

-- Vencimiento de cada garantía
CREATE VIEW v_garantia_vigencia AS
SELECT id_garantia, id_orden, fecha_inicio, dias_cobertura,
       fecha_inicio + dias_cobertura AS fecha_vencimiento
FROM garantia;
```

## 4. Resumen

| Tabla | Forma normal alcanzada | Observación |
|---|---|---|
| CLIENTE | BCNF | — |
| VEHICULO | BCNF | `tipo` como discriminador (redundancia deliberada) |
| BICICLETA / MOTOCICLETA | BCNF | PK = FK a `VEHICULO` |
| MECANICO | BCNF | — |
| CITA | BCNF | clave candidata por la regla de no solapamiento |
| ORDEN_SERVICIO | BCNF | `estado` repite el último historial (excepción justificada) |
| REPUESTO | BCNF | — |
| DETALLE_ORDEN_REPUESTO | BCNF | precio histórico (excepción justificada) |
| PROVEEDOR | BCNF | `nit` como clave candidata |
| COMPRA | BCNF | `total` derivado, calculado con vista |
| DETALLE_COMPRA | BCNF | — |
| GARANTIA | BCNF | `fecha_vencimiento` derivado: guardarlo violaría la 3FN, se calcula con vista |
| HISTORIAL_ESTADO | BCNF | `estado_anterior` deducible (documentado) |
| ALERTAS_STOCK | BCNF | `stock_registrado` histórico (excepción justificada) |

**Conclusión:** las 15 tablas quedan en BCNF. Las redundancias que se mantienen son deliberadas y están justificadas arriba. Los dos atributos derivados del diagrama no se almacenan.
