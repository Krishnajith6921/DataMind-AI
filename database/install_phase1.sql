-- =====================================================================
-- DataMind AI | Phase 1 installer (tables + indexes)
-- Run from the project root, connected as DATAMIND_AI:
--   sqlplus DATAMIND_AI@127.0.0.1:1521/FREEPDB1 "@database/install_phase1.sql"
-- Must be run from the project root folder. Stops at the first error.
-- =====================================================================
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE
SET FEEDBACK ON
SET ECHO OFF

-- Safety: never create project objects in SYS/SYSTEM by accident.
BEGIN
  IF USER <> 'DATAMIND_AI' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Connect as DATAMIND_AI, not ' || USER);
  END IF;
END;
/

PROMPT ===== Tables =====
@database/01_schema/01_dm_batch_master.sql
@database/01_schema/02_dm_batch_details.sql
@database/01_schema/03_dm_staging_customer.sql
@database/01_schema/04_dm_customer_master.sql
@database/01_schema/05_dm_validation_rule.sql
@database/01_schema/06_dm_validation_result.sql
@database/01_schema/07_dm_database_incident.sql
@database/01_schema/08_dm_audit_log.sql

PROMPT ===== Indexes =====
@database/03_indexes/01_phase1_indexes.sql

PROMPT ===== Installed tables =====
SET HEADING ON
COLUMN TABLE_NAME FORMAT A25
SELECT TABLE_NAME FROM USER_TABLES ORDER BY TABLE_NAME;

EXIT
