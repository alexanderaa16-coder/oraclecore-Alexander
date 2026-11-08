-- ============================================================
-- pkg_ttem_catalog.pks
-- Walking Skeleton - Especificación
-- ============================================================

CREATE OR REPLACE PACKAGE pkg_ttem_catalog AS

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
