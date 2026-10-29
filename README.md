[README (1).md](https://github.com/user-attachments/files/34129923/README.1.md)
# AutoRueda Taller Técnico

Sistema de Gestión de Órdenes de Servicio e Inventario
**Proyecto Integrador – Bases de Datos I** · Universidad Popular del Cesar
Semestre 2026 · PostgreSQL 16+

---

## Descripción

Base de datos relacional para el taller **AutoRueda Taller Técnico**, ubicado en Valledupar.
Gestiona clientes, vehículos (bicicletas y motocicletas), mecánicos, citas, órdenes de servicio, inventario de repuestos y compras a proveedores.

**Entrega 2:** 15 tablas con 65 restricciones con nombre propio (`pk_`, `fk_`, `ck_`, `uq_`), políticas de borrado justificadas, datos de prueba (~20.000 órdenes), índices y vistas.

---

## Integrantes y participación

| Nombre | Participación |
|---|---|
| Cristhian Santiago Paba Galindo | Esquema relacional y políticas de borrado, normalización, migraciones (DDL) `001–004` y `006`, script de rechazos, cierre de la entrega |
| Jimmy Andrés Huertas Novoa | Diagrama EER actualizado |
| Kevin Arbey Pinzon Sierra | Datos de prueba (semilla) e índices |
| Jhoan Pereira | Banco de consultas |
| Rafael Mendoza | Participó en la Entrega 1; se retiró del curso antes de la Entrega 2 |

---

## Cómo ejecutar

Sobre una base de datos **vacía** de PostgreSQL 16+, en este orden:

```bash
createdb autorueda
psql -d autorueda -f Documentacion/migrations/001_tablas_base.sql
psql -d autorueda -f Documentacion/migrations/002_vehiculos_y_citas.sql
psql -d autorueda -f Documentacion/migrations/003_ordenes.sql
psql -d autorueda -f Documentacion/migrations/004_compras.sql
psql -d autorueda -f Documentacion/seed/01_semilla.sql
psql -d autorueda -f Documentacion/migrations/005_indices.sql
psql -d autorueda -f Documentacion/migrations/006_vistas.sql
# Demostración de restricciones (cada sentencia debe fallar con un ERROR):
psql -d autorueda -f Documentacion/seed/02_rechazos.sql
```

- `001` activa la extensión `btree_gist` (necesaria para evitar citas solapadas).
- Una migración ya aplicada no se edita: los cambios van en una migración nueva.
- No hay credenciales en el repositorio.

---

## Estructura del repositorio

```text
├── README.md
└── Documentacion/
    ├── 01_planteamiento.md
    ├── 02_requisitos_y_supuestos.md
    ├── 03_diagrama_eer.jpg
    ├── 04_esquema_relacional.md      ← 15 tablas, FKs y políticas de borrado
    ├── 05_diccionario_datos.md
    ├── 06_normalizacion.md
    ├── 07_banco_consultas.md
    ├── 08_indices.md
    ├── 09_declaracion_ia.md          ← uso de IA y cómo se verificó
    ├── Entrega1_AutoRueda.pdf
    ├── migrations/
    │   ├── 001_tablas_base.sql
    │   ├── 002_vehiculos_y_citas.sql
    │   ├── 003_ordenes.sql
    │   ├── 004_compras.sql
    │   ├── 005_indices.sql
    │   └── 006_vistas.sql
    └── seed/
        ├── 01_semilla.sql
        └── 02_rechazos.sql
```

---

## Estado de las entregas

**Entrega 1**
- [x] Planteamiento, requisitos y supuestos
- [x] Diagrama EER
- [x] Esquema relacional
- [x] Diccionario de datos inicial

**Entrega 2**
- [x] Esquema en SQL (DDL) con migraciones numeradas
- [x] Restricciones con nombre propio y políticas `ON DELETE` justificadas
- [x] Datos de prueba e índices
- [x] Demostración de rechazos (`seed/02_rechazos.sql`)
- [x] Normalización y banco de consultas
- [x] Declaración de uso de IA
- [ ] Diccionario de datos actualizado (pendiente)

---

## Herramientas utilizadas

- PostgreSQL 16+ (`psql`)
- Git + GitHub
- Draw.io / diagrams.net (diagrama EER)
- Markdown
