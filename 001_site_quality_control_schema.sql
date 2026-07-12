-- =============================================================================
-- Porta Plywood — site_quality_control MES schema
-- Target: PostgreSQL 14+
-- Version: 1.0  |  2026-07-10
-- =============================================================================
-- Delta vs. old site_quality_control project: this is a clean redesign, not a
-- migration script. The old project's 4 tables (site_lathe_quality,
-- site_dryer_quality, site_dryer_outfeed_quality, finished_panel_thickness)
-- had inconsistent column naming (t_stamp vs date_time) and no line/operator/
-- shift/audit columns at all. This schema keeps the same measurement fields
-- (verified against the remediated project export) but adds the columns the
-- architect skill's schema standards require for every transactional table.
-- If historical data from the old tables needs to be preserved, that's a
-- separate ETL step — flagging here rather than silently assuming a migration
-- path, since I don't have the live row counts or retention requirements.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS qc;

-- -----------------------------------------------------------------------------
-- Shared reference: process lines (single line today; table exists so a second
-- line is a row, not a schema change — this is the one piece of "future-proofing"
-- kept, because it costs nothing now and the alternative is a hardcoded string
-- sprinkled through every query).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qc.lines (
    line_id         VARCHAR(32)  PRIMARY KEY,
    line_name       VARCHAR(128) NOT NULL,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO qc.lines (line_id, line_name)
VALUES ('MYRTLEFORD_L1', 'Porta Myrtleford — Plywood Line 1')
ON CONFLICT (line_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Table: qc.lathe_quality
-- Fields carried forward unchanged from site_lathe_quality (remediated export).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qc.lathe_quality (
    record_id           BIGSERIAL PRIMARY KEY,
    line_id             VARCHAR(32)  NOT NULL REFERENCES qc.lines(line_id),
    station_id          VARCHAR(32)  NOT NULL DEFAULT 'LATHE',
    t_stamp             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    thickness_1         NUMERIC(6,3) NOT NULL,
    thickness_2         NUMERIC(6,3) NOT NULL,
    thickness_3         NUMERIC(6,3) NOT NULL,
    target_thickness    NUMERIC(6,3) NOT NULL,
    operator_id         VARCHAR(64)  NOT NULL,
    shift_code          VARCHAR(8)   NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          VARCHAR(64)  NOT NULL,
    modified_at         TIMESTAMP WITH TIME ZONE,
    modified_by         VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_lathe_quality_tstamp   ON qc.lathe_quality (t_stamp);
CREATE INDEX IF NOT EXISTS idx_lathe_quality_line     ON qc.lathe_quality (line_id, t_stamp);

-- -----------------------------------------------------------------------------
-- Table: qc.dryer_quality
-- Shared shape for BOTH infeed and outfeed (confirmed identical field sets in
-- the remediated export) — stage_position distinguishes them instead of two
-- near-duplicate tables. This directly removes the t_stamp/date_time drift
-- that caused H found-and-fixed in the last audit: one table, one column name.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qc.dryer_quality (
    record_id           BIGSERIAL PRIMARY KEY,
    line_id             VARCHAR(32)  NOT NULL REFERENCES qc.lines(line_id),
    stage_position       VARCHAR(8)   NOT NULL CHECK (stage_position IN ('INFEED', 'OUTFEED')),
    t_stamp             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    thickness_1         NUMERIC(6,3) NOT NULL,
    thickness_2         NUMERIC(6,3) NOT NULL,
    thickness_3         NUMERIC(6,3) NOT NULL,
    width               NUMERIC(7,2) NOT NULL,
    moisture_min         NUMERIC(5,2) NOT NULL,
    moisture_max         NUMERIC(5,2) NOT NULL,
    operator_id          VARCHAR(64)  NOT NULL,
    shift_code           VARCHAR(8)   NOT NULL,
    created_at           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           VARCHAR(64)  NOT NULL,
    modified_at          TIMESTAMP WITH TIME ZONE,
    modified_by          VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_dryer_quality_tstamp  ON qc.dryer_quality (t_stamp);
CREATE INDEX IF NOT EXISTS idx_dryer_quality_line    ON qc.dryer_quality (line_id, stage_position, t_stamp);

-- -----------------------------------------------------------------------------
-- Table: qc.finished_panel_quality
-- Per-side moisture readings, carried forward from finished_panel_thickness.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qc.finished_panel_quality (
    record_id           BIGSERIAL PRIMARY KEY,
    line_id              VARCHAR(32)  NOT NULL REFERENCES qc.lines(line_id),
    station_id           VARCHAR(32)  NOT NULL DEFAULT 'FINISHED_PANEL',
    t_stamp              TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    product_code          VARCHAR(64)  NOT NULL,
    face_grade            VARCHAR(16),
    moisture_lhs          NUMERIC(5,2) NOT NULL,
    moisture_mid          NUMERIC(5,2) NOT NULL,
    moisture_rhs          NUMERIC(5,2) NOT NULL,
    operator_id           VARCHAR(64)  NOT NULL,
    shift_code            VARCHAR(8)   NOT NULL,
    created_at            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by            VARCHAR(64)  NOT NULL,
    modified_at           TIMESTAMP WITH TIME ZONE,
    modified_by           VARCHAR(64)
);

CREATE INDEX IF NOT EXISTS idx_finished_panel_tstamp ON qc.finished_panel_quality (t_stamp);
CREATE INDEX IF NOT EXISTS idx_finished_panel_line   ON qc.finished_panel_quality (line_id, t_stamp);

-- -----------------------------------------------------------------------------
-- Table: qc.alarm_journal
-- New — per alarms-and-pipelines.md: alarm history belongs in the database,
-- not just the Gateway's internal store, so QA/Compliance retains a queryable
-- record independent of Gateway alarm-log retention settings.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qc.alarm_journal (
    event_id        BIGSERIAL PRIMARY KEY,
    source_path     VARCHAR(256) NOT NULL,
    display_path    VARCHAR(256) NOT NULL,
    priority        VARCHAR(16)  NOT NULL CHECK (priority IN ('Low','Medium','High','Critical')),
    state           VARCHAR(16)  NOT NULL CHECK (state IN ('Active','Cleared','Acknowledged')),
    event_time      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ack_time        TIMESTAMP WITH TIME ZONE,
    ack_user        VARCHAR(64),
    ack_notes       VARCHAR(512)
);

CREATE INDEX IF NOT EXISTS idx_alarm_journal_time ON qc.alarm_journal (event_time);
CREATE INDEX IF NOT EXISTS idx_alarm_journal_state ON qc.alarm_journal (state);

-- -----------------------------------------------------------------------------
-- Quality targets — replaces the hardcoded "2.6mm and 3.2mm only" UCL/LCL
-- disclaimer from the old lathe_spc query with an actual configurable table.
-- The old system's [ASSUMED TYPICAL ±0.15mm] band width lives here now as
-- data instead of a buried SQL constant — Supervisor role can maintain it,
-- QA can audit changes via modified_by/modified_at.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS qc.quality_targets (
    target_thickness    NUMERIC(6,3) PRIMARY KEY,
    ucl_offset          NUMERIC(6,3) NOT NULL,
    lcl_offset          NUMERIC(6,3) NOT NULL,
    modified_at         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modified_by         VARCHAR(64)  NOT NULL DEFAULT 'SYSTEM_INIT'
);

-- Seed with the two confirmed bands from the old lathe_spc view's disclaimer.
-- [ASSUMED TYPICAL - NOT VERIFIED AGAINST DATASHEET] ±0.15mm carried forward
-- as a starting value only — confirm against the real quality spec sheet.
INSERT INTO qc.quality_targets (target_thickness, ucl_offset, lcl_offset, modified_by)
VALUES (2.6, 0.15, 0.15, 'SYSTEM_INIT'), (3.2, 0.15, 0.15, 'SYSTEM_INIT')
ON CONFLICT (target_thickness) DO NOTHING;
