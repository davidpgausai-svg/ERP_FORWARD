-- ============================================================
-- 00_discovery.sql — run FIRST against each instance (HCM, FSCM, CS)
-- Pure SELECTs. Identifies the landscape and validates the kit's
-- assumptions before any bulk extraction.
-- ============================================================

-- 0.1 Tools release and database identity
SELECT * FROM PSSTATUS;                       -- TOOLSREL = PeopleTools version
SELECT * FROM PSRELEASE ORDER BY RELEASEDTTM; -- application release history

-- 0.2 Size of the metadata estate (sets expectations for Pack 1/2)
SELECT 'PSRECDEFN'   AS OBJ, COUNT(*) AS CNT FROM PSRECDEFN   UNION ALL
SELECT 'PSPNLDEFN'          , COUNT(*)        FROM PSPNLDEFN   UNION ALL
SELECT 'PSPNLGRPDEFN'       , COUNT(*)        FROM PSPNLGRPDEFN UNION ALL
SELECT 'PSMENUDEFN'         , COUNT(*)        FROM PSMENUDEFN  UNION ALL
SELECT 'PSPCMPROG'          , COUNT(*)        FROM PSPCMPROG   UNION ALL
SELECT 'PSSQLDEFN'          , COUNT(*)        FROM PSSQLDEFN   UNION ALL
SELECT 'PSAEAPPLDEFN'       , COUNT(*)        FROM PSAEAPPLDEFN UNION ALL
SELECT 'PSQRYDEFN'          , COUNT(*)        FROM PSQRYDEFN   UNION ALL
SELECT 'PSPRCSDEFN'         , COUNT(*)        FROM PSPRCSDEFN  UNION ALL
SELECT 'PSPRSMDEFN'         , COUNT(*)        FROM PSPRSMDEFN  UNION ALL
SELECT 'PSTREEDEFN'         , COUNT(*)        FROM PSTREEDEFN  UNION ALL
SELECT 'PSROLEDEFN'         , COUNT(*)        FROM PSROLEDEFN  UNION ALL
SELECT 'PSOPRDEFN'          , COUNT(*)        FROM PSOPRDEFN;

-- 0.3 Discover version-variable table families (names differ by
-- release; export whatever exists). Oracle: ALL_TABLES / user schema.
-- SQL Server: use INFORMATION_SCHEMA.TABLES.
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PS_EOAW%'    -- Approval Workflow Engine family
    OR TABLE_NAME LIKE 'EOAW%'
 ORDER BY TABLE_NAME;

SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PSAPMSG%'    -- Integration Broker runtime/monitor
    OR TABLE_NAME LIKE 'PSIB%'       -- IB definitions
 ORDER BY TABLE_NAME;

SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PSPM%'       -- Performance Monitor (if enabled)
 ORDER BY TABLE_NAME;

-- 0.4 Telemetry availability check (drives Pack 4 expectations)
SELECT 'PSPRCSRQST rows' AS CHECK_ITEM, COUNT(*) AS CNT FROM PSPRCSRQST;
SELECT MIN(RQSTDTTM) AS OLDEST, MAX(RQSTDTTM) AS NEWEST FROM PSPRCSRQST;  -- how far back history goes (purge check!)
SELECT 'PSACCESSLOG rows', COUNT(*) FROM PSACCESSLOG;
-- If the next one errors, query stats logging is not enabled — note it and enable prospectively:
SELECT 'PSQRYEXECLOG rows', COUNT(*) FROM PSQRYEXECLOG;

-- 0.5 Which portals/navigation trees exist (drives Pack 1 nav extract)
SELECT PORTAL_NAME, COUNT(*) AS ITEMS FROM PSPRSMDEFN GROUP BY PORTAL_NAME ORDER BY 2 DESC;
