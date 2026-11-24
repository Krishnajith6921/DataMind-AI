-- =====================================================================
-- DataMind AI | PKG_DM_UTIL (specification)
-- Shared helpers used by every other PKG_DM_ package:
--   * status codes for P_ERR_STATUS OUT parameters
--   * text / email / phone normalisation (used by validation + duplicates)
--   * correlation IDs (link UI -> API -> batch -> AI in logs)
--   * incident logging (Oracle errors) and audit logging
--
-- Transaction convention for the whole project:
--   * Public PKG_DM_ procedures called by the API own their unit of work:
--     COMMIT on success, ROLLBACK on failure, and report via
--     P_ERR_STATUS / P_ERR_MSG instead of raising.
--   * LOG_INCIDENT_PRC is an AUTONOMOUS transaction: the incident is saved
--     even when the caller rolls back its business work.
--   * LOG_AUDIT_PRC is NOT autonomous: an audit row is kept only if the
--     business action it describes is committed.
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_DM_UTIL AS

  C_SUCCESS CONSTANT NUMBER := 0;
  C_ERROR   CONSTANT NUMBER := 1;

  -- 'Asha   Nair ' -> 'ASHA NAIR'
  FUNCTION NORMALIZE_TEXT_FN (P_TEXT IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;

  -- ' Asha@Mail.COM ' -> 'asha@mail.com'
  FUNCTION NORMALIZE_EMAIL_FN (P_EMAIL IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;

  -- '+91 98765-43210' -> '+919876543210' (digits only, leading + kept)
  FUNCTION NORMALIZE_PHONE_FN (P_PHONE IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;

  -- New random 32-character id
  FUNCTION NEW_CORRELATION_ID_FN RETURN VARCHAR2;

  -- Correlation id for the current session (set by the API per request).
  -- GET creates one automatically if none was set.
  PROCEDURE SET_CORRELATION_ID_PRC (P_CORRELATION_ID IN VARCHAR2);
  FUNCTION  GET_CORRELATION_ID_FN RETURN VARCHAR2;

  -- Call from inside an EXCEPTION handler. Captures SQLCODE, SQLERRM,
  -- error stack and backtrace into DM_DATABASE_INCIDENT.
  -- Never raises: logging must not hide the original error.
  -- P_CONTEXT, if given, must be JSON.
  PROCEDURE LOG_INCIDENT_PRC (
    P_MODULE_NAME    IN  VARCHAR2,
    P_PROCEDURE_NAME IN  VARCHAR2,
    P_BATCH_ID       IN  NUMBER DEFAULT NULL,
    P_CONTEXT        IN  CLOB   DEFAULT NULL,
    P_INCIDENT_ID    OUT NUMBER);

  -- Same, when the caller does not need the incident id.
  PROCEDURE LOG_INCIDENT_PRC (
    P_MODULE_NAME    IN  VARCHAR2,
    P_PROCEDURE_NAME IN  VARCHAR2,
    P_BATCH_ID       IN  NUMBER DEFAULT NULL,
    P_CONTEXT        IN  CLOB   DEFAULT NULL);

  -- Writes one row to DM_AUDIT_LOG inside the caller's transaction.
  PROCEDURE LOG_AUDIT_PRC (
    P_ACTION_NAME   IN VARCHAR2,
    P_OBJECT_NAME   IN VARCHAR2 DEFAULT NULL,
    P_OBJECT_ID     IN VARCHAR2 DEFAULT NULL,
    P_OLD_VALUE     IN CLOB     DEFAULT NULL,
    P_NEW_VALUE     IN CLOB     DEFAULT NULL,
    P_ACTION_STATUS IN VARCHAR2 DEFAULT 'SUCCESS');

END PKG_DM_UTIL;
/
