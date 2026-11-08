# Examen Técnico Oracle PL/SQL - Core Bancario

## 1. Descripción del proyecto

Implementación de una solución Oracle PL/SQL para el mantenimiento de catálogos parametrizables, consulta de información de clientes por número de cuenta y procesamiento de transferencias bancarias.

El proyecto forma parte del examen técnico para el puesto de Desarrollador(a) Oracle PL/SQL – Core Bancario.

**Repositorio:** [oraclecore-Alexander](https://github.com/alexanderaa16-coder/oraclecore-Alexander)

## 2. Avance actual

|Sección|Descripción|Estado|
|---|---|---|
|A.1|Modelo de catálogos TTEM_CATALOG y TTEM_ITEM|Hecho|
|A.2|Package de mantenimiento y Object Types|Hecho|
|A.3|Validaciones y excepciones propias|Hecho|
|A.4|Consulta JSON por ItemId|Hecho|
|B|Consulta de cliente por número de cuenta|Hecho|
|C|Transferencias y control de atomicidad|Hecho y probado|
|D|Propuesta técnica de mejora|Pendiente|
|A.5|Procesamiento masivo BULK COLLECT y FORALL|No implementado (P2)|

## 3. Herramientas y entorno

- Motor de base de datos: Oracle Database Free.
    
- Cliente SQL: Oracle SQL Developer.
    
- Control de versiones: Git y GitHub.
    
- Esquema de trabajo: CORE_DEV.
    
- Host de conexión: localhost.
    
- Puerto: 1521.
    
- Servicio: FREEPDB1.
    

Para consultar la versión exacta del motor:

```
SELECT * FROM V$VERSION;
```

La versión obtenida debe quedar registrada en la entrega definitiva.

## 4. Estructura del proyecto

```
oraclecore-Alexander/
│
├── setup/
│   ├── 01_core_ddl.sql
│   └── 02_core_datos.sql
│
├── ddl/
│   ├── 01_ttem_tables.sql
│   └── 02_ttem_types.sql
│
├── plsql/
│   ├── pkg_ttem_catalog.pks
│   ├── pkg_ttem_catalog.pkb
│   ├── pkg_core_settlement.pks
│   └── pkg_core_settlement.pkb
│
├── scripts/
│   ├── consulta_cliente.sql
│   └── pruebas_transferencia.sql
│
├── README.md
├── AI-LOG.md
├── STATUS.md
└── connection.env.example
```

## 5. Instalación y orden de ejecución

### 5.1. Preparación del esquema Core Bancario

Conectarse desde Oracle SQL Developer al esquema CORE_DEV.

Ejecutar los siguientes scripts en este orden:

**Primero: creación de tablas del Core**

```
setup/01_core_ddl.sql
```

**Segundo: carga de datos de prueba**

```
setup/02_core_datos.sql
```

Estos scripts corresponden al modelo Core Bancario del examen.

Importante: ejecutar el script de datos una sola vez sobre un esquema limpio para evitar registros duplicados.

### 5.2. Modelo de catálogos TTEM

Ejecutar:

```
ddl/01_ttem_tables.sql
ddl/02_ttem_types.sql
```

Se crean las tablas de catálogos e ítems, sus restricciones y los Object Types.

### 5.3. Package de mantenimiento de catálogos

Ejecutar en el siguiente orden:

```
plsql/pkg_ttem_catalog.pks
plsql/pkg_ttem_catalog.pkb
```

Primero se compila la especificación y posteriormente el cuerpo del package.

### 5.4. Package de transferencias

Ejecutar:

```
plsql/pkg_core_settlement.pks
plsql/pkg_core_settlement.pkb
```

Primero se compila la especificación y después el cuerpo del package.

### 5.5. Ejecución de consultas y pruebas

Los siguientes scripts se ejecutan desde Oracle SQL Developer:

```
scripts/consulta_cliente.sql
scripts/pruebas_transferencia.sql
```

En SQL Developer se utiliza F5 para ejecutar los scripts completos.

## 6. Sección A — Catálogos parametrizables

### 6.1. A.1 — Modelo de datos

Se implementaron las tablas:

- TTEM_CATALOG.
    
- TTEM_ITEM.
    

Se incorporaron claves primarias, relaciones, restricciones de unicidad y validaciones correspondientes al modelo.

Se incluyeron los datos iniciales obligatorios:

|Catálogo|Código|Descripción|
|---|---|---|
|MONEDA|PEN|Sol peruano|
|MONEDA|USD|Dólar estadounidense|
|TIPO_COMISION|COM_MANT|Comisión de mantenimiento|

### 6.2. A.2 — Package y Object Types

Se implementó el package:

`PKG_TTEM_CATALOG`

Se desarrollaron las operaciones de mantenimiento de ítems mediante procedimientos de inserción, actualización, eliminación y consulta.

Se crearon los siguientes Object Types:

- TYP_TTEM_ITEM.
    
- TYP_TTEM_ITEM_TAB.
    

**Decisión técnica: eliminación lógica**

Se utiliza eliminación lógica mediante actualización del estado del ítem.

Esta decisión permite conservar los registros para mantener trazabilidad y evitar la pérdida de información histórica.

### 6.3. A.3 — Validaciones y excepciones propias

Se implementaron validaciones para:

- Existencia del catálogo.
    
- Existencia del ítem.
    
- Datos obligatorios.
    
- Códigos de ítem duplicados.
    
- Identificadores duplicados.
    
- Coherencia de fechas de vigencia.
    
- Estados permitidos.
    
- Actualización de registros inexistentes.
    
- Eliminación de registros inexistentes.
    

Tabla de excepciones propias:

|Código|Excepción|Descripción|
|---|---|---|
|-20001|e_catalogo_no_existe|El catálogo no existe|
|-20002|e_item_no_existe|El ítem no existe|
|-20003|e_codigo_item_duplicado|Código de ítem duplicado|
|-20004|e_vigencia_invalida|Vigencia incorrecta|
|-20005|e_datos_incompletos|Datos obligatorios incompletos|
|-20006|e_estado_invalido|Estado no permitido|
|-20007|e_item_id_duplicado|Identificador de ítem duplicado|

Se realizaron pruebas de las validaciones y se comprobó la respuesta de las excepciones mediante Oracle SQL Developer.

### 6.4. A.4 — Consulta JSON por ItemId

Se implementó el procedimiento:

`PKG_TTEM_CATALOG.OBTENER_ITEM_JSON`

El procedimiento recibe un identificador de ítem y devuelve un documento JSON mediante un parámetro CLOB.

Se utiliza JSON_OBJECT, sin concatenación manual del documento.

El resultado contiene los siguientes atributos:

- itemId
    
- catalogId
    
- catalogCode
    
- itemCode
    
- name
    
- value
    
- status
    
- validFrom
    
- validTo
    

Las fechas se presentan en formato YYYY-MM-DD y los valores nulos se representan mediante NULL ON NULL.

**Ejemplo de ejecución:**

```
SET SERVEROUTPUT ON;

DECLARE
    l_json CLOB;
BEGIN
    PKG_TTEM_CATALOG.OBTENER_ITEM_JSON(
        p_item_id => 2,
        p_json    => l_json
    );

    DBMS_OUTPUT.PUT_LINE(
        DBMS_LOB.SUBSTR(l_json, 4000, 1)
    );
END;
/
```

**Salida obtenida en las pruebas:**

```
{
  "itemId": 2,
  "catalogId": 1,
  "catalogCode": "MONEDA",
  "itemCode": "USD",
  "name": "Dólar estadounidense",
  "value": "USD",
  "status": "A",
  "validFrom": "2026-01-01",
  "validTo": null
}
```

Cuando el ItemId no existe, el procedimiento genera la excepción propia correspondiente.

## 7. Sección B — Consulta de cliente por número de cuenta

**Archivo:** `scripts/consulta_cliente.sql`

Se implementó una consulta SQL que recibe un número de cuenta mediante una variable de sustitución.

La consulta relaciona las tablas CORE_ACCOUNT, CORE_CUSTOMER y OLB_USER.

### Información devuelta

**Datos de la cuenta:**

- Número de cuenta.
    
- Tipo de producto.
    
- Moneda.
    
- Saldo.
    
- Estado.
    

**Datos del cliente:**

- Identificador del cliente.
    
- Tipo de persona: Natural o Jurídica.
    
- Tipo y número de documento.
    
- Nombre normalizado.
    

**Fecha de referencia:**

- Fecha de nacimiento para personas naturales.
    
- Fecha de constitución para personas jurídicas.
    
- Tipo de fecha correspondiente.
    
- Cuando no existe fecha, se muestra vacía y el tipo indica No registrada.
    

**Usuarios de Banca en Línea:**

Se utiliza LISTAGG para consolidar los usuarios OLB del cliente en una única columna, incluyendo el estado de cada usuario.

Cuando un cliente no tiene usuarios OLB, la columna se presenta vacía.

### Casos de prueba ejecutados

|Número de cuenta|Escenario|Resultado|
|---|---|---|
|1910001000011|Persona natural con fecha de nacimiento y un usuario OLB|Correcto|
|1910002000017|Persona natural sin fecha de nacimiento ni usuarios OLB; nombre con espacios irregulares|Correcto|
|1910003000013|Persona jurídica con dos usuarios OLB, uno bloqueado|Correcto|
|1910004000019|Persona jurídica sin fecha de constitución y cuenta bloqueada|Correcto|
|9999999999999|Cuenta inexistente|Cero filas, sin error|

### Normalización de nombres

Se normalizan los espacios iniciales, finales y espacios internos redundantes para presentar nombres legibles.

### Comportamiento ante cuenta inexistente

Cuando se introduce un número de cuenta que no existe, la consulta devuelve cero filas y termina normalmente, sin generar una excepción Oracle.

## 8. Sección C — Transferencias bancarias

**Estado: Hecho y probado.**

**Package:**

- `plsql/pkg_core_settlement.pks`
    
- `plsql/pkg_core_settlement.pkb`
    

**Script de pruebas:**

- `scripts/pruebas_transferencia.sql`
    

Se implementó el package `PKG_CORE_SETTLEMENT`, que contiene el procedimiento `TRANSFERIR`.

### 8.1. Reglas de negocio implementadas

- Validación de monto positivo y máximo dos decimales.
    
- Validación de existencia de ambas cuentas.
    
- Validación de cuentas de origen y destino diferentes.
    
- Validación de estado activo de ambas cuentas.
    
- Validación de moneda.
    
- Validación de saldo suficiente.
    
- Control de referencias duplicadas.
    
- Bloqueo de cuentas mediante SELECT FOR UPDATE.
    
- Bloqueo de cuentas en orden consistente para reducir el riesgo de deadlocks.
    
- Débito de la cuenta de origen.
    
- Acreditación de la cuenta de destino.
    
- Registro del movimiento en CORE_TRX.
    
- Identificador del movimiento obtenido mediante SEQ_CORE_TRX.
    
- Simulación de fallas y recuperación transaccional.
    

### 8.2. Control transaccional

El procedimiento utiliza SAVEPOINT para delimitar la operación.

Ante una excepción ejecuta ROLLBACK TO SAVEPOINT y vuelve a lanzar el error mediante RAISE.

El procedimiento no ejecuta COMMIT.

La confirmación o reversión final corresponde al invocador, permitiendo que la aplicación que consume el procedimiento controle la transacción.

**Justificación:** evitar que una operación interna confirme accidentalmente otras operaciones pendientes dentro de la misma sesión.

### 8.3. Códigos de error de transferencias

|Código|Descripción|
|---|---|
|-20101|Monto inválido|
|-20102|Cuenta de origen y destino iguales|
|-20103|Cuenta inexistente o error en actualización|
|-20104|Una de las cuentas no está activa|
|-20105|Moneda incompatible|
|-20106|Saldo insuficiente|
|-20107|Referencia duplicada|
|-20108|Falla simulada|
|-20109|Parámetros obligatorios o indicadores inválidos|

### 8.4. Pruebas funcionales ejecutadas

Se ejecutaron satisfactoriamente los siguientes escenarios:

|Prueba|Resultado esperado|Resultado obtenido|
|---|---|---|
|Transferencia exitosa de 100 PEN|Actualización de saldos y registro contable|TRX_ID 1000|
|Repetición de referencia REF-T001|Rechazo por duplicidad|-20107|
|Transferencia de 5,000 PEN sin saldo suficiente|Rechazo|-20106|
|Transferencia entre cuentas de distinta moneda|Rechazo|-20105|
|Transferencia a cuenta bloqueada|Rechazo|-20104|
|Falla simulada entre débito y crédito|Rollback completo|-20108|

### 8.5. Evidencia de atomicidad

Para comprobar la atomicidad se ejecutó una transferencia con `p_simular_falla = 'S'`.

El procedimiento provocó una excepción después de realizar el débito y antes de ejecutar la acreditación.

Se verificó que el saldo de origen fue restaurado y que no quedó un movimiento contable parcial.

**Resultados comprobados:**

|Concepto|Resultado|
|---|---|
|Cuenta origen: 1910001000011|5,150.00 PEN|
|Cuenta destino: 1910002000017|450.50 PEN|
|Movimientos con referencia REF-T001|1|
|Movimientos con referencia REF-T002|0|

La prueba confirma que el ROLLBACK TO SAVEPOINT deshace el débito cuando ocurre la falla simulada.

## 9. Sección D — Propuesta técnica de mejora

**Estado: Pendiente de elaboración.**

Se documentará una propuesta para automatizar el mantenimiento de catálogos, incluyendo el flujo de solicitud, validación, aprobación por un segundo responsable, registro de auditoría y mecanismo de reversión.

La propuesta final se incorporará en esta sección, respetando el máximo de 20 líneas establecido en el examen.

## 10. Sección A.5 — Procesamiento masivo

**Estado: No implementado.**

Esta sección tiene prioridad P2 y se considera opcional frente a la finalización y documentación de los requisitos P0 y P1.

La solución prevista contempla:

- BULK COLLECT con LIMIT.
    
- FORALL con SAVE EXCEPTIONS.
    
- Normalización de datos.
    
- Validación de registros.
    
- Registro de rechazos.
    
- Control del resultado de carga y procesamiento del lote.
    

## 11. Uso de inteligencia artificial

Se utilizó ChatGPT como asistente durante el análisis, diseño, generación y revisión de componentes SQL y PL/SQL.

El desarrollador ejecutó y verificó los scripts en Oracle SQL Developer, revisó los resultados de las operaciones y realizó las pruebas funcionales.

Las decisiones técnicas, prompts representativos, correcciones y porcentaje estimado de participación se documentan en `AI-LOG.md`.

## 12. Estado de entrega

|Elemento|Estado|
|---|---|
|Modelo TTEM|Completado|
|Package de catálogos|Completado|
|Validaciones y excepciones|Completado|
|Procedimiento JSON|Completado|
|Consulta de clientes|Completado|
|Package de transferencias|Completado|
|Pruebas funcionales de transferencias|Completadas|
|Documentación de sección D|Pendiente|
|Procesamiento masivo A.5|No implementado|
|Revisión final de documentación|Pendiente|

## 13. Control de versiones

El proyecto utiliza Git y GitHub para mantener un historial incremental de los cambios y entregas.

Repositorio:

[https://github.com/alexanderaa16-coder/oraclecore-Alexander](https://github.com/alexanderaa16-coder/oraclecore-Alexander)

Los commits documentan la evolución del modelo, la implementación de los packages, las validaciones, las consultas y las pruebas realizadas.