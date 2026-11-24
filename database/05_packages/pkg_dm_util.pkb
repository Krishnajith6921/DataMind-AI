-- =====================================================================
-- DataMind AI | PKG_DM_UTIL (body)
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKG_DM_UTIL AS

  -- Correlation id for this database session
  g_correlation_id VARCHAR2(64);

  -- -------------------------------------------------------------------
  FUNCTION NORMALIZE_TEXT_FN (P_TEXT IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
  BEGIN
    RETURN UPPER(TRIM(REGEXP_REPLACE(P_TEXT, '[[:space:]]+', ' ')));
  END NORMALIZE_TEXT_FN;

  -- -------------------------------------------------------------------
  FUNCTION NORMALIZE_EMAIL_FN (P_EMAIL IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
  BEGIN
    RETURN LOWER(TRIM(P_EMAIL));
  END NORMALIZE_EMAIL_FN;

  -- -------------------------------------------------------------------
  FUNCTION NORMALIZE_PHONE_FN (P_PHONE IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
    l_digits VARCHAR2(100);
  BEGIN
    l_digits := REGEXP_REPLACE(P_PHONE, '[^0-9]', '');
    IF SUBSTR(TRIM(P_PHONE), 1, 1) = '+' AND l_digits IS NOT NULL THEN
      RETURN '+' || l_digits;
    END IF;
    RETURN l_digits;
  END NORMALIZE_PHONE_FN;

  -- -------------------------------------------------------------------
  FUNCTION NEW_CORRELATION_ID_FN RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END NEW_CORRELATION_ID_FN;

  -- -------------------------------------------------------------------
  PROCEDURE SET_CORRELATION_ID_PRC (P_CORRELATION_ID IN VARCHAR2) IS
  BEGIN
    IF P_CORRELATION_ID IS NOT NULL AND LENGTH(P_CORRELATION_ID) > 64 THEN
      RAISE_APPLICATION_ERROR(-20010, 'Correlation id longer than 64 characters');
    END IF;
    g_correlation_id := P_CORRELATION_ID;
  END SET_CORRELATION_ID_PRC;

  -- -------------------------------------------------------------------
  FUNCTION GET_CORRELATION_ID_FN RETURN VARCHAR2 IS
  BEGIN
    IF g_correlation_id IS NULL THEN
      g_correlation_id := NEW_CORRELATION_ID_FN;
    END IF;
    RETURN g_correlation_id;
  END GET_CORRELATION_ID_FN;

  -- -------------------------------------------------------------------
  PROCEDURE LOG_INCIDENT_PRC (
    P_MODULE_NAME    IN  VARCHAR2,
    P_PROCEDURE_NAME IN  VARCHAR2,
    P_BATCH_ID       IN  NUMBER DEFAULT NULL,
    P_CONTEXT        IN  CLOB   DEFAULT NULL,
    P_INCIDENT_ID    OUT NUMBER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    -- Capture the error details first, before anything else can change them
    l_code      NUMBER         := SQLCODE;
    l_message   VARCHAR2(4000) := SUBSTR(SQLERRM, 1, 4000);
    l_stack     CLOB           := DBMS_UTILITY.FORMAT_ERROR_STACK;
    l_backtrace CLOB           := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    l_corr_id   VARCHAR2(64)   := GET_CORRELATION_ID_FN;

    PROCEDURE insert_incident (p_ctx IN CLOB) IS
    BEGIN
      INSERT INTO DM_DATABASE_INCIDENT
        (BATCH_ID, ERROR_CODE, ERROR_MESSAGE, ERROR_STACK, ERROR_BACKTRACE,
         MODULE_NAME, PROCEDURE_NAME, EXECUTION_CONTEXT, CORRELATION_ID)
      VALUES
        (P_BATCH_ID, l_code, l_message, l_stack, l_backtrace,
         SUBSTR(P_MODULE_NAME, 1, 200), SUBSTR(P_PROCEDURE_NAME, 1, 200), p_ctx, l_corr_id)
      RETURNING INCIDENT_ID INTO P_INCIDENT_ID;
    END insert_incident;
  BEGIN
    BEGIN
      insert_incident(P_CONTEXT);
    EXCEPTION
      WHEN OTHERS THEN
        -- Most likely P_CONTEXT was not valid JSON: keep the error, drop the context
        insert_incident(NULL);
    END;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      -- Logging must never mask the caller's original error
      ROLLBACK;
      P_INCIDENT_ID := NULL;
  END LOG_INCIDENT_PRC;

  -- -------------------------------------------------------------------
  PROCEDURE LOG_INCIDENT_PRC (
    P_MODULE_NAME    IN VARCHAR2,
    P_PROCEDURE_NAME IN VARCHAR2,
    P_BATCH_ID       IN NUMBER DEFAULT NULL,
    P_CONTEXT        IN CLOB   DEFAULT NULL)
  IS
    l_ignore NUMBER;
  BEGIN
    LOG_INCIDENT_PRC(P_MODULE_NAME, P_PROCEDURE_NAME, P_BATCH_ID, P_CONTEXT, l_ignore);
  END LOG_INCIDENT_PRC;

  -- -------------------------------------------------------------------
  PROCEDURE LOG_AUDIT_PRC (
    P_ACTION_NAME   IN VARCHAR2,
    P_OBJECT_NAME   IN VARCHAR2 DEFAULT NULL,
    P_OBJECT_ID     IN VARCHAR2 DEFAULT NULL,
    P_OLD_VALUE     IN CLOB     DEFAULT NULL,
    P_NEW_VALUE     IN CLOB     DEFAULT NULL,
    P_ACTION_STATUS IN VARCHAR2 DEFAULT 'SUCCESS')
  IS
  BEGIN
    INSERT INTO DM_AUDIT_LOG
      (ACTION_NAME, OBJECT_NAME, OBJECT_ID, OLD_VALUE, NEW_VALUE,
       ACTION_STATUS, CORRELATION_ID)
    VALUES
      (P_ACTION_NAME, P_OBJECT_NAME, P_OBJECT_ID, P_OLD_VALUE, P_NEW_VALUE,
       P_ACTION_STATUS, GET_CORRELATION_ID_FN);
  END LOG_AUDIT_PRC;

END PKG_DM_UTIL;
/
