
CREATE OR REPLACE PACKAGE pkg_ttem_catalog AS

    -- =====================================================
    -- 1. EXCEPCIONES PROPIAS DE NEGOCIO
    -- =====================================================

    e_catalogo_no_existe EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_catalogo_no_existe, -20001);

    e_item_no_existe EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_item_no_existe, -20002);

    e_codigo_item_duplicado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_codigo_item_duplicado, -20003);

    e_vigencia_invalida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_vigencia_invalida, -20004);

    e_datos_incompletos EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_datos_incompletos, -20005);

    e_estado_invalido EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_estado_invalido, -20006);

    e_item_id_duplicado EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_item_id_duplicado, -20007);


    -- =====================================================
    -- 2. OPERACIONES DE MANTENIMIENTO
    -- =====================================================

    PROCEDURE insertar_item (
        p_item IN typ_ttem_item
    );


    PROCEDURE actualizar_item (
        p_item IN typ_ttem_item
    );


    PROCEDURE eliminar_item (
        p_item_id IN NUMBER
    );


    -- =====================================================
    -- 3. CONSULTAR ITEMS POR CATALOGO
    -- =====================================================

    FUNCTION obtener_items_catalogo (
        p_catalog_id IN NUMBER
    ) RETURN typ_ttem_item_tab;


    -- =====================================================
    -- 4. CONSULTAR ITEM EN FORMATO JSON
    -- =====================================================

    PROCEDURE obtener_item_json (
        p_item_id IN NUMBER,
        p_json    OUT CLOB
    );

END pkg_ttem_catalog;
/
