# AI-LOG.md
# Bitácora de uso de Inteligencia Artificial
## Examen Técnico Oracle PL/SQL – Core Bancario

**Proyecto:** oraclecore-Alexander  
**Herramienta de IA:** ChatGPT (OpenAI)  
**Motor de base de datos:** Oracle Database Free  
**Cliente SQL:** Oracle SQL Developer  
**Control de versiones:** Git y GitHub  
**Esquema de trabajo:** CORE_DEV  

---

## 1. Objetivo del uso de inteligencia artificial

Se utilizó ChatGPT como asistente técnico durante el desarrollo del examen Oracle PL/SQL para apoyar el análisis de requerimientos, diseño de objetos de base de datos, construcción de código PL/SQL, revisión de errores y elaboración de pruebas.

La IA se utilizó como herramienta de apoyo y no como sustituto de la validación técnica. Las implementaciones propuestas fueron trasladadas a Oracle SQL Developer, ejecutadas, compiladas y verificadas por el desarrollador.

El trabajo se realizó de manera incremental, validando cada sección antes de continuar con la siguiente.

## 2. Preparación del entorno de desarrollo

Se utilizó asistencia de IA para revisar la preparación del equipo y configurar el entorno de desarrollo.

Actividades realizadas:

- Verificación de compatibilidad del equipo.
- Instalación y configuración de Oracle Database Free.
- Configuración de la conexión local mediante `localhost:1521/FREEPDB1`.
- Configuración de Oracle SQL Developer.
- Preparación de Git y conexión con GitHub.
- Organización de la estructura inicial del repositorio.

La ejecución y comprobación de las instalaciones se realizaron directamente en el equipo del desarrollador.

## 3. Desarrollo de la sección A — Catálogos parametrizables

### 3.1. A.1 — Modelo de datos

Se utilizó ChatGPT como apoyo para estructurar las tablas:

- TTEM_CATALOG.
- TTEM_ITEM.

Se definieron claves primarias, relaciones, restricciones de unicidad, validaciones de estado y reglas de vigencia.

Se incorporaron los datos iniciales obligatorios:

- Catálogo MONEDA: PEN y USD.
- Catálogo TIPO_COMISION: COM_MANT.

Se contemplaron campos de auditoría de creación y modificación en el modelo.

**Decisión técnica:** mantener separados los catálogos y sus ítems para facilitar su administración y reutilización.

### 3.2. A.2 — Package y Object Types

Se utilizó IA para desarrollar progresivamente:

- PKG_TTEM_CATALOG, especificación y cuerpo.
- TYP_TTEM_ITEM.
- TYP_TTEM_ITEM_TAB.
- Operaciones de inserción, actualización, eliminación y consulta.

Se implementó la eliminación lógica de ítems.

**Justificación:** conservar el registro histórico y evitar la eliminación física de información que puede ser necesaria para consultas o trazabilidad.

Se utilizó el enfoque Walking Skeleton: primero se logró un package compilable y posteriormente se incorporaron funcionalidades y validaciones.

### 3.3. A.3 — Validaciones y excepciones propias

ChatGPT apoyó la definición de validaciones de negocio y códigos de error propios.

La implementación contempla:

| Código | Excepción | Descripción |
|---|---|---|
| -20001 | e_catalogo_no_existe | Catálogo inexistente |
| -20002 | e_item_no_existe | Ítem inexistente |
| -20003 | e_codigo_item_duplicado | Código de ítem duplicado |
| -20004 | e_vigencia_invalida | Vigencia incorrecta |
| -20005 | e_datos_incompletos | Datos obligatorios incompletos |
| -20006 | e_estado_invalido | Estado no permitido |
| -20007 | e_item_id_duplicado | Identificador duplicado |

Se verificaron escenarios de inserción, actualización, eliminación, duplicidad, catálogo inexistente, fechas inválidas, datos incompletos y estados no permitidos.

**Decisión técnica:** utilizar excepciones propias mediante `RAISE_APPLICATION_ERROR` para distinguir los errores de negocio de los errores técnicos de Oracle.

### 3.4. A.4 — Consulta JSON por ItemId

Se utilizó IA para implementar el procedimiento:

`PKG_TTEM_CATALOG.OBTENER_ITEM_JSON`

Se utilizó `JSON_OBJECT` para construir el documento JSON y devolverlo mediante un parámetro CLOB.

Se contemplaron:

- Nombres exactos de los atributos solicitados.
- Fechas con formato YYYY-MM-DD.
- Representación de valores nulos mediante NULL ON NULL.
- Excepción propia cuando el identificador no existe.

El resultado fue ejecutado y comprobado en Oracle SQL Developer.

## 4. Desarrollo de la sección B — Consulta de clientes

Se utilizó ChatGPT como apoyo para elaborar la consulta por número de cuenta, utilizando las tablas del modelo Core Bancario.

La implementación contempla:

- Información de cuenta y producto.
- Moneda, saldo y estado.
- Identificación y tipo de persona del cliente.
- Normalización de nombres.
- Fecha de nacimiento o constitución.
- Tipo de fecha de referencia.
- Consolidación de usuarios OLB mediante LISTAGG.

Se utilizó una variable de sustitución para recibir el número de cuenta.

Se ejecutaron satisfactoriamente los cinco escenarios establecidos en el examen:

1. Persona natural con fecha de nacimiento y usuario OLB.
2. Persona natural sin fecha de nacimiento ni usuarios OLB.
3. Persona jurídica con dos usuarios OLB, uno bloqueado.
4. Persona jurídica sin fecha de constitución y cuenta bloqueada.
5. Cuenta inexistente.

**Decisión técnica:** consolidar los usuarios OLB en una consulta agrupada para evitar duplicar filas de las cuentas cuando un cliente posee varios usuarios.

La cuenta inexistente devuelve cero filas, sin generar una excepción Oracle.

## 5. Desarrollo de la sección C — Transferencias bancarias

Se utilizó ChatGPT para diseñar e implementar un package independiente:

`PKG_CORE_SETTLEMENT`

Procedimiento principal:

`TRANSFERIR`

Se implementaron los siguientes controles:

- Monto positivo y con máximo dos decimales.
- Validación de cuentas existentes y diferentes.
- Validación del estado activo de ambas cuentas.
- Validación de moneda.
- Validación de saldo suficiente.
- Control de referencias duplicadas.
- Bloqueo de cuentas mediante SELECT FOR UPDATE.
- Bloqueo en orden consistente para reducir el riesgo de deadlocks.
- Débito y acreditación.
- Registro del movimiento en CORE_TRX.
- Simulación de fallas.
- Recuperación mediante SAVEPOINT y ROLLBACK TO SAVEPOINT.

### 5.1. Decisión sobre el control transaccional

Se decidió que el procedimiento no ejecute COMMIT.

El procedimiento establece un SAVEPOINT y, ante una excepción, ejecuta ROLLBACK TO SAVEPOINT y vuelve a lanzar el error mediante RAISE.

El invocador controla la confirmación o reversión final de la transacción.

**Justificación:** evitar que el procedimiento confirme accidentalmente otras operaciones pendientes de la sesión que lo invoca.

### 5.2. Códigos de error de transferencias

| Código | Descripción |
|---|---|
| -20101 | Monto inválido |
| -20102 | Cuentas de origen y destino iguales |
| -20103 | Cuenta inexistente o error en actualización |
| -20104 | Una de las cuentas no está activa |
| -20105 | Moneda incompatible |
| -20106 | Saldo insuficiente |
| -20107 | Referencia duplicada |
| -20108 | Falla simulada |
| -20109 | Parámetros obligatorios o indicadores inválidos |

### 5.3. Pruebas ejecutadas

Se creó el archivo `scripts/pruebas_transferencia.sql` y se ejecutaron seis escenarios:

| Prueba | Resultado |
|---|---|
| Transferencia exitosa de 100 PEN | TRX_ID 1000 |
| Referencia duplicada | -20107 |
| Saldo insuficiente | -20106 |
| Moneda distinta | -20105 |
| Cuenta bloqueada | -20104 |
| Falla simulada y rollback | -20108 |

Se comprobó la atomicidad mediante la simulación de una falla después del débito y antes de la acreditación.

Saldos verificados después de la falla:

- Cuenta 1910001000011: 5,150.00 PEN.
- Cuenta 1910002000017: 450.50 PEN.
- Movimientos registrados con REF-T002: cero.

Las seis pruebas finalizaron correctamente.

## 6. Revisión crítica y correcciones del código generado

El código propuesto por IA fue revisado y ajustado durante su integración.

Entre las revisiones realizadas se encuentran:

- Incorporación de controles mediante SQL%ROWCOUNT para detectar actualizaciones o eliminaciones de registros inexistentes.
- Diferenciación entre excepciones de negocio y errores técnicos.
- Validación de existencia de catálogo e ítem antes de operar.
- Revisión de parámetros y vigencias.
- Uso de SAVEPOINT y ROLLBACK TO SAVEPOINT en la transferencia.
- Relanzamiento de excepciones mediante RAISE.
- Verificación de referencias duplicadas.
- Comprobación de que las fallas no dejen movimientos parciales.

No se aceptó el uso de `WHEN OTHERS THEN NULL` ni el ocultamiento de errores.

La ejecución y validación final del código se realizó en Oracle SQL Developer.

## 7. Prompts representativos y resultados de IA

Durante el desarrollo se utilizaron instrucciones iterativas en ChatGPT. A continuación se registran solicitudes textuales disponibles en el historial de trabajo, junto con los resultados generados y las acciones realizadas por el desarrollador.

### 7.1. Preparación del entorno

**Prompt utilizado:**

> Ayúdame a revisar paso a paso si mi computadora está lista con Oracle para el examen de mañana.

**Resultado de IA:** guía para verificar el equipo, preparar Oracle Database, configurar la conexión local y utilizar SQL Developer.

**Acción del desarrollador:** realizó las verificaciones en su computadora, instaló Oracle Database Free y configuró la conexión CORE_DEV mediante localhost:1521/FREEPDB1.

### 7.2. Selección de instalación

**Instrucción del desarrollador:**

> ya tengo git solo falta la configuracion , me ire por el exe de oracle , no docker

**Resultado de IA:** adaptación de las instrucciones de instalación y configuración al uso de Oracle mediante instalador ejecutable, sin utilizar Docker.

**Acción del desarrollador:** continuó con la instalación local y la configuración de SQL Developer.

### 7.3. Validaciones y mantenimiento de catálogos

**Trabajo realizado:** desarrollo iterativo de las tablas TTEM_CATALOG y TTEM_ITEM, Object Types y package PKG_TTEM_CATALOG.

**Resultado de IA:** propuestas de DDL, especificación y cuerpo del package, procedimientos CRUD, validaciones de existencia y excepciones propias.

**Acción del desarrollador:** ejecutó los scripts en SQL Developer, verificó compilaciones y probó inserciones, actualizaciones, eliminaciones lógicas, duplicados, vigencias inválidas y registros inexistentes.

Como corrección al código inicialmente propuesto se incorporó SQL%ROWCOUNT para comprobar que las operaciones de actualización y eliminación afectaran registros existentes.

### 7.4. Consulta JSON por ItemId

**Trabajo realizado:** implementación del procedimiento OBTENER_ITEM_JSON.

**Resultado de IA:** propuesta de utilización de JSON_OBJECT, parámetro de salida CLOB, formato de fechas YYYY-MM-DD y tratamiento de valores nulos.

**Acción del desarrollador:** compiló y ejecutó el procedimiento en Oracle SQL Developer. Comprobó el JSON correspondiente al ItemId 2 y su representación de validTo como null.

### 7.5. Consulta de clientes — Sección B

**Trabajo realizado:** desarrollo de la consulta SQL por número de cuenta.

**Resultado de IA:** consulta con JOIN, normalización de nombres, CASE para fecha de nacimiento o constitución y LISTAGG para consolidar usuarios OLB.

**Acción del desarrollador:** ejecutó los cinco escenarios del examen y compartió los resultados para su revisión. Se verificaron los casos de personas naturales, jurídicas, usuarios activos y bloqueados, fechas faltantes y cuenta inexistente.

### 7.6. Transferencias bancarias — Sección C

**Trabajo realizado:** diseño e implementación del package PKG_CORE_SETTLEMENT.

**Resultado de IA:** especificación, cuerpo del package, validaciones de negocio, bloqueo mediante SELECT FOR UPDATE, control de referencias duplicadas y manejo transaccional con SAVEPOINT y ROLLBACK TO SAVEPOINT.

**Acción del desarrollador:** compiló el package y ejecutó las seis pruebas funcionales mediante scripts SQL.

Se comprobó especialmente la falla simulada después del débito y antes del crédito. El resultado confirmó que los saldos se restauraron y que no quedó registrado un movimiento con REF-T002.

### 7.7. Documentación y control de versiones

**Prompts textuales utilizados:**

> vamos con el commit y lo del readme agregarlo

> recuerda que tmabine tenemos que subir los de setuo

> dame todo el redmi completo

> dame todo el status

> AI-LOG.MD agregarle desde el inicio

**Resultado de IA:** instrucciones para actualizar README.md, STATUS.md y AI-LOG.md, conservar los scripts setup del examen y ejecutar los comandos de Git para preparar commits y sincronizar GitHub.

**Acción del desarrollador:** editó y guardó los archivos, ejecutó los comandos de Git, resolvió un conflicto de README.md durante un rebase y publicó los cambios en el repositorio.

### 7.8. Observación sobre la transcripción de prompts técnicos

Las solicitudes de las secciones A.1 a A.4, B y C se realizaron mediante múltiples intercambios técnicos. En esta bitácora se documentan sus objetivos, resultados y validaciones. Las frases entrecomilladas corresponden únicamente a mensajes textuales que se pudieron recuperar del historial disponible; los demás apartados son resúmenes de las interacciones, no transcripciones literales.

### 7.9. Evaluación del resultado del uso de IA

La IA aceleró la elaboración de estructuras SQL, procedimientos PL/SQL, consultas y documentación.

El desarrollador mantuvo la responsabilidad de instalar el entorno, ejecutar los scripts, verificar compilaciones, interpretar los errores, validar los resultados y decidir qué implementaciones incorporar al repositorio.

El uso de IA fue iterativo: se revisaron las propuestas, se solicitaron correcciones y se comprobaron los resultados directamente en Oracle Database.

## 8. Participación aproximada de IA y desarrollador

La IA participó principalmente en la generación inicial de estructuras, consultas y bloques PL/SQL, así como en la revisión de errores.

El desarrollador realizó:

- Preparación y configuración del entorno.
- Integración de los scripts en el esquema CORE_DEV.
- Ejecución y compilación de los objetos.
- Revisión de resultados.
- Ejecución de las pruebas funcionales.
- Validación de saldos y movimientos.
- Organización del repositorio y control de versiones.
- Revisión y aceptación de las decisiones técnicas.

Estimación inicial de participación:

- Código generado con asistencia de IA: aproximadamente 80%.
- Código escrito, adaptado, integrado y validado por el desarrollador: aproximadamente 20%.

Esta proporción es estimativa y debe ajustarse a la contribución real de cada parte antes de la entrega definitiva.

## 9. Estado del alcance

| Sección                          | Estado               |
| -------------------------------- | -------------------- |
| A.1 — Modelo de catálogos        | Hecho                |
| A.2 — Package y Object Types     | Hecho                |
| A.3 — Validaciones y excepciones | Hecho                |
| A.4 — Consulta JSON              | Hecho                |
| B — Consulta de clientes         | Hecho                |
| C — Transferencias               | Hecho y probado      |
| D — Propuesta técnica            | Hecho                |
| A.5 — Carga masiva               | No implementado (P2) |

## 10. Compromiso de transparencia

El uso de inteligencia artificial se realizó como apoyo al desarrollo técnico y al aprendizaje de las decisiones de implementación.

El desarrollador verificó las implementaciones directamente en Oracle, ejecutó los casos de prueba y revisó el comportamiento de los procedimientos antes de incorporarlos al repositorio.

Las funcionalidades pendientes se declararán expresamente en STATUS.md y README.md.