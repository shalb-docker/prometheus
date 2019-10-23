CREATE USER postgres_exporter PASSWORD 'test_password';
ALTER USER postgres_exporter SET SEARCH_PATH TO postgres_exporter,pg_catalog;

GRANT pg_read_all_stats to postgres_exporter;

