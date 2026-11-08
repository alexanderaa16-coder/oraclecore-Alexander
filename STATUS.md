
# Estado del proyecto — Examen Oracle PL/SQL

| Requisito | Estado | Observaciones |
|---|---|---|
| A.1 — Modelo de catálogos | Hecho | Tablas TTEM_CATALOG y TTEM_ITEM con datos iniciales. |
| A.2 — Package y Object Types | Hecho | CRUD y tipos de objetos compilados. |
| A.3 — Validaciones | Hecho | Excepciones propias y validaciones de negocio probadas. |
| A.4 — Consulta JSON | Hecho | Procedimiento JSON por ItemId con manejo de inexistencia. |
| B — Consulta de clientes | Hecho | Cinco escenarios de prueba ejecutados correctamente. |
| C — Transferencias | Hecho | Seis escenarios probados, incluida atomicidad. |
| D — Propuesta técnica | Pendiente | Falta elaborar y documentar la propuesta. |
| A.5 — Carga masiva | No hecho | Prioridad P2; implementación opcional según tiempo. |

## Evidencias de ejecución

- Compilación de PKG_TTEM_CATALOG.
- Compilación de PKG_CORE_SETTLEMENT.
- Consultas de clientes por número de cuenta.
- Pruebas de transferencias y manejo de errores.
- Prueba de falla simulada con rollback completo.

## Pendientes

- Completar la propuesta técnica de la sección D.
- Revisar AI-LOG.md.
- Verificar README.md y estructura del repositorio.
- Registrar commit final y validar GitHub.
