CREATE OR REPLACE PACKAGE pkg_ttem_catalog AS

    -- Excepciones propias de negocio

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


    -- Operaciones del catálogo

    PROCEDURE insertar_item (
        p_item IN typ_ttem_item
    );

    PROCEDURE actualizar_item (
        p_item IN typ_ttem_item
    );

    PROCEDURE eliminar_item (
        p_item_id IN NUMBER
    );

    FUNCTION obtener_items_catalogo (
        p_catalog_id IN NUMBER
    ) RETURN typ_ttem_item_tab;

END pkg_ttem_catalog;
/