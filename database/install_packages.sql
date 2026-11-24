-- =====================================================================
-- DataMind AI | Package installer (safe to re-run: CREATE OR REPLACE)
-- Run from the project root, connected as DATAMIND_AI:
--   sqlplus DATAMIND_AI@127.0.0.1:1521/FREEPDB1 "@database/install_packages.sql"
-- Stops if any package fails to compile.
-- =====================================================================
WHENEVER SQLERROR EXIT SQL.SQLCODE
WHENEVER OSERROR EXIT FAILURE
SET FEEDBACK ON

BEGIN
  IF USER <> 'DATAMIND_AI' THEN
    RAISE_APPLICATION_ERROR(-20001, 'Connect as DATAMIND_AI, not ' || USER);
  END IF;
END;
/

PROMPT ===== PKG_DM_UTIL =====
@database/05_packages/pkg_dm_util.pks
@database/05_packages/pkg_dm_util.pkb

PROMPT ===== Compilation errors (should be none) =====
SET LINESIZE 200
COLUMN NAME FORMAT A20
COLUMN TEXT FORMAT A120
SELECT NAME, TYPE, LINE, TEXT FROM USER_ERRORS ORDER BY NAME, TYPE, SEQUENCE;

DECLARE
  l_errors NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_errors FROM USER_ERRORS;
  IF l_errors > 0 THEN
    RAISE_APPLICATION_ERROR(-20002, l_errors || ' compilation error(s) - see list above');
  END IF;
END;
/

PROMPT ===== All packages compiled =====
EXIT
