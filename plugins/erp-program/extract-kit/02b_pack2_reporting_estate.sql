-- ============================================================
-- 02b_pack2_reporting_estate.sql  (KIT v2) — NEW PACK
-- The reporting estate beyond PS Query. Entirely absent from v1,
-- which is a serious gap for a finance-led programme: nVision IS
-- management reporting in PeopleSoft GL, and BI Publisher is where
-- most modern statutory and payroll output lives.
-- Sensitivity: LOW (definitions and layouts; no person data).
-- ============================================================

-- ------------------------------------------------------------
-- 2b.1 BI Publisher / XML Publisher
-- ------------------------------------------------------------
SELECT RECNAME FROM PSRECDEFN
 WHERE RECNAME IN ('PSXPDATASRC','PSXPTMPLDEFN','PSXPRPTDEFN','PSXPTMPLFILE',
                   'PSXPRPTSRCH','PSXPTMPLLANG','PSXPBURSTFLD','PSXPCTLANG');

SELECT * FROM PSXPRPTDEFN;      -- report definitions (the user-facing report)
SELECT * FROM PSXPDATASRC;      -- data sources (which query/AE/XMLDoc feeds it)
SELECT * FROM PSXPTMPLDEFN;     -- templates (RTF/XLS/PDF layouts)
SELECT * FROM PSXPBURSTFLD;     -- bursting fields — reveals distribution rules
-- PSXPTMPLFILE holds the binary template body. Do NOT CSV it — extract the
-- index only, and pull the layout files themselves from the BI Publisher
-- admin pages if the layouts are in scope.
SELECT TEMPLATE_ID, LANGUAGE_CD, EFFDT, FILE_NAME, VERSION
  FROM PSXPTMPLFILE ORDER BY TEMPLATE_ID, LANGUAGE_CD, EFFDT;

-- 2b.1b BIP report → data source → underlying query, joined
SELECT r.REPORT_DEFN_ID, r.REPORT_DESCR, r.DS_ID, r.DS_TYPE,
       d.DS_DESCR, d.DS_SQLOBJ, r.OBJECTOWNERID, r.LASTUPDOPRID, r.LASTUPDDTTM
  FROM PSXPRPTDEFN r
  LEFT JOIN PSXPDATASRC d ON d.DS_ID = r.DS_ID AND d.DS_TYPE = r.DS_TYPE
 ORDER BY r.REPORT_DEFN_ID;

-- ------------------------------------------------------------
-- 2b.2 nVision — GL management reporting. FINANCE CRITICAL.
-- nVision layouts are .xnv files on the report server; the DEFINITIONS
-- (scopes, ledger criteria, tree-based row/column sets) are in the DB.
-- ------------------------------------------------------------
SELECT RECNAME FROM PSRECDEFN
 WHERE RECNAME LIKE 'NVS_%' OR RECNAME LIKE 'RPT_%';

SELECT * FROM PS_NVS_REPORT;        -- report requests / definitions
SELECT * FROM PS_NVS_SCOPE;         -- scope definitions (the "run for every dept" driver)
SELECT * FROM PS_NVS_SCOPE_DTL;
SELECT * FROM PS_NVS_LAYOUT;        -- layout registry
SELECT * FROM PS_NVS_REPORT_TREE;   -- tree usage inside reports, where present
SELECT * FROM PS_RPT_DEFN;          -- report book / request definitions, where present
SELECT * FROM PS_RPT_DEFN_DTL;
-- Existence varies by release — run the guard above and extract what exists.

-- 2b.2b nVision dependency on trees — tells you which GL trees are
-- load-bearing for reporting and therefore must be reproduced in the
-- target ERP's hierarchy design.
SELECT DISTINCT TREE_NAME, SETID FROM PS_NVS_REPORT_TREE ORDER BY 1,2;

-- ------------------------------------------------------------
-- 2b.3 SQR — inventory lives on the FILESYSTEM, not the database
-- ------------------------------------------------------------
-- The DB knows which SQRs are *registered* as processes:
SELECT PRCSNAME, PRCSTYPE, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPRCSDEFN WHERE PRCSTYPE LIKE 'SQR%' ORDER BY PRCSNAME;
-- It does NOT know what the .sqr / .sqc source contains. Ask the App Admin for:
--   ls -lR $PS_HOME/sqr $PS_CUST_HOME/sqr  > <instance>_P2_SQR_FILELIST.txt
--   (name, bytes, mtime — that alone separates custom SQRs from delivered)
-- and a tarball of any SQR whose name matches your custom prefixes
-- (see 00_discovery §0.9). Register both in the manifest as pack 2b.

-- ------------------------------------------------------------
-- 2b.4 Crystal / legacy reporting, where still registered
-- ------------------------------------------------------------
SELECT PRCSNAME, PRCSTYPE, DESCR, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPRCSDEFN WHERE PRCSTYPE LIKE 'Crystal%' OR PRCSTYPE LIKE 'CRW%';

-- ------------------------------------------------------------
-- 2b.5 Report output distribution — WHO receives what
-- The distribution list is the true consumer list for the report
-- rationalisation exercise. Sensitivity: MODERATE (user IDs).
-- ------------------------------------------------------------
SELECT * FROM PS_PRCSDEFNGRP;       -- process → process group, where present
SELECT * FROM PSPRCSRQSTDIST;       -- request-level distribution (large; aggregate below)
SELECT DISTRIBUTE_TO, DISTTYPE, COUNT(*) AS DISTRIBUTIONS
  FROM PSPRCSRQSTDIST GROUP BY DISTRIBUTE_TO, DISTTYPE ORDER BY 3 DESC;

-- ------------------------------------------------------------
-- 2b.6 Reporting estate rollup — one row per engine
-- Paste this into the report rationalisation workbook.
-- ------------------------------------------------------------
SELECT 'PS_QUERY_PUBLIC'  AS ENGINE, COUNT(*) AS OBJECTS FROM PSQRYDEFN WHERE OPRID = ' '  UNION ALL
SELECT 'PS_QUERY_PRIVATE'       , COUNT(*) FROM PSQRYDEFN WHERE OPRID <> ' '                UNION ALL
SELECT 'BI_PUBLISHER'           , COUNT(*) FROM PSXPRPTDEFN                                  UNION ALL
SELECT 'SQR_REGISTERED'         , COUNT(*) FROM PSPRCSDEFN WHERE PRCSTYPE LIKE 'SQR%'        UNION ALL
SELECT 'NVISION_REGISTERED'     , COUNT(*) FROM PSPRCSDEFN WHERE PRCSTYPE LIKE 'nVision%'    UNION ALL
SELECT 'APP_ENGINE'             , COUNT(*) FROM PSAEAPPLDEFN                                 UNION ALL
SELECT 'COBOL_REGISTERED'       , COUNT(*) FROM PSPRCSDEFN WHERE PRCSTYPE LIKE 'COBOL%';
