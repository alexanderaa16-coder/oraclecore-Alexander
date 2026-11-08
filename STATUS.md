# Estado del proyecto — Examen Técnico Oracle PL/SQL

**Proyecto:** oraclecore-Alexander
**Esquema:** CORE_DEV
**Motor:** Oracle Database Free
**Cliente SQL:** Oracle SQL Developer
**Repositorio:** [https://github.com/alexanderaa16-coder/oraclecore-Alexander](https://github.com/alexanderaa16-coder/oraclecore-Alexander)

---

## 1. Resumen general

El proyecto implementa funcionalidades de mantenimiento de catálogos, consulta de clientes por número de cuenta y transferencias bancarias utilizando Oracle PL/SQL.

Se ha completado la implementación y validación funcional de los requisitos A.1, A.2, A.3, A.4, B y C.

La propuesta técnica de la sección D ha sido elaborada y está pendiente de incorporación definitiva a la documentación.

La sección A.5, correspondiente al procesamiento masivo, no fue implementada por tratarse de una prioridad P2.

## 2. Estado de los requisitos

| Requisito                        | Estado   | Observaciones                                                                                    |
| -------------------------------- | -------- | ------------------------------------------------------------------------------------------------ |
| A.1 — Modelo de catálogos        | Hecho    | Tablas TTEM_CATALOG y TTEM_ITEM, constraints y datos iniciales.                                  |
| A.2 — Package y Object Types     | Hecho    | PKG_TTEM_CATALOG, CRUD y Object Types compilados.                                                |
| A.3 — Validaciones y excepciones | Hecho    | Validaciones de existencia, duplicidad, datos obligatorios, vigencias y estados.                 |
| A.4 — Consulta JSON              | Hecho    | Procedimiento OBTENER_ITEM_JSON con salida CLOB y manejo de ítem inexistente.                    |
| B — Consulta de clientes         | Hecho    | Consulta por número de cuenta y cinco escenarios ejecutados correctamente.                       |
| C — Transferencias               | Hecho    | Package PKG_CORE_SETTLEMENT y seis escenarios de prueba satisfactorios.                          |
| D — Propuesta técnica            | Hecho    | Propuesta documentada en README.md: automatización, aprobación, auditoría, reversión y métricas. |
| A.5 — Carga masiva               | No hecho | No implementado. Prioridad P2.                                                                   |

## 3. Evidencias de implementación

### A.1 — Modelo de catálogos

- Creación de TTEM_CATALOG.

- Creación de TTEM_ITEM.

- Restricciones y relaciones.

- Datos iniciales de MONEDA y TIPO_COMISION.


**Archivos:**

- `ddl/01_ttem_tables.sql`

- `ddl/02_ttem_types.sql`


### A.2 — Package de mantenimiento

- Especificación y cuerpo de PKG_TTEM_CATALOG.

- Object Type TYP_TTEM_ITEM.

- Colección TYP_TTEM_ITEM_TAB.

- Operaciones de mantenimiento.

- Eliminación lógica de ítems.


**Archivos:**

- `plsql/pkg_ttem_catalog.pks`

- `plsql/pkg_ttem_catalog.pkb`


### A.3 — Validaciones

Se probaron los siguientes escenarios:

- Catálogo inexistente.

- Ítem inexistente.

- Código de ítem duplicado.

- Identificador duplicado.

- Vigencia inválida.

- Datos obligatorios incompletos.

- Estado no permitido.

- Actualización y eliminación de registros inexistentes.


Se utilizaron excepciones propias mediante RAISE_APPLICATION_ERROR.

### A.4 — Consulta JSON

Se implementó y ejecutó:

`PKG_TTEM_CATALOG.OBTENER_ITEM_JSON`

Se verificó la salida CLOB, los atributos requeridos, las fechas con formato YYYY-MM-DD y la representación de valores nulos mediante JSON.

### B — Consulta de clientes

Archivo:

`scripts/consulta_cliente.sql`

Casos ejecutados:

|Cuenta|Escenario|Resultado|
|---|---|---|
|1910001000011|Natural con fecha y usuario OLB|Correcto|
|1910002000017|Natural sin fecha ni usuarios OLB|Correcto|
|1910003000013|Jurídica con dos usuarios OLB|Correcto|
|1910004000019|Jurídica bloqueada y sin fecha|Correcto|
|9999999999999|Cuenta inexistente|Cero filas, sin error|

### C — Transferencias bancarias

Package implementado:

`PKG_CORE_SETTLEMENT`

Procedimiento:

`TRANSFERIR`

Archivos:

- `plsql/pkg_core_settlement.pks`

- `plsql/pkg_core_settlement.pkb`

- `scripts/pruebas_transferencia.sql`


Se implementaron validaciones de monto, cuentas, moneda, saldo, referencia única y estado de las cuentas.

Se utilizó SELECT FOR UPDATE con orden consistente para bloquear las cuentas.

Se implementó SAVEPOINT y ROLLBACK TO SAVEPOINT para el manejo de errores. El procedimiento no ejecuta COMMIT; el invocador controla la transacción.

#### Resultados de las pruebas

|Caso|Resultado|
|---|---|
|Transferencia exitosa de 100 PEN|TRX_ID 1000|
|Referencia duplicada|-20107|
|Saldo insuficiente|-20106|
|Moneda distinta|-20105|
|Cuenta bloqueada|-20104|
|Falla simulada y rollback|-20108|

#### Verificación de atomicidad

Después de ejecutar la falla simulada entre el débito y el crédito:

|Cuenta|Saldo verificado|
|---|---|
|1910001000011|5,150.00 PEN|
|1910002000017|450.50 PEN|

Movimientos registrados con referencia REF-T002: **0**.

La prueba confirmó que no quedó un débito parcial ni un movimiento contable incompleto.

## 4. Sección D — Propuesta técnica

**Estado: Parcial.**

Se elaboró una propuesta para automatizar el mantenimiento de catálogos, considerando:

- Solicitud electrónica de cambios.

- Validaciones automáticas.

- Aprobación por un segundo responsable.

- Separación de funciones.

- Registro de auditoría.

- Ejecución controlada mediante PKG_TTEM_CATALOG.

- Mecanismo de reversión.

- Identificación de riesgos y dependencias.

- Indicadores de medición.


Pendiente: incorporar la versión definitiva en README.md y verificar el límite de 20 líneas solicitado en el examen.

## 5. Sección A.5 — Procesamiento masivo

**Estado: No hecho.**

No se implementó el procesamiento del lote LOTE-2026-10.

La solución prevista contempla:

- BULK COLLECT con LIMIT.

- FORALL con SAVE EXCEPTIONS.

- Normalización de datos.

- Validación individual de registros.

- Registro de errores por registro.

- Control de registros cargados y rechazados.


Se priorizó completar y validar los requisitos P0 y P1.

## 6. Documentación y entrega

|Elemento|Estado|Observaciones|
|---|---|---|
|README.md|En revisión|Documentación de A, B y C; incorporar versión definitiva de D.|
|AI-LOG.md|En revisión|Documentar decisiones, prompts representativos y participación de IA.|
|STATUS.md|En actualización|Estado de avance del proyecto.|
|connection.env.example|Preparado|Plantilla sin credenciales reales.|
|Scripts setup|Incluidos|DDL y datos oficiales del Core Bancario.|
|GitHub|Sincronizado hasta sección C|Commit 82437f7 publicado en main.|

## 7. Pendientes para el cierre

1. Incorporar la propuesta definitiva de la sección D en README.md.

2. Revisar la bitácora AI-LOG.md, incluidos prompts representativos y estimación de participación de IA.

3. Verificar la versión exacta de Oracle Database utilizada.

4. Confirmar que todos los scripts están incluidos en el repositorio.

5. Revisar README.md, AI-LOG.md y STATUS.md.

6. Ejecutar git diff --cached --check antes de cada commit.

7. Realizar el commit de documentación y sincronizar GitHub.

8. Verificar el estado final del repositorio.


## 8. Declaración de alcance

Los requisitos A.1, A.2, A.3, A.4, B y C fueron implementados y probados en Oracle SQL Developer.

La sección D cuenta con una propuesta elaborada, pendiente de incorporación definitiva en la documentación.

La sección A.5 no fue implementada por su prioridad P2.

El alcance pendiente se declara expresamente para mantener la transparencia de la entrega técnica.