
CREATE OR REPLACE PACKAGE BODY PKG_CORE_SETTLEMENT AS

    ------------------------------------------------------------
    -- PROCEDIMIENTO PRIVADO:
    -- Consulta y bloquea una cuenta con SELECT FOR UPDATE.
    ------------------------------------------------------------
    PROCEDURE bloquear_cuenta (
        p_account_no IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_currency   OUT CORE_ACCOUNT.CURRENCY%TYPE,
        p_balance    OUT CORE_ACCOUNT.BALANCE%TYPE,
        p_status     OUT CORE_ACCOUNT.STATUS%TYPE
    ) IS
    BEGIN
        SELECT currency, balance, status
          INTO p_currency, p_balance, p_status
          FROM CORE_ACCOUNT
         WHERE account_no = p_account_no
           FOR UPDATE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20103,
                'La cuenta no existe: ' || p_account_no
            );
    END bloquear_cuenta;


    ------------------------------------------------------------
    -- PROCEDIMIENTO PRINCIPAL DE TRANSFERENCIA
    ------------------------------------------------------------
    PROCEDURE transferir (
        p_cuenta_origen  IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_cuenta_destino IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_monto          IN NUMBER,
        p_moneda         IN VARCHAR2,
        p_referencia     IN CORE_TRX.REFERENCE%TYPE,
        p_descripcion    IN CORE_TRX.DESCRIPTION%TYPE DEFAULT NULL,
        p_simular_falla  IN VARCHAR2 DEFAULT 'N',
        p_trx_id         OUT CORE_TRX.TRX_ID%TYPE
    ) IS

        v_cuenta_origen  CORE_ACCOUNT.ACCOUNT_NO%TYPE;
        v_cuenta_destino CORE_ACCOUNT.ACCOUNT_NO%TYPE;

        v_moneda         CORE_ACCOUNT.CURRENCY%TYPE;
        v_moneda_origen  CORE_ACCOUNT.CURRENCY%TYPE;
        v_moneda_destino CORE_ACCOUNT.CURRENCY%TYPE;

        v_saldo_origen   CORE_ACCOUNT.BALANCE%TYPE;
        v_saldo_destino  CORE_ACCOUNT.BALANCE%TYPE;

        v_estado_origen  CORE_ACCOUNT.STATUS%TYPE;
        v_estado_destino CORE_ACCOUNT.STATUS%TYPE;

        v_referencia     CORE_TRX.REFERENCE%TYPE;
        v_simular_falla  VARCHAR2(1);

        v_existe         NUMBER;

    BEGIN

        --------------------------------------------------------
        -- 1. SAVEPOINT PARA CONTROLAR LA ATOMICIDAD
        --------------------------------------------------------
        p_trx_id := NULL;

        SAVEPOINT sp_core_transferencia;


        --------------------------------------------------------
        -- 2. NORMALIZACION DE PARAMETROS
        --------------------------------------------------------
        v_cuenta_origen  := TRIM(p_cuenta_origen);
        v_cuenta_destino := TRIM(p_cuenta_destino);
        v_moneda         := UPPER(TRIM(p_moneda));
        v_referencia     := TRIM(p_referencia);
        v_simular_falla  := UPPER(TRIM(NVL(p_simular_falla, 'N')));


        --------------------------------------------------------
        -- 3. VALIDACION DE PARAMETROS
        --------------------------------------------------------
        IF v_cuenta_origen IS NULL
           OR v_cuenta_destino IS NULL
           OR v_referencia IS NULL
           OR v_moneda IS NULL THEN

            RAISE_APPLICATION_ERROR(
                -20109,
                'Los parametros obligatorios no pueden estar vacios.'
            );
        END IF;

        IF v_cuenta_origen = v_cuenta_destino THEN
            RAISE_APPLICATION_ERROR(
                -20102,
                'La cuenta de origen y destino deben ser distintas.'
            );
        END IF;

        IF p_monto IS NULL
           OR p_monto <= 0
           OR p_monto <> ROUND(p_monto, 2) THEN

            RAISE_APPLICATION_ERROR(
                -20101,
                'El monto debe ser positivo y tener maximo dos decimales.'
            );
        END IF;

        IF v_moneda NOT IN ('PEN', 'USD') THEN
            RAISE_APPLICATION_ERROR(
                -20105,
                'La moneda indicada no es valida.'
            );
        END IF;

        IF LENGTH(v_referencia) > 40 THEN
            RAISE_APPLICATION_ERROR(
                -20109,
                'La referencia supera los 40 caracteres permitidos.'
            );
        END IF;

        IF v_simular_falla NOT IN ('S', 'N') THEN
            RAISE_APPLICATION_ERROR(
                -20109,
                'El indicador de falla debe ser S o N.'
            );
        END IF;


        --------------------------------------------------------
        -- 4. BLOQUEO DE CUENTAS EN ORDEN CONSISTENTE
        --    Se bloquea primero el numero de cuenta menor.
        --    Esto reduce el riesgo de deadlocks.
        --------------------------------------------------------
        IF v_cuenta_origen < v_cuenta_destino THEN

            bloquear_cuenta(
                v_cuenta_origen,
                v_moneda_origen,
                v_saldo_origen,
                v_estado_origen
            );

            bloquear_cuenta(
                v_cuenta_destino,
                v_moneda_destino,
                v_saldo_destino,
                v_estado_destino
            );

        ELSE

            bloquear_cuenta(
                v_cuenta_destino,
                v_moneda_destino,
                v_saldo_destino,
                v_estado_destino
            );

            bloquear_cuenta(
                v_cuenta_origen,
                v_moneda_origen,
                v_saldo_origen,
                v_estado_origen
            );

        END IF;


        --------------------------------------------------------
        -- 5. VALIDACION DE ESTADO DE LAS CUENTAS
        --------------------------------------------------------
        IF v_estado_origen <> 'A'
           OR v_estado_destino <> 'A' THEN

            RAISE_APPLICATION_ERROR(
                -20104,
                'Ambas cuentas deben estar activas.'
            );
        END IF;


        --------------------------------------------------------
        -- 6. VALIDACION DE MONEDA
        --------------------------------------------------------
        IF v_moneda_origen <> v_moneda
           OR v_moneda_destino <> v_moneda THEN

            RAISE_APPLICATION_ERROR(
                -20105,
                'La moneda indicada debe coincidir con ambas cuentas.'
            );
        END IF;


        --------------------------------------------------------
        -- 7. VALIDACION DE SALDO
        --------------------------------------------------------
        IF v_saldo_origen < p_monto THEN
            RAISE_APPLICATION_ERROR(
                -20106,
                'Saldo insuficiente en la cuenta de origen.'
            );
        END IF;


        --------------------------------------------------------
        -- 8. VALIDACION DE REFERENCIA DUPLICADA
        --------------------------------------------------------
        SELECT COUNT(*)
          INTO v_existe
          FROM CORE_TRX
         WHERE reference = v_referencia;

        IF v_existe > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20107,
                'La referencia ya fue utilizada.'
            );
        END IF;


        --------------------------------------------------------
        -- 9. DEBITO DE LA CUENTA DE ORIGEN
        --------------------------------------------------------
        UPDATE CORE_ACCOUNT
           SET balance = balance - p_monto
         WHERE account_no = v_cuenta_origen;

        IF SQL%ROWCOUNT <> 1 THEN
            RAISE_APPLICATION_ERROR(
                -20103,
                'No fue posible realizar el debito.'
            );
        END IF;


        --------------------------------------------------------
        -- 10. SIMULACION DE FALLA CONTROLADA
        --     Ocurre despues del debito y antes del credito.
        --------------------------------------------------------
        IF v_simular_falla = 'S' THEN
            RAISE_APPLICATION_ERROR(
                -20108,
                'Falla simulada despues del debito.'
            );
        END IF;


        --------------------------------------------------------
        -- 11. CREDITO DE LA CUENTA DESTINO
        --------------------------------------------------------
        UPDATE CORE_ACCOUNT
           SET balance = balance + p_monto
         WHERE account_no = v_cuenta_destino;

        IF SQL%ROWCOUNT <> 1 THEN
            RAISE_APPLICATION_ERROR(
                -20103,
                'No fue posible realizar el credito.'
            );
        END IF;


        --------------------------------------------------------
        -- 12. REGISTRO DEL MOVIMIENTO CONTABLE
        --------------------------------------------------------
        BEGIN

            INSERT INTO CORE_TRX (
                trx_id,
                trx_date,
                debit_account_no,
                credit_account_no,
                amount,
                currency,
                trx_type,
                description,
                reference,
                reversal_flag,
                reversed_trx_id,
                created_at
            )
            VALUES (
                SEQ_CORE_TRX.NEXTVAL,
                SYSDATE,
                v_cuenta_origen,
                v_cuenta_destino,
                p_monto,
                v_moneda,
                'TRF',
                TRIM(p_descripcion),
                v_referencia,
                'N',
                NULL,
                SYSTIMESTAMP
            )
            RETURNING trx_id INTO p_trx_id;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                RAISE_APPLICATION_ERROR(
                    -20107,
                    'La referencia o identificador del movimiento esta duplicado.'
                );
        END;


        --------------------------------------------------------
        -- 13. FIN EXITOSO
        --     NO SE EJECUTA COMMIT.
        --     El invocador controla la transaccion.
        --------------------------------------------------------

    EXCEPTION

        WHEN OTHERS THEN

            ROLLBACK TO sp_core_transferencia;

            p_trx_id := NULL;

            RAISE;

    END transferir;

END PKG_CORE_SETTLEMENT;
/
