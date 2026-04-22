-- ============================================================
-- ROLES
-- ============================================================

CREATE ROLE IF NOT EXISTS iso;
CREATE ROLE IF NOT EXISTS viewer;

-- ============================================================
-- VIEWER ROLE
-- Read-only access to all databases
-- ============================================================

GRANT SELECT ON *.* TO viewer;

REVOKE SELECT ON information_schema.* FROM viewer;
REVOKE SELECT ON system.* FROM viewer;

-- Revoke all privileges
REVOKE ALL ON *.* FROM viewer;

-- Show all grants
SHOW GRANTS FOR viewer;

-- ============================================================
-- ISO ROLE
-- Read-only on `operation` database
-- Full privileges (DDL + DML) on all other databases
-- ============================================================

-- Full privileges globally, then restrict operation below
GRANT CREATE DATABASE, DROP DATABASE ON *.* TO iso;
GRANT CREATE TABLE, DROP TABLE, TRUNCATE ON *.* TO iso;
GRANT SELECT, INSERT, ALTER UPDATE, ALTER DELETE ON *.* TO iso;

-- Lock down `operation` to read-only
REVOKE DROP DATABASE ON operation.* FROM iso;
REVOKE CREATE TABLE, DROP TABLE, TRUNCATE ON operation.* FROM iso;
REVOKE INSERT, ALTER UPDATE, ALTER DELETE ON operation.* FROM iso;

-- Lock down `system` to read-only
REVOKE DROP DATABASE ON system.* FROM iso;
REVOKE CREATE TABLE, DROP TABLE, TRUNCATE ON system.* FROM iso;
REVOKE INSERT, ALTER UPDATE, ALTER DELETE ON system.* FROM iso;

-- Lock down `information_schema` to read-only
REVOKE DROP DATABASE ON information_schema.* FROM iso;
REVOKE CREATE TABLE, DROP TABLE, TRUNCATE ON information_schema.* FROM iso;
REVOKE INSERT, ALTER UPDATE, ALTER DELETE ON information_schema.* FROM iso;

-- Reenable access to specific databases
GRANT SELECT ON operation.* TO iso;

-- Reset all privileges
REVOKE ALL ON *.* FROM iso;

-- Show all grants
SHOW GRANTS FOR iso;

-- ============================================================
-- USERS
-- ============================================================

-- ISO Users

CREATE USER IF NOT EXISTS user_name
    IDENTIFIED WITH sha256_password BY 'user_password'
    DEFAULT ROLE iso;