
-- ============================================================
-- SECCION B - CONSULTA DE CLIENTE POR NUMERO DE CUENTA
-- Examen Oracle PL/SQL - Core Bancario
-- ============================================================

SET DEFINE ON;

-- Variable de sustitucion:
-- SQL Developer solicitara el numero de cuenta al ejecutar F5.

WITH usuarios_olb AS (
    SELECT
        u.customer_id,

        LISTAGG(
            TRIM(u.username) || ' (' ||
            CASE u.status
                WHEN 'A' THEN 'Activo'
                WHEN 'B' THEN 'Bloqueado'
                WHEN 'I' THEN 'Inactivo'
                ELSE u.status
            END || ')',
            ', '
        ) WITHIN GROUP (
            ORDER BY u.username
        ) AS usuarios_banca_linea

    FROM olb_user u
    GROUP BY u.customer_id
)

SELECT

    -- ========================================================
    -- 1. DATOS DE LA CUENTA
    -- ========================================================

    a.account_no AS numero_cuenta,
    a.product_type AS tipo_producto,
    a.currency AS moneda,
    a.balance AS saldo,
    a.status AS estado_cuenta,

    -- ========================================================
    -- 2. DATOS DEL CLIENTE
    -- ========================================================

    c.customer_id AS identificador_cliente,

    CASE c.person_type
        WHEN 'N' THEN 'Natural'
        WHEN 'J' THEN 'Juridica'
        ELSE 'No definida'
    END AS tipo_persona,

    c.doc_type AS tipo_documento,
    c.doc_number AS numero_documento,

    -- Nombre normalizado
    CASE
        WHEN c.person_type = 'N' THEN
            TRIM(
                REGEXP_REPLACE(
                    NVL(c.first_name, '') || ' ' ||
                    NVL(c.last_name, ''),
                    '[[:space:]]+',
                    ' '
                )
            )

        WHEN c.person_type = 'J' THEN
            TRIM(
                REGEXP_REPLACE(
                    NVL(c.business_name, ''),
                    '[[:space:]]+',
                    ' '
                )
            )
    END AS nombre_cliente,

    -- ========================================================
    -- 3. FECHA DE REFERENCIA
    -- ========================================================

    CASE
        WHEN c.person_type = 'N'
             AND c.birth_date IS NOT NULL
        THEN TO_CHAR(c.birth_date, 'YYYY-MM-DD')

        WHEN c.person_type = 'J'
             AND c.incorporation_date IS NOT NULL
        THEN TO_CHAR(c.incorporation_date, 'YYYY-MM-DD')

        ELSE NULL
    END AS fecha_referencia,

    CASE
        WHEN c.person_type = 'N'
             AND c.birth_date IS NOT NULL
        THEN 'Fecha de nacimiento'

        WHEN c.person_type = 'J'
             AND c.incorporation_date IS NOT NULL
        THEN 'Fecha de constitucion'

        ELSE 'No registrada'
    END AS tipo_fecha_referencia,

    -- ========================================================
    -- 4. USUARIOS DE BANCA EN LINEA
    -- ========================================================

    NVL(
        u.usuarios_banca_linea,
        ''
    ) AS usuarios_banca_linea

-- ============================================================
-- 5. RELACIONES ENTRE TABLAS
-- ============================================================

FROM core_account a

INNER JOIN core_customer c
    ON c.customer_id = a.customer_id

LEFT JOIN usuarios_olb u
    ON u.customer_id = c.customer_id

-- ============================================================
-- 6. PARAMETRO DE ENTRADA
-- ============================================================

WHERE a.account_no = TRIM('&p_account_no');

