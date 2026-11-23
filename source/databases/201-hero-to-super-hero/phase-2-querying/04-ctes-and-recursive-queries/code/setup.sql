DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.categories (
    category_id bigint GENERATED ALWAYS AS IDENTITY,
    parent_id bigint,
    title text NOT NULL,
    CONSTRAINT pk_categories PRIMARY KEY (category_id),
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id)
        REFERENCES app.categories (category_id) ON DELETE RESTRICT
);
CREATE INDEX ix_categories_parent_id ON app.categories (parent_id);
INSERT INTO app.categories (title) VALUES ('Shop');
INSERT INTO app.categories (parent_id, title) VALUES (1, 'Paper'), (1, 'Writing');
INSERT INTO app.categories (parent_id, title) VALUES (2, 'Notebooks');
