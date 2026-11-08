
CREATE OR REPLACE PACKAGE BODY pkg_ttem_catalog AS

    -- =====================================================
    -- 1. VALIDAR EXISTENCIA DEL CATALOGO
    -- =====================================================

    PROCEDURE validar_catalogo (
        p_catalog_id IN NUMBER
    ) IS
        l_count NUMBER;
    BEGIN
        IF p_catalog_id IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20005,
                'El identificador del catalogo es obligatorio'
            );
        END IF;

        SELECT COUNT(*)
          INTO l_count
          FROM ttem_catalog
         WHERE catalog_id = p_catalog_id;

        IF l_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'El catalogo no existe'
            );
        END IF;

    END validar_catalogo;


    -- =====================================================
    -- 2. VALIDAR DATOS DEL ITEM
    -- =====================================================

    PROCEDURE validar_datos_item (
        p_item IN typ_ttem_item
    ) IS
        l_status CHAR(1);
    BEGIN

        IF p_item IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20005,
                'El objeto item es obligatorio'
            );
        END IF;

        -- Validar campos obligatorios
        IF p_item.item_id IS NULL
           OR p_item.catalog_id IS NULL
           OR TRIM(p_item.item_code) IS NULL
           OR TRIM(p_item.item_name) IS NULL
           OR p_item.valid_from IS NULL THEN

            RAISE_APPLICATION_ERROR(
                -20005,
                'Existen datos obligatorios incompletos'
            );
        END IF;

        -- Normalizar y validar estado
        l_status := NVL(
            UPPER(TRIM(p_item.status)),
            'A'
        );

        IF l_status NOT IN ('A', 'I') THEN
            RAISE_APPLICATION_ERROR(
                -20006,
                'Estado invalido. Valores permitidos: A o I'
            );
        END IF;

        -- Validar fechas de vigencia
        IF p_item.valid_to IS NOT NULL
           AND p_item.valid_to < p_item.valid_from THEN

            RAISE_APPLICATION_ERROR(
                -20004,
                'La vigencia hasta no puede ser menor que la vigencia desde'
            );
        END IF;

    END validar_datos_item;


    -- =====================================================
    -- 3. VALIDAR CODIGO DUPLICADO
    -- =====================================================

    PROCEDURE validar_codigo_duplicado (
        p_catalog_id IN NUMBER,
        p_item_code  IN VARCHAR2,
        p_item_id    IN NUMBER DEFAULT NULL
    ) IS
        l_count NUMBER;
    BEGIN

        SELECT COUNT(*)
          INTO l_count
          FROM ttem_item
         WHERE catalog_id = p_catalog_id
           AND UPPER(TRIM(item_code)) = UPPER(TRIM(p_item_code))
           AND (
                p_item_id IS NULL
                OR item_id <> p_item_id
           );

        IF l_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'El codigo del item ya existe en el catalogo'
            );
        END IF;

    END validar_codigo_duplicado;


    -- =====================================================
    -- 4. INSERTAR ITEM
    -- =====================================================

    PROCEDURE insertar_item (
        p_item IN typ_ttem_item
    ) IS
        l_count NUMBER;
    BEGIN

        -- Validar datos recibidos
        validar_datos_item(p_item);

        -- Validar catalogo
        validar_catalogo(p_item.catalog_id);

        -- Validar identificador duplicado
        SELECT COUNT(*)
          INTO l_count
          FROM ttem_item
         WHERE item_id = p_item.item_id;

        IF l_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'El identificador del item ya existe'
            );
        END IF;

        -- Validar codigo duplicado
        validar_codigo_duplicado(
            p_item.catalog_id,
            p_item.item_code
        );

        -- Insertar registro
        INSERT INTO ttem_item (
            item_id,
            catalog_id,
            item_code,
            item_name,
            item_value,
            display_order,
            status,
            valid_from,
            valid_to,
            created_by,
            created_at,
            updated_by,
            updated_at
        ) VALUES (
            p_item.item_id,
            p_item.catalog_id,
            UPPER(TRIM(p_item.item_code)),
            TRIM(p_item.item_name),
            TRIM(p_item.item_value),
            p_item.display_order,
            NVL(UPPER(TRIM(p_item.status)), 'A'),
            p_item.valid_from,
            p_item.valid_to,
            USER,
            SYSDATE,
            USER,
            SYSDATE
        );

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN

            SELECT COUNT(*)
              INTO l_count
              FROM ttem_item
             WHERE item_id = p_item.item_id;

            IF l_count > 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20007,
                    'El identificador del item ya existe'
                );
            ELSE
                RAISE_APPLICATION_ERROR(
                    -20003,
                    'El codigo del item ya existe'
                );
            END IF;

    END insertar_item;


    -- =====================================================
    -- 5. ACTUALIZAR ITEM
    -- =====================================================

    PROCEDURE actualizar_item (
        p_item IN typ_ttem_item
    ) IS
        l_count NUMBER;
    BEGIN

        -- Validar datos
        validar_datos_item(p_item);

        -- Validar existencia del item
        SELECT COUNT(*)
          INTO l_count
          FROM ttem_item
         WHERE item_id = p_item.item_id;

        IF l_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'El item que desea actualizar no existe'
            );
        END IF;

        -- Validar existencia del catalogo
        validar_catalogo(p_item.catalog_id);

        -- Validar codigo duplicado
        validar_codigo_duplicado(
            p_item.catalog_id,
            p_item.item_code,
            p_item.item_id
        );

        -- Ejecutar actualizacion
        UPDATE ttem_item
           SET catalog_id    = p_item.catalog_id,
               item_code     = UPPER(TRIM(p_item.item_code)),
               item_name     = TRIM(p_item.item_name),
               item_value    = TRIM(p_item.item_value),
               display_order = p_item.display_order,
               status        = NVL(UPPER(TRIM(p_item.status)), 'A'),
               valid_from    = p_item.valid_from,
               valid_to      = p_item.valid_to,
               updated_by    = USER,
               updated_at    = SYSDATE
         WHERE item_id = p_item.item_id;

        -- Verificar filas afectadas
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'El item ya no existe'
            );
        END IF;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'El codigo del item ya existe'
            );

    END actualizar_item;


    -- =====================================================
    -- 6. ELIMINAR ITEM (ELIMINACION LOGICA)
    -- =====================================================

    PROCEDURE eliminar_item (
        p_item_id IN NUMBER
    ) IS
        l_count NUMBER;
    BEGIN

        -- Validar identificador
        IF p_item_id IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20005,
                'El identificador del item es obligatorio'
            );
        END IF;

        -- Validar existencia
        SELECT COUNT(*)
          INTO l_count
          FROM ttem_item
         WHERE item_id = p_item_id;

        IF l_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'El item que desea eliminar no existe'
            );
        END IF;

        -- Realizar eliminacion logica
        UPDATE ttem_item
           SET status = 'I',
               updated_by = USER,
               updated_at = SYSDATE
         WHERE item_id = p_item_id;

        -- Verificar filas afectadas
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'El item ya no existe'
            );
        END IF;

    END eliminar_item;


    -- =====================================================
    -- 7. CONSULTAR ITEMS POR CATALOGO
    -- =====================================================

    FUNCTION obtener_items_catalogo (
        p_catalog_id IN NUMBER
    ) RETURN typ_ttem_item_tab IS

        l_items typ_ttem_item_tab;

    BEGIN

        -- Validar catalogo
        validar_catalogo(p_catalog_id);

        -- Obtener items
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
