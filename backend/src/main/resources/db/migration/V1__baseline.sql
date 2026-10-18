-- V1: basismigratie (fase 1).
--
-- Er worden in de MVP bewust nog GEEN aankopen, documenten of gebruikers op de server opgeslagen:
-- de app is local-first. Deze tabel legt alleen vast welk schema er draait, zodat migraties en
-- de databaseverbinding vanaf het begin getest worden.
-- Alle tijdstippen zijn TIMESTAMPTZ en worden in UTC opgeslagen.

CREATE TABLE app_metadata (
    meta_key   VARCHAR(100) PRIMARY KEY,
    meta_value VARCHAR(500) NOT NULL,
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO app_metadata (meta_key, meta_value) VALUES ('schema_baseline', 'fase-1');
