-- =====================================================================
-- DataMind AI | Tests for PKG_DM_UTIL
-- Run from the project root, connected as DATAMIND_AI:
--   sqlplus DATAMIND_AI@127.0.0.1:1521/FREEPDB1 "@database/09_test_scripts/test_pkg_dm_util.sql"
-- Leaves no test data behind. Exits with an error if any test fails.
-- =====================================================================
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF

DECLARE
  g_failures NUMBER := 0;
  l_incident_id NUMBER;
  l_row DM_DATABASE_INCIDENT%ROWTYPE;
  l_count NUMBER;
  l_corr VARCHAR2(64);

  PROCEDURE check_equal (p_name VARCHAR2, p_actual VARCHAR2, p_expected VARCHAR2) IS
  BEGIN
    IF (p_actual = p_expected) OR (p_actual IS NULL AND p_expected IS NULL) THEN
      DBMS_OUTPUT.PUT_LINE('PASS  ' || p_name);
    ELSE
      g_failures := g_failures + 1;
      DBMS_OUTPUT.PUT_LINE('FAIL  ' || p_name || '  expected [' || p_expected || '] got [' || p_actual || ']');
    END IF;
  END;

  PROCEDURE check_true (p_name VARCHAR2, p_condition BOOLEAN) IS
  BEGIN
    check_equal(p_name, CASE WHEN p_condition THEN 'TRUE' ELSE 'FALSE' END, 'TRUE');
  END;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Normalisation ---');
  check_equal('text: trims, collapses spaces, upper-cases', PKG_DM_UTIL.NORMALIZE_TEXT_FN('  Asha    Nair '), 'ASHA NAIR');
  check_equal('text: tabs/newlines become one space',      PKG_DM_UTIL.NORMALIZE_TEXT_FN('Asha' || CHR(9) || CHR(10) || 'Nair'), 'ASHA NAIR');
  check_equal('text: NULL stays NULL',                      PKG_DM_UTIL.NORMALIZE_TEXT_FN(NULL), NULL);
  check_equal('email: trims and lower-cases',               PKG_DM_UTIL.NORMALIZE_EMAIL_FN(' Asha@Mail.COM '), 'asha@mail.com');
  check_equal('phone: keeps + and digits only',             PKG_DM_UTIL.NORMALIZE_PHONE_FN('+91 98765-43210'), '+919876543210');
  check_equal('phone: brackets and spaces removed',         PKG_DM_UTIL.NORMALIZE_PHONE_FN('(0484) 123 456'), '0484123456');
  check_equal('phone: no digits -> NULL',                   PKG_DM_UTIL.NORMALIZE_PHONE_FN('N/A'), NULL);

  DBMS_OUTPUT.PUT_LINE('--- Correlation id ---');
  l_corr := PKG_DM_UTIL.GET_CORRELATION_ID_FN;
  check_true ('auto-generated id is 32 characters',  LENGTH(l_corr) = 32);
  check_equal('same id returned within the session', PKG_DM_UTIL.GET_CORRELATION_ID_FN, l_corr);
  PKG_DM_UTIL.SET_CORRELATION_ID_PRC('test-request-001');
  check_equal('id set by the API is used',           PKG_DM_UTIL.GET_CORRELATION_ID_FN, 'test-request-001');

  DBMS_OUTPUT.PUT_LINE('--- Incident logging ---');
  BEGIN
    l_count := 1 / 0;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_DM_UTIL.LOG_INCIDENT_PRC('TEST_PKG_DM_UTIL', 'DIVIDE_TEST', NULL, '{"step":"divide"}', l_incident_id);
  END;
  check_true('incident id returned', l_incident_id IS NOT NULL);
  SELECT * INTO l_row FROM DM_DATABASE_INCIDENT WHERE INCIDENT_ID = l_incident_id;
  check_equal('error code captured (ORA-01476 divide by zero)', TO_CHAR(l_row.ERROR_CODE), '-1476');
  check_true ('backtrace captured (has line number)', DBMS_LOB.INSTR(l_row.ERROR_BACKTRACE, 'line') > 0);
  check_equal('correlation id stored',  l_row.CORRELATION_ID, 'test-request-001');
  check_equal('status starts as OPEN',  l_row.INCIDENT_STATUS, 'OPEN');

  -- Incident survives the caller's rollback (autonomous transaction)
  ROLLBACK;
  SELECT COUNT(*) INTO l_count FROM DM_DATABASE_INCIDENT WHERE INCIDENT_ID = l_incident_id;
  check_equal('incident kept after caller ROLLBACK', TO_CHAR(l_count), '1');

  -- Invalid JSON context must not stop the logging
  BEGIN
    RAISE NO_DATA_FOUND;
  EXCEPTION
    WHEN OTHERS THEN
      PKG_DM_UTIL.LOG_INCIDENT_PRC('TEST_PKG_DM_UTIL', 'BAD_CONTEXT_TEST', NULL, 'not json', l_incident_id);
  END;
  check_true('incident logged even with bad JSON context', l_incident_id IS NOT NULL);

  DBMS_OUTPUT.PUT_LINE('--- Audit logging ---');
  PKG_DM_UTIL.LOG_AUDIT_PRC('TEST_ACTION', 'DM_BATCH_MASTER', '42');
  SELECT COUNT(*) INTO l_count FROM DM_AUDIT_LOG WHERE ACTION_NAME = 'TEST_ACTION';
  check_equal('audit row written', TO_CHAR(l_count), '1');
  ROLLBACK;
  SELECT COUNT(*) INTO l_count FROM DM_AUDIT_LOG WHERE ACTION_NAME = 'TEST_ACTION';
  check_equal('audit row removed by caller ROLLBACK', TO_CHAR(l_count), '0');

  -- Clean up committed test incidents
  DELETE FROM DM_DATABASE_INCIDENT WHERE MODULE_NAME = 'TEST_PKG_DM_UTIL';
  COMMIT;
  PKG_DM_UTIL.SET_CORRELATION_ID_PRC(NULL);

  DBMS_OUTPUT.PUT_LINE('-----------------------------------');
  IF g_failures > 0 THEN
    RAISE_APPLICATION_ERROR(-20999, g_failures || ' test(s) FAILED');
  END IF;
  DBMS_OUTPUT.PUT_LINE('ALL PKG_DM_UTIL TESTS PASSED');
END;
/
EXIT
