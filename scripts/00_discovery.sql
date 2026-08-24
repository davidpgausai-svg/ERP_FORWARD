-- ============================================================
-- 00_discovery.sql  (KIT v2)
-- RUN FIRST against each instance (HCM, FSCM, CS).
-- Pure SELECTs. Establishes: platform, release, licensed modules,
-- object volumes, telemetry availability, and the version-variable
-- table families the later packs generate against.
--
-- v2 changes vs v1:
--   + installed/licensed module check (PS_INSTALLATION*) — decides scope
--   + tableset control discovery (SETID is meaningless without it)
--   + LONG/CLOB datatype probe (v1 would have silently truncated SQL text)
--   + volume guards on the tables that are dangerous to SELECT *
--   + SQL Server / DB2 variants inline, not just "noted"
--   + PSPRCSDEFNPNL name corrected (v1 said PS_PRCSDEFNPNL — does not exist)
-- ============================================================

-- ------------------------------------------------------------
-- 0.1 Platform, tools release, application release
-- ------------------------------------------------------------
SELECT * FROM PSSTATUS;                        -- TOOLSREL, LASTREFRESHDTTM, DBNAME
SELECT * FROM PSRELEASE ORDER BY RELEASEDTTM;  -- application release history
SELECT * FROM PSOPTIONS;                       -- multi-currency, language, base ccy

-- Oracle only: confirm you are on the replica you think you are.
SELECT SYS_CONTEXT('USERENV','DB_NAME')   AS DB_NAME,
       SYS_CONTEXT('USERENV','DB_UNIQUE_NAME') AS DB_UNIQUE_NAME,
       SYS_CONTEXT('USERENV','CURRENT_SCHEMA') AS CURRENT_SCHEMA,
       SYSDATE AS EXTRACT_RUN_AT
  FROM DUAL;
-- SQL Server:  SELECT DB_NAME() AS DB_NAME, SUSER_SNAME() AS LOGIN, GETDATE() AS EXTRACT_RUN_AT;
-- DB2 z/OS  :  SELECT CURRENT SERVER, CURRENT SQLID, CURRENT TIMESTAMP FROM SYSIBM.SYSDUMMY1;

-- ------------------------------------------------------------
-- 0.2 WHAT IS ACTUALLY LICENSED / INSTALLED  ** new in v2 **
-- Do not scope a discovery program off an org chart. Scope it off
-- the installation record: it is the system's own statement of
-- which products are turned on.
-- ------------------------------------------------------------
SELECT RECNAME, RECDESCR FROM PSRECDEFN
 WHERE RECNAME IN ('INSTALLATION','INSTALLATION_FS','INSTALLATION_HR',
                   'INSTALLATION_PY','INSTALLATION_BN','INSTALLATION_TL',
                   'INSTALLATION_AM','INSTALLATION_PC','INSTALLATION_GM',
                   'INSTALLATION_EX','INSTALLATION_AP','INSTALLATION_AR',
                   'INSTALLATION_BI','INSTALLATION_PO','INSTALLATION_IN',
                   'INSTALLATION_KK','INSTALLATION_CS','INSTALLATION_SF');
-- Extract every one the guard returns, e.g.:
--   SELECT * FROM PS_INSTALLATION;
--   SELECT * FROM PS_INSTALLATION_FS;
--   SELECT * FROM PS_INSTALLATION_HR;
--   ... (see 03x anchor files; each begins with the same guard pattern)

-- Product registration / licence codes
SELECT * FROM PSPRODLIC;            -- licensed products (existence varies by tools rel)
SELECT * FROM PSOBJGROUP;           -- object owner-ID decode (HR, PY, GL, AP, SF ...)

-- ------------------------------------------------------------
-- 0.3 Size of the metadata estate — sets expectations for Packs 1/2
-- ------------------------------------------------------------
SELECT 'PSRECDEFN'      AS OBJ, COUNT(*) AS CNT FROM PSRECDEFN      UNION ALL
SELECT 'PSRECFIELD'           , COUNT(*)        FROM PSRECFIELD     UNION ALL
SELECT 'PSRECFIELDDB'         , COUNT(*)        FROM PSRECFIELDDB   UNION ALL
SELECT 'PSDBFIELD'            , COUNT(*)        FROM PSDBFIELD      UNION ALL
SELECT 'PSPNLDEFN'            , COUNT(*)        FROM PSPNLDEFN      UNION ALL
SELECT 'PSPNLFIELD'           , COUNT(*)        FROM PSPNLFIELD     UNION ALL
SELECT 'PSPNLGRPDEFN'         , COUNT(*)        FROM PSPNLGRPDEFN   UNION ALL
SELECT 'PSMENUDEFN'           , COUNT(*)        FROM PSMENUDEFN     UNION ALL
SELECT 'PSPCMPROG'            , COUNT(*)        FROM PSPCMPROG      UNION ALL
SELECT 'PSSQLDEFN'            , COUNT(*)        FROM PSSQLDEFN      UNION ALL
SELECT 'PSSQLTEXTDEFN'        , COUNT(*)        FROM PSSQLTEXTDEFN  UNION ALL
SELECT 'PSAEAPPLDEFN'         , COUNT(*)        FROM PSAEAPPLDEFN   UNION ALL
SELECT 'PSAESTMTDEFN'         , COUNT(*)        FROM PSAESTMTDEFN   UNION ALL
SELECT 'PSQRYDEFN'            , COUNT(*)        FROM PSQRYDEFN      UNION ALL
SELECT 'PSPRCSDEFN'           , COUNT(*)        FROM PSPRCSDEFN     UNION ALL
SELECT 'PSJOBDEFN'            , COUNT(*)        FROM PSJOBDEFN      UNION ALL
SELECT 'PSPRSMDEFN'           , COUNT(*)        FROM PSPRSMDEFN     UNION ALL
SELECT 'PSTREEDEFN'           , COUNT(*)        FROM PSTREEDEFN     UNION ALL
SELECT 'PSTREENODE'           , COUNT(*)        FROM PSTREENODE     UNION ALL
SELECT 'PSTREELEAF'           , COUNT(*)        FROM PSTREELEAF     UNION ALL
SELECT 'PSROLEDEFN'           , COUNT(*)        FROM PSROLEDEFN     UNION ALL
SELECT 'PSCLASSDEFN'          , COUNT(*)        FROM PSCLASSDEFN    UNION ALL
SELECT 'PSAUTHITEM'           , COUNT(*)        FROM PSAUTHITEM     UNION ALL
SELECT 'PSROLEUSER'           , COUNT(*)        FROM PSROLEUSER     UNION ALL
SELECT 'PSOPRDEFN'            , COUNT(*)        FROM PSOPRDEFN      UNION ALL
SELECT 'PSPROJECTDEFN'        , COUNT(*)        FROM PSPROJECTDEFN;

-- VOLUME GUARD  ** new in v2 **
-- Anything above ~5,000,000 rows should NOT be pulled with a naive
-- SELECT * to CSV. In practice the repeat offenders are PSTREENODE,
-- PSTREELEAF, PSAUTHITEM, PSPNLFIELD and PSPRCSRQST. Record the counts
-- above in the manifest BEFORE extracting; 06_manifest_and_qa.sql
-- reconciles them afterwards.

-- ------------------------------------------------------------
-- 0.4 Datatype probe — the silent-truncation trap  ** new in v2 **
-- PSSQLTEXTDEFN.SQLTEXT and PSPCMPROG.PROGTXT are LONG / LONG RAW on
-- many Oracle installs. Most CSV spool tools truncate LONG at 80 chars
-- (SQL*Plus default) or fail outright. v1 said "SELECT *" and would
-- have produced a reporting estate full of one-line stubs.
-- ------------------------------------------------------------
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_LENGTH
  FROM ALL_TAB_COLUMNS
 WHERE TABLE_NAME IN ('PSSQLTEXTDEFN','PSPCMPROG','PSAESTMTDEFN',
                      'PSQRYDEFN','PSXPTMPLDEFN','PSCONTENT')
   AND DATA_TYPE IN ('LONG','LONG RAW','CLOB','BLOB','NCLOB')
 ORDER BY TABLE_NAME, COLUMN_ID;
-- If DATA_TYPE = LONG, extract with:  SET LONG 2000000  SET LONGCHUNKSIZE 2000000
-- or convert:  SELECT TO_LOB(SQLTEXT) ... (requires a CTAS staging table),
-- or use SQLcl / Data Pump rather than SQL*Plus spool. See README §Extract mechanics.
-- SQL Server: these are VARCHAR(MAX)/IMAGE — check with
--   SELECT c.name, t.name, c.max_length FROM sys.columns c
--     JOIN sys.types t ON t.user_type_id=c.user_type_id
--    WHERE OBJECT_NAME(c.object_id) IN ('PSSQLTEXTDEFN','PSPCMPROG');

-- ------------------------------------------------------------
-- 0.5 Version-variable table families — generate extract lists
-- ------------------------------------------------------------
-- Approval Workflow Engine (AWE / Approval Framework)
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PS_EOAW%' OR TABLE_NAME LIKE 'EOAW%'
    OR TABLE_NAME LIKE 'PS_APPR%' OR TABLE_NAME LIKE 'PS_EOWF%'
 ORDER BY TABLE_NAME;

-- Integration Broker: definitions (PSIB%, PSOPR*, PSSERVICE), runtime (PSAPMSG%)
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PSIB%' OR TABLE_NAME LIKE 'PSAPMSG%'
    OR TABLE_NAME LIKE 'PSSERVICE%' OR TABLE_NAME LIKE 'PSOPER%'
 ORDER BY TABLE_NAME;

-- Reporting engines: BI Publisher (PSXP%), nVision (PS_NVS%), Crystal (PSCR%)
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PSXP%' OR TABLE_NAME LIKE 'PS_NVS%'
    OR TABLE_NAME LIKE 'PSCR%'  OR TABLE_NAME LIKE 'PS_RPT%'
 ORDER BY TABLE_NAME;

-- Performance Monitor
SELECT TABLE_NAME FROM ALL_TABLES WHERE TABLE_NAME LIKE 'PSPM%' ORDER BY TABLE_NAME;

-- Commitment Control (FSCM) and Combo Edits — finance-critical, absent from v1
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PS_KK_%' OR TABLE_NAME LIKE 'PS_COMBO%'
 ORDER BY TABLE_NAME;

-- North American Payroll tax + earnings/deduction rule families — absent from v1
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PS_%TAX%TBL' OR TABLE_NAME LIKE 'PS_ERN%'
    OR TABLE_NAME LIKE 'PS_DED%'     OR TABLE_NAME LIKE 'PS_GARN%'
 ORDER BY TABLE_NAME;
-- SQL Server for all of the above: FROM INFORMATION_SCHEMA.TABLES,
--   column TABLE_NAME, add  AND TABLE_TYPE='BASE TABLE'.

-- ------------------------------------------------------------
-- 0.6 TABLESET CONTROL  ** new in v2 — the biggest v1 gap **
-- Pack 3 extracts every SETID-keyed setup table. Without these four
-- tables the extract is uninterpretable: you cannot tell which
-- business unit consumes which SETID for which record group.
-- ------------------------------------------------------------
SELECT RECNAME FROM PSRECDEFN
 WHERE RECNAME IN ('SET_CNTRL_TBL','SET_CNTRL_REC','SET_CNTRL_GROUP',
                   'REC_GROUP_TBL','REC_GROUP_REC','TBLSET_TBL','SETID_TBL');
SELECT COUNT(*) AS SET_CNTRL_REC_ROWS FROM PS_SET_CNTRL_REC;
SELECT COUNT(*) AS DISTINCT_SETIDS FROM PS_SETID_TBL;

-- ------------------------------------------------------------
-- 0.7 Telemetry availability — drives Pack 4 expectations
-- EXTRACT PSPRCSRQST FIRST. It is purged on a schedule and is the
-- single best evidence of what actually runs.
-- ------------------------------------------------------------
SELECT 'PSPRCSRQST' AS SRC, COUNT(*) AS CNT,
       MIN(RQSTDTTM) AS OLDEST, MAX(RQSTDTTM) AS NEWEST FROM PSPRCSRQST;
SELECT 'PSACCESSLOG', COUNT(*), MIN(LOGINDTTM), MAX(LOGINDTTM) FROM PSACCESSLOG;
-- Errors here => query stats logging is OFF. Note it, then enable prospectively.
SELECT 'PSQRYEXECLOG', COUNT(*), MIN(EXECDTTM), MAX(EXECDTTM) FROM PSQRYEXECLOG;
-- Errors here => Performance Monitor is OFF. Turn it on TODAY; 60 days of
-- page-level telemetry before design workshops beats any interview schedule.
SELECT 'PSPMTRANSHIST', COUNT(*) FROM PSPMTRANSHIST;
-- Purge policy for process history (tells you how much history you will keep):
SELECT * FROM PSPRCSSYSTEM;   -- includes retention/purge settings on most releases

-- ------------------------------------------------------------
-- 0.8 Navigation portals — drives the Pack 1 nav extract
-- ------------------------------------------------------------
SELECT PORTAL_NAME, COUNT(*) AS ITEMS FROM PSPRSMDEFN
 GROUP BY PORTAL_NAME ORDER BY 2 DESC;

-- ------------------------------------------------------------
-- 0.9 Custom-object naming convention detector  ** new in v2 **
-- v1 hardcoded 'UM%','Z%','X%'. Derive the real prefixes instead:
-- look at what non-Oracle operators actually created.
-- ------------------------------------------------------------
SELECT SUBSTR(RECNAME,1,2) AS PREFIX, COUNT(*) AS RECORDS
  FROM PSRECDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT',' ') AND LASTUPDOPRID IS NOT NULL
 GROUP BY SUBSTR(RECNAME,1,2)
HAVING COUNT(*) >= 5
 ORDER BY 2 DESC;
-- Feed the top prefixes into 05_pack5_customization.sql §5.4.
