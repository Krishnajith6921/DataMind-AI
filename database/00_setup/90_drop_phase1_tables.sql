-- =====================================================================
-- DataMind AI | DEV ONLY: drop all Phase 1 tables (and their data!)
-- Use when you want to reinstall from scratch during development:
--   sqlplus DATAMIND_AI@127.0.0.1:1521/FREEPDB1 "@database/00_setup/90_drop_phase1_tables.sql"
-- Never run against a database whose data you need.
-- =====================================================================
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON

DECLARE
  TYPE t_names IS TABLE OF VARCHAR2(128);
  -- children first, parents last
  l_tables t_names := t_names(
    'DM_VALIDATION_RESULT', 'DM_VALIDATION_RULE', 'DM_CUSTOMER_MASTER',
    'DM_STAGING_CUSTOMER', 'DM_BATCH_DETAILS', 'DM_DATABASE_INCIDENT',
    'DM_AUDIT_LOG', 'DM_BATCH_MASTER');
  l_count NUMBER;
BEGIN
  IF USER <> 'DATAMIND_AI' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Connect as DATAMIND_AI, not ' || USER);
  END IF;
  FOR i IN 1 .. l_tables.COUNT LOOP
    SELECT COUNT(*) INTO l_count FROM user_tables WHERE table_name = l_tables(i);
    IF l_count > 0 THEN
      EXECUTE IMMEDIATE 'DROP TABLE ' || DBMS_ASSERT.SIMPLE_SQL_NAME(l_tables(i)) || ' CASCADE CONSTRAINTS PURGE';
      DBMS_OUTPUT.PUT_LINE('Dropped ' || l_tables(i));
    END IF;
  END LOOP;
END;
/
EXIT
