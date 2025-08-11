CREATE USER replication WITH REPLICATION PASSWORD '123';
SELECT pg_create_physical_replication_slot('db2');
