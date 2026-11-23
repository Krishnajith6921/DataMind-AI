-- =====================================================================
-- DataMind AI | database/00_setup/01_create_schema.sql
--
-- Purpose : Create the DATAMIND_AI application schema (owner of all
--           DM_ tables and PKG_DM_ packages) inside pluggable DB FREEPDB1.
-- Run as  : SYSDBA, from the project root folder:
--             sqlplus / as sysdba @database/00_setup/01_create_schema.sql
-- Password: You are prompted for it twice. Input is hidden and is not
--           stored anywhere by this script. Avoid quotes ( ' " ), @ and $.
-- Re-run  : Safe. Stops without changes if DATAMIND_AI already exists.
-- =====================================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET VERIFY OFF
SET FEEDBACK ON

-- All project objects live in the pluggable database, never in CDB root.
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Guard: do nothing if the schema already exists.
DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM dba_users WHERE username = 'DATAMIND_AI';
  IF l_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'User DATAMIND_AI already exists - nothing to do.');
  END IF;
END;
/

ACCEPT dm_password  CHAR PROMPT 'Enter new password for DATAMIND_AI : ' HIDE
ACCEPT dm_password2 CHAR PROMPT 'Re-enter the same password         : ' HIDE

-- Guard: both entries must match.
BEGIN
  IF '&dm_password' IS NULL OR '&dm_password' <> '&dm_password2' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Passwords are empty or do not match - nothing created.');
  END IF;
END;
/

CREATE USER DATAMIND_AI IDENTIFIED BY "&dm_password"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA 2G ON USERS;

-- Least privilege: only what the schema owner needs to build the project.
-- (Explicit grants instead of DB_DEVELOPER_ROLE keep us 19c-compatible.)
-- NOTE: in SQL*Plus a ';' must be the LAST character on the line. A trailing
-- "-- comment" after ';' silently prevents the statement from running.
--   CREATE SESSION   : connect
--   CREATE TABLE     : DM_ tables
--   CREATE VIEW      : reporting / AI-allowlisted views
--   CREATE SEQUENCE  : sequences if ever needed
--   CREATE PROCEDURE : PKG_DM_ packages
--   CREATE TRIGGER   : audit triggers
--   CREATE TYPE      : collection types for BULK COLLECT
--   CREATE SYNONYM   : private synonyms
--   CREATE JOB       : DBMS_SCHEDULER monitoring jobs (weeks 11-12)
GRANT CREATE SESSION   TO DATAMIND_AI;
GRANT CREATE TABLE     TO DATAMIND_AI;
GRANT CREATE VIEW      TO DATAMIND_AI;
GRANT CREATE SEQUENCE  TO DATAMIND_AI;
GRANT CREATE PROCEDURE TO DATAMIND_AI;
GRANT CREATE TRIGGER   TO DATAMIND_AI;
GRANT CREATE TYPE      TO DATAMIND_AI;
GRANT CREATE SYNONYM   TO DATAMIND_AI;
GRANT CREATE JOB       TO DATAMIND_AI;

-- Privileges for performance monitoring (V$ views) are granted later, in a
-- separate script, when that module is built.

UNDEFINE dm_password
UNDEFINE dm_password2

PROMPT
PROMPT  DATAMIND_AI created in FREEPDB1.
PROMPT  Next: put the same password in your local .env file (ORACLE_PASSWORD=...).
PROMPT
EXIT
