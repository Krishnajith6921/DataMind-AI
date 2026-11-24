-- =====================================================================
-- DataMind AI | Phase 1 indexes
-- Covers foreign keys and the filters the dashboard will use most
-- (batch, status, date). Primary/unique keys already create their own
-- indexes, e.g. DM_STAGING_SOURCE_ROW_UK covers STAGING.BATCH_ID.
-- Revisit with real execution plans once data volumes exist.
-- =====================================================================

-- Batch list filtered by status, newest first
CREATE INDEX DM_BATCH_STATUS_IX   ON DM_BATCH_MASTER (BATCH_STATUS, CREATED_DATE);

-- Records of a batch in a given status (e.g. all INVALID rows of batch 42)
CREATE INDEX DM_STAGING_STATUS_IX ON DM_STAGING_CUSTOMER (BATCH_ID, RECORD_STATUS);

-- FK: customers loaded by a batch
CREATE INDEX DM_CUSTOMER_BATCH_IX ON DM_CUSTOMER_MASTER (SOURCE_BATCH_ID);

-- FKs + dashboard filters on validation findings
CREATE INDEX DM_VALRES_BATCH_IX   ON DM_VALIDATION_RESULT (BATCH_ID, SEVERITY);
CREATE INDEX DM_VALRES_STAGING_IX ON DM_VALIDATION_RESULT (STAGING_ID);
CREATE INDEX DM_VALRES_RULE_IX    ON DM_VALIDATION_RESULT (RULE_ID);

-- Incident centre: open incidents by date, incidents of a batch
CREATE INDEX DM_INCIDENT_STATUS_IX ON DM_DATABASE_INCIDENT (INCIDENT_STATUS, CREATED_DATE);
CREATE INDEX DM_INCIDENT_BATCH_IX  ON DM_DATABASE_INCIDENT (BATCH_ID);

-- Audit history by date and by object
CREATE INDEX DM_AUDIT_DATE_IX   ON DM_AUDIT_LOG (CREATED_DATE);
CREATE INDEX DM_AUDIT_OBJECT_IX ON DM_AUDIT_LOG (OBJECT_NAME, OBJECT_ID);
