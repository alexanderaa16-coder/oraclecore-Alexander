

# Examen Técnico Oracle PL/SQL - Core Bancario



## 1. Descripción del proyecto



Implementación de una solución Oracle PL/SQL para el mantenimiento de catálogos, consulta de información de clientes por número de cuenta y operaciones de core bancario.



El proyecto utiliza Oracle Database Free y SQL Developer.



## 2. Avance actual



| Sección | Descripción | Estado |

|---|---|---|

| A.1 | Modelo TTEM\_CATALOG y TTEM\_ITEM, constraints y datos iniciales | Hecho |

| A.2 | Package PKG\_TTEM\_CATALOG, CRUD y Object Types | Hecho |

| A.3 | Validaciones de negocio y excepciones propias | Hecho |

| A.4 | Consulta de ítem mediante JSON y manejo de inexistencia | Hecho |

| B | Consulta de cliente por número de cuenta | Hecho |

| C | Transferencias entre cuentas y control transaccional | Pendiente |

| D | Propuesta técnica de mejora | Pendiente |

| A.5 | Carga masiva mediante BULK COLLECT y FORALL | Pendiente |


## 3. Herramientas utilizadas



- Motor de base de datos: Oracle Database Free.

- Cliente SQL: Oracle SQL Developer.

- Control de versiones: Git y GitHub.

- Esquema de trabajo: CORE\_DEV.

- Conexión local: localhost:1521/FREEPDB1.



La versión exacta de Oracle Database debe verificarse mediante:



```sql

SELECT \* FROM V$VERSION;

```



## 4. Estructura del proyecto



```text

oraclecore-Alexander/

│

├── setup/

│   ├── 01\_core\_ddl.sql

│   └── 02\_core\_datos.sql

│

├── ddl/

│   ├── 01\_ttem\_tables.sql

│   └── 02\_ttem\_types.sql

│

├── plsql/

│   ├── pkg\_ttem\_catalog.pks

│   └── pkg\_ttem\_catalog.pkb

│

├── scripts/

│   └── consulta\_cliente.sql

│

├── README.md

├── AI-LOG.md

├── STATUS.md

└── connection.env.example

```



## 5. Orden de ejecución



Conectarse al esquema CORE\_DEV desde SQL Developer.



Ejecutar los scripts en el siguiente orden:



### 5.1. Modelo Core Bancario



```text

setup/01\_core\_ddl.sql

setup/02\_core\_datos.sql

```



Estos scripts crean las tablas del modelo Core Bancario y cargan los datos de prueba.



Importante: ejecutar los scripts de datos una sola vez sobre un esquema limpio.



### 5.2. Modelo de catálogos TTEM



```text

ddl/01\_ttem\_tables.sql

ddl/02\_ttem\_types.sql

```



Se crean las tablas de catálogos e ítems, sus restricciones y los Object Types.



### 5.3. Package de mantenimiento



```text

plsql/pkg\_ttem\_catalog.pks

plsql/pkg\_ttem\_catalog.pkb

```



Ejecutar primero la especificación y posteriormente el cuerpo del package.



### 5.4. Consulta de clientes



```text

scripts/consulta\_cliente.sql

```



Ejecutar mediante SQL Developer utilizando F5 e introducir el número de cuenta solicitado.



## 6. Sección A — Mantenimiento de catálogos



### A.1. Modelo de datos



Se implementaron las tablas:



\- TTEM\_CATALOG

- TTEM\_ITEM



Se incluyeron restricciones y datos iniciales obligatorios:



- Catálogo MONEDA: PEN y USD.

- Catálogo TIPO\_COMISION: COM\_MANT.



### A.2. Package y Object Types



Se implementó PKG\_TTEM\_CATALOG con operaciones de mantenimiento de ítems.



Se crearon:



- TYP\_TTEM\_ITEM.

- TYP\_TTEM\_ITEM\_TAB.



La eliminación de ítems es lógica, utilizando el estado correspondiente.



### A.3. Validaciones y excepciones propias



Se implementaron validaciones para:



\- Existencia del catálogo.

- Existencia del ítem.

- Datos obligatorios.

- Códigos duplicados.

- Identificadores duplicados.

- Vigencias incorrectas.

- Estados no permitidos.

- Actualización y eliminación de registros inexistentes.



Tabla de códigos de error:



| Código | Excepción | Descripción |

|---|---|---|

| -20001 | e\_catalogo\_no\_existe | El catálogo no existe |

| -20002 | e\_item\_no\_existe | El ítem no existe |

| -20003 | e\_codigo\_item\_duplicado | Código de ítem duplicado |

| -20004 | e\_vigencia\_invalida | Vigencia incorrecta |

| -20005 | e\_datos\_incompletos | Datos obligatorios incompletos |

| -20006 | e\_estado\_invalido | Estado no permitido |

| -20007 | e\_item\_id\_duplicado | Identificador de ítem duplicado |



\### A.4. Consulta JSON por ItemId



Se implementó el procedimiento:



```sql

PKG\_TTEM\_CATALOG.OBTENER\_ITEM\_JSON

```



Recibe un identificador de ítem y devuelve un CLOB con la información construida mediante JSON\_OBJECT.



Ejemplo de ejecución:



```sql

SET SERVEROUTPUT ON;



DECLARE

&#x20;   l\_json CLOB;

BEGIN

&#x20;   PKG\_TTEM\_CATALOG.OBTENER\_ITEM\_JSON(

&#x20;       p\_item\_id => 2,

&#x20;       p\_json    => l\_json

&#x20;   );



&#x20;   DBMS\_OUTPUT.PUT\_LINE(

&#x20;       DBMS\_LOB.SUBSTR(l\_json, 4000, 1)

&#x20;   );

END;

/

```



Salida esperada con los datos iniciales actuales:



```json

{

&#x20; "itemId": 2,

&#x20; "catalogId": 1,

&#x20; "catalogCode": "MONEDA",

&#x20; "itemCode": "USD",

&#x20; "name": "Dólar estadounidense",

&#x20; "value": "USD",

&#x20; "status": "A",

&#x20; "validFrom": "2026-01-01",

&#x20; "validTo": null

}

```



El procedimiento maneja el caso de un identificador inexistente mediante la excepción propia correspondiente.



## 7. Sección B — Consulta de cliente por número de cuenta



Archivo:



```text

scripts/consulta\_cliente.sql

```



La consulta recibe un número de cuenta y devuelve información consolidada de la cuenta y su titular.



### Información recuperada



- Número de cuenta.

- Tipo de producto.

- Moneda.

- Saldo.

- Estado de la cuenta.

- Identificador del cliente.

- Tipo de persona: Natural o Jurídica.

- Tipo y número de documento.

- Nombre normalizado.

- Fecha de nacimiento o constitución.

- Tipo de fecha de referencia.

- Usuarios de Banca en Línea y su estado.



Los usuarios OLB se consolidan mediante LISTAGG.



Los nombres se normalizan eliminando espacios iniciales, finales y espacios internos redundantes.



Cuando no existe fecha de nacimiento o constitución, la fecha se presenta vacía y el tipo de referencia indica "No registrada".



### Casos de prueba ejecutados



| Número de cuenta | Escenario | Resultado |

|---|---|---|

| 1910001000011 | Natural con fecha de nacimiento y usuario OLB | Correcto |

| 1910002000017 | Natural sin fecha de nacimiento ni usuarios OLB | Correcto |

| 1910003000013 | Jurídica con dos usuarios OLB, uno bloqueado | Correcto |

| 1910004000019 | Jurídica sin fecha de constitución y cuenta bloqueada | Correcto |

| 9999999999999 | Cuenta inexistente | Cero filas, sin error |



### Comportamiento ante cuenta inexistente



Cuando el número de cuenta no existe, la consulta no devuelve registros y termina normalmente, sin generar una excepción Oracle.


## 8. Sección C — Transferencias bancarias



Estado: pendiente de implementación.



Se implementará el procedimiento de transferencia entre cuentas, incluyendo:



- Validación de cuentas y moneda.

- Validación de saldo disponible.

- Control de referencias duplicadas.

- Bloqueo de cuentas mediante SELECT FOR UPDATE.

- Actualización de saldos.

- Registro del movimiento en CORE\_TRX.

- Manejo de fallas y atomicidad mediante SAVEPOINT y ROLLBACK.



Esta sección se documentará cuando termine su implementación y validación.



## 9. Sección D — Propuesta técnica



Estado: pendiente de documentación.



Se incorporará una propuesta de mejora para automatizar el mantenimiento de catálogos, incluyendo aprobación, trazabilidad, auditoría y reversión.


## 10. Sección A.5 — Carga masiva



Estado: pendiente.



Se evaluará la implementación de carga masiva mediante BULK COLLECT y FORALL SAVE EXCEPTIONS, de acuerdo con las prioridades del examen.



## 11. Control de versiones



El proyecto utiliza Git para registrar avances incrementales.



Repositorio:



https://github.com/alexanderaa16-coder/oraclecore-Alexander



Los commits documentan la evolución del modelo, el package, sus validaciones y las consultas implementadas.



