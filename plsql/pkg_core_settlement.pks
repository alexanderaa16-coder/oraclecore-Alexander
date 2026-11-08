
CREATE OR REPLACE PACKAGE PKG_CORE_SETTLEMENT AS

    PROCEDURE transferir (
        p_cuenta_origen  IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_cuenta_destino IN CORE_ACCOUNT.ACCOUNT_NO%TYPE,
        p_monto          IN NUMBER,
        p_moneda         IN VARCHAR2,
        p_referencia     IN CORE_TRX.REFERENCE%TYPE,
        p_descripcion    IN CORE_TRX.DESCRIPTION%TYPE DEFAULT NULL,
        p_simular_falla  IN VARCHAR2 DEFAULT 'N',
        p_trx_id         OUT CORE_TRX.TRX_ID%TYPE
    );

END PKG_CORE_SETTLEMENT;
/
