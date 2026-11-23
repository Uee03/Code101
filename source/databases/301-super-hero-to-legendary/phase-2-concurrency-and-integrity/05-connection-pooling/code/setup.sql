DROP SCHEMA IF EXISTS app CASCADE;
CREATE SCHEMA app;
CREATE TABLE app.services (
    service text NOT NULL,
    instances integer NOT NULL,
    pool_per_instance integer NOT NULL,
    CONSTRAINT pk_services PRIMARY KEY (service),
    CONSTRAINT ck_services_positive CHECK (instances > 0 AND pool_per_instance > 0)
);
INSERT INTO app.services (service, instances, pool_per_instance) VALUES
    ('api', 6, 10),
    ('worker', 4, 5),
    ('admin', 1, 3);
