
-- ============================================================
-- EXAMEN TECNICO ORACLE PL/SQL - CORE BANCARIO
-- SECCION C: PRUEBAS DE TRANSFERENCIAS
-- Package: PKG_CORE_SETTLEMENT
-- Esquema: CORE_DEV
-- ============================================================

SET SERVEROUTPUT ON;

PROMPT ============================================================
PROMPT SECCION C - PRUEBAS DE TRANSFERENCIAS
PROMPT ============================================================

DECLARE

    v_trx_id       CORE_TRX.TRX_ID%TYPE;
    v_total        NUMBER;
    v_correcto     NUMBER;

    ------------------------------------------------------------
    -- PROCEDIMIENTO AUXILIAR PARA VALIDAR RECHAZOS ESPERADOS
    ------------------------------------------------------------
    PROCEDURE validar_rechazo (
        p_nombre           IN VARCHAR2,
        p_codigo_esperado  IN NUMBER,
        p_cuenta_origen    IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_cuenta_destino   IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_monto            IN NUMBER,
        p_moneda           IN VARCHAR2,
        p_referencia       IN CORE_TRX.REFERENCE%TYPE,
        p_simular_falla    IN VARCHAR2 DEFAULT 'N'
    ) IS

        v_id       CORE_TRX.TRX_ID%TYPE;
        v_rechazo  BOOLEAN := FALSE;

    BEGIN

        SAVEPOINT sp_prueba_rechazo;

        BEGIN

            PKG_CORE_SETTLEMENT.TRANSFERIR(
                p_cuenta_origen  => p_cuenta_origen,
                p_cuenta_destino => p_cuenta_destino,
                p_monto          => p_monto,
                p_moneda         => p_moneda,
                p_referencia     => p_referencia,
                p_descripcion    => p_nombre,
                p_simular_falla  => p_simular_falla,
                p_trx_id         => v_id
            );

        EXCEPTION
            WHEN OTHERS THEN

                IF SQLCODE = p_codigo_esperado THEN

                    v_rechazo := TRUE;

                    DBMS_OUTPUT.PUT_LINE(
                        'OK - ' || p_nombre ||
                        ' | Codigo: ' || SQLCODE
                    );

                ELSE

                    ROLLBACK TO sp_prueba_rechazo;
                    RAISE;

                END IF;

        END;

        IF NOT v_rechazo THEN

            ROLLBACK TO sp_prueba_rechazo;

            RAISE_APPLICATION_ERROR(
                -20990,
                'FALLO: no se produjo el rechazo esperado en ' ||
                p_nombre
            );

        END IF;

    END validar_rechazo;


BEGIN

    ------------------------------------------------------------
    -- C.1 TRANSFERENCIA EXITOSA
    -- REF-T001 se comprueba para evitar repetir el movimiento
    -- si la prueba ya fue ejecutada anteriormente.
    ------------------------------------------------------------

    SELECT COUNT(*)
      INTO v_total
      FROM CORE_TRX
     WHERE reference = 'REF-T001';

    SELECT COUNT(*)
      INTO v_correcto
      FROM CORE_TRX
     WHERE reference = 'REF-T001'
       AND debit_account_no = '1910001000011'
       AND credit_account_no = '1910002000017'
       AND amount = 100
       AND currency = 'PEN'
       AND trx_type = 'TRF'
       AND reversal_flag = 'N';

    IF v_total = 0 THEN

        PKG_CORE_SETTLEMENT.TRANSFERIR(
            p_cuenta_origen  => '1910001000011',
            p_cuenta_destino => '1910002000017',
            p_monto          => 100,
            p_moneda         => 'PEN',
            p_referencia     => 'REF-T001',
            p_descripcion    => 'Transferencia prueba examen',
            p_simular_falla  => 'N',
            p_trx_id         => v_trx_id
        );

        COMMIT;

        DBMS_OUTPUT.PUT_LINE(
            'OK - Transferencia exitosa. TRX_ID: ' || v_trx_id
        );

    ELSIF v_total = 1 AND v_correcto = 1 THEN

        DBMS_OUTPUT.PUT_LINE(
            'OK - REF-T001 ya existe correctamente. ' ||
            'Se omite repetir la transferencia.'
        );

    ELSE

        RAISE_APPLICATION_ERROR(
            -20991,
            'REF-T001 existe, pero sus datos no coinciden con la prueba.'
        );

    END IF;


    ------------------------------------------------------------
    -- C.2 REFERENCIA DUPLICADA
    -- Resultado esperado: -20107
    ------------------------------------------------------------

    validar_rechazo(
        p_nombre          => 'Referencia duplicada',
        p_codigo_esperado => -20107,
        p_cuenta_origen   => '1910001000011',
        p_cuenta_destino  => '1910002000017',
        p_monto           => 100,
        p_moneda          => 'PEN',
        p_referencia      => 'REF-T001'
    );


    ------------------------------------------------------------
    -- C.3 SALDO INSUFICIENTE
    -- Resultado esperado: -20106
    ------------------------------------------------------------

    validar_rechazo(
        p_nombre          => 'Saldo insuficiente',
        p_codigo_esperado => -20106,
        p_cuenta_origen   => '1910002000017',
        p_cuenta_destino  => '1910001000011',
        p_monto           => 5000,
        p_moneda          => 'PEN',
        p_referencia      => 'REF-T003'
    );


    ------------------------------------------------------------
    -- C.4 MONEDA DISTINTA
    -- Resultado esperado: -20105
    ------------------------------------------------------------

    validar_rechazo(
        p_nombre          => 'Moneda distinta',
        p_codigo_esperado => -20105,
        p_cuenta_origen   => '1910001000011',
        p_cuenta_destino  => '1910001000029',
        p_monto           => 10,
        p_moneda          => 'PEN',
        p_referencia      => 'REF-T004'
    );


    ------------------------------------------------------------
    -- C.5 CUENTA DESTINO BLOQUEADA
    -- Resultado esperado: -20104
    ------------------------------------------------------------

    validar_rechazo(
        p_nombre          => 'Cuenta bloqueada',
        p_codigo_esperado => -20104,
        p_cuenta_origen   => '1910003000013',
        p_cuenta_destino  => '1910004000019',
        p_monto           => 50,
        p_moneda          => 'PEN',
        p_referencia      => 'REF-T005'
    );


    ------------------------------------------------------------
    -- C.6 FALLA SIMULADA Y ATOMICIDAD
    -- Resultado esperado: -20108
    ------------------------------------------------------------

    validar_rechazo(
        p_nombre          => 'Falla simulada y rollback',
        p_codigo_esperado => -20108,
        p_cuenta_origen   => '1910001000011',
        p_cuenta_destino  => '1910002000017',
        p_monto           => 100,
        p_moneda          => 'PEN',
        p_referencia      => 'REF-T002',
        p_simular_falla   => 'S'
    );


    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('PRUEBAS DE LA SECCION C FINALIZADAS');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');

END;
/

------------------------------------------------------------
-- VERIFICACION FINAL DE SALDOS
------------------------------------------------------------

PROMPT
PROMPT SALDOS DE LAS CUENTAS DE PRUEBA

SELECT
    account_no,
    balance,
    currency,
    status
FROM CORE_ACCOUNT
WHERE account_no IN (
    '1910001000011',
    '1910002000017'
)
ORDER BY account_no;


------------------------------------------------------------
-- VERIFICACION DE REFERENCIAS
------------------------------------------------------------

PROMPT
PROMPT CONTROL DE MOVIMIENTOS

SELECT
    'REF-T001' AS referencia,
    COUNT(*) AS movimientos_registrados
FROM CORE_TRX
WHERE reference = 'REF-T001'

UNION ALL

SELECT
    'REF-T002',
    COUNT(*)
FROM CORE_TRX
WHERE reference = 'REF-T002';

PROMPT
PROMPT FIN DE LAS PRUEBAS
