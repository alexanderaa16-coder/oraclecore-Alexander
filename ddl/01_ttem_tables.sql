-- ============================================================
-- 01_ttem_tables.sql
-- Sección A.1 - Catálogos parametrizables
-- Examen Técnico Oracle PL/SQL - Core Bancario
-- ============================================================

CREATE TABLE ttem_catalog (
    catalog_id       NUMBER(10) NOT NULL,
    catalog_code     VARCHAR2(30) NOT NULL,
    catalog_name     VARCHAR2(100) NOT NULL,
    description      VARCHAR2(500),
    status           CHAR(1) DEFAULT 'A' NOT NULL,

    created_by       VARCHAR2(100) DEFAULT USER NOT NULL,
    created_at       DATE DEFAULT SYSDATE NOT NULL,
    updated_by       VARCHAR2(100) DEFAULT USER NOT NULL,
    updated_at       DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT pk_ttem_catalog PRIMARY KEY (catalog_id),
    CONSTRAINT uk_ttem_catalog_code UNIQUE (catalog_code),
    CONSTRAINT ck_ttem_catalog_status CHECK (status IN ('A', 'I'))
);

CREATE TABLE ttem_item (
    item_id          NUMBER(10) NOT NULL,
    catalog_id       NUMBER(10) NOT NULL,
    item_code        VARCHAR2(30) NOT NULL,
    item_name        VARCHAR2(200) NOT NULL,
    item_value       VARCHAR2(500),
    display_order    NUMBER(10),
    status           CHAR(1) DEFAULT 'A' NOT NULL,
    valid_from       DATE NOT NULL,
    valid_to         DATE,

    created_by       VARCHAR2(100) DEFAULT USER NOT NULL,
    created_at       DATE DEFAULT SYSDATE NOT NULL,
    updated_by       VARCHAR2(100) DEFAULT USER NOT NULL,
    updated_at       DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT pk_ttem_item PRIMARY KEY (item_id),
    CONSTRAINT fk_ttem_item_catalog
        FOREIGN KEY (catalog_id)
        REFERENCES ttem_catalog (catalog_id),
    CONSTRAINT uk_ttem_item_catalog_code
        UNIQUE (catalog_id, item_code),
    CONSTRAINT ck_ttem_item_status CHECK (status IN ('A', 'I')),
    CONSTRAINT ck_ttem_item_validity
        CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

-- ============================================================
-- Datos iniciales obligatorios
-- ============================================================

INSERT INTO ttem_catalog (
    catalog_id, catalog_code, catalog_name, description, status
) VALUES (
    1, 'MONEDA', 'Monedas', 'Catálogo de monedas', 'A'
);

INSERT INTO ttem_catalog (
    catalog_id, catalog_code, catalog_name, description, status
) VALUES (
    2, 'TIPO_COMISION', 'Tipos de comisión',
    'Catálogo de tipos de comisión', 'A'
);

INSERT INTO ttem_item (
    item_id, catalog_id, item_code, item_name, item_value,
    display_order, status, valid_from
) VALUES (
    1, 1, 'PEN', 'Sol peruano', 'PEN',
    1, 'A', DATE '2026-01-01'
);

INSERT INTO ttem_item (
    item_id, catalog_id, item_code, item_name, item_value,
    display_order, status, valid_from
) VALUES (
    2, 1, 'USD', 'Dólar estadounidense', 'USD',
    2, 'A', DATE '2026-01-01'
);

INSERT INTO ttem_item (
    item_id, catalog_id, item_code, item_name, item_value,
    display_order, status, valid_from
) VALUES (
    3, 2, 'COM_MANT', 'Comisión de mantenimiento', 'COM_MANT',
    1, 'A', DATE '2026-01-01'
);

COMMIT;

PROMPT Verificación de catálogos e ítems
SELECT catalog_id, catalog_code, catalog_name, status
FROM ttem_catalog
ORDER BY catalog_id;

SELECT item_id, catalog_id, item_code, item_name, status
FROM ttem_item
ORDER BY item_id;
