-- ============================================================
-- pkg_ttem_catalog.pkb
-- Walking Skeleton - Cuerpo compilable
-- Las validaciones completas se agregarán en A.3
-- ============================================================

CREATE OR REPLACE PACKAGE BODY pkg_ttem_catalog AS

    PROCEDURE insertar_item (
        p_item IN typ_ttem_item
    ) IS
    BEGIN
        INSERT INTO ttem_item (
            item_id, catalog_id, item_code, item_name, item_value,
            display_order, status, valid_from, valid_to,
            created_by, created_at, updated_by, updated_at
        ) VALUES (
            p_item.item_id,
            p_item.catalog_id,
            p_item.item_code,
            p_item.item_name,
            p_item.item_value,
            p_item.display_order,
            p_item.status,
            p_item.valid_from,
            p_item.valid_to,
            USER, SYSDATE, USER, SYSDATE
        );
    END insertar_item;


    PROCEDURE actualizar_item (
        p_item IN typ_ttem_item
    ) IS
    BEGIN
        UPDATE ttem_item
           SET catalog_id    = p_item.catalog_id,
               item_code     = p_item.item_code,
               item_name     = p_item.item_name,
               item_value    = p_item.item_value,
               display_order = p_item.display_order,
               status        = p_item.status,
               valid_from    = p_item.valid_from,
               valid_to      = p_item.valid_to,
               updated_by    = USER,
               updated_at    = SYSDATE
         WHERE item_id = p_item.item_id;
    END actualizar_item;


    PROCEDURE eliminar_item (
        p_item_id IN NUMBER
    ) IS
    BEGIN
        -- Eliminación física en el esqueleto inicial.
        -- La decisión definitiva se documentará y validará en A.3.
        DELETE FROM ttem_item
         WHERE item_id = p_item_id;
    END eliminar_item;


    FUNCTION obtener_items_catalogo (
        p_catalog_id IN NUMBER
    ) RETURN typ_ttem_item_tab IS
        l_items typ_ttem_item_tab;
    BEGIN
        SELECT typ_ttem_item(
                   item_id,
                   catalog_id,
                   item_code,
                   item_name,
                   item_value,
                   display_order,
                   status,
                   valid_from,
                   valid_to
               )
        BULK COLLECT INTO l_items
        FROM ttem_item
        WHERE catalog_id = p_catalog_id
        ORDER BY display_order, item_id;

        RETURN l_items;
    END obtener_items_catalogo;

END pkg_ttem_catalog;
/
