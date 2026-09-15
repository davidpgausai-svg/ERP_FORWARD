-- ============================================================
-- 06_manifest_and_qa.sql  (KIT v2) — NEW PACK
-- Manifest generation, row-count reconciliation, and pre-landing QA.
--
-- v1 shipped a manifest template with one example row, a written
-- instruction to "complete it", and no way to verify it. In practice
-- that means an intake team cannot tell a truncated extract from a
-- small table, and nobody notices until an analysis is already wrong.
-- This pack makes the manifest machine-generated and checkable.
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 RUN HEADER — one row, first thing, into every extract run
-- Land as <instance>_P0_RUN_HEADER.csv
-- ------------------------------------------------------------
SELECT SYS_CONTEXT('USERENV','DB_NAME')  AS INSTANCE_DB,
       (SELECT TOOLSREL FROM PSSTATUS)   AS TOOLS_RELEASE,
       (SELECT MAX(RELEASELABEL) FROM PSRELEASE) AS APP_RELEASE,
       (SELECT LASTREFRESHDTTM FROM PSSTATUS)    AS LAST_REFRESH,
       USER                              AS EXTRACTED_BY_SCHEMA,
       SYSDATE                           AS EXTRACT_RUN_AT
  FROM DUAL;
-- SQL Server:
--   SELECT DB_NAME(), (SELECT TOOLSREL FROM PSSTATUS),
--          (SELECT MAX(RELEASELABEL) FROM PSRELEASE),
--          (SELECT LASTREFRESHDTTM FROM PSSTATUS), SUSER_SNAME(), GETDATE();

-- ------------------------------------------------------------
-- 6.2 EXPECTED ROW COUNTS — generate before extracting
-- Run this, land the result as <instance>_P0_EXPECTED_COUNTS.csv, and
-- have the intake job compare it against the actual CSV line counts.
-- Any file whose actual count differs from expected by more than the
-- extract window's own churn is a failed extract, not a small table.
-- ------------------------------------------------------------
SELECT 'PSRECDEFN'    AS SOURCE_OBJECT, 1 AS PACK, COUNT(*) AS EXPECTED_ROWS FROM PSRECDEFN    UNION ALL
SELECT 'PSRECFIELD'        , 1, COUNT(*) FROM PSRECFIELD      UNION ALL
SELECT 'PSRECFIELDDB'      , 1, COUNT(*) FROM PSRECFIELDDB    UNION ALL
SELECT 'PSDBFIELD'         , 1, COUNT(*) FROM PSDBFIELD       UNION ALL
SELECT 'PSDBFLDLABL'       , 1, COUNT(*) FROM PSDBFLDLABL     UNION ALL
SELECT 'PSPNLDEFN'         , 1, COUNT(*) FROM PSPNLDEFN       UNION ALL
SELECT 'PSPNLFIELD'        , 1, COUNT(*) FROM PSPNLFIELD      UNION ALL
SELECT 'PSPNLGRPDEFN'      , 1, COUNT(*) FROM PSPNLGRPDEFN    UNION ALL
SELECT 'PSPNLGROUP'        , 1, COUNT(*) FROM PSPNLGROUP      UNION ALL
SELECT 'PSMENUDEFN'        , 1, COUNT(*) FROM PSMENUDEFN      UNION ALL
SELECT 'PSMENUITEM'        , 1, COUNT(*) FROM PSMENUITEM      UNION ALL
SELECT 'PSPRSMDEFN'        , 1, COUNT(*) FROM PSPRSMDEFN      UNION ALL
SELECT 'PSXLATITEM'        , 1, COUNT(*) FROM PSXLATITEM      UNION ALL
SELECT 'PSPCMPROG'         , 2, COUNT(*) FROM PSPCMPROG       UNION ALL
SELECT 'PSSQLDEFN'         , 2, COUNT(*) FROM PSSQLDEFN       UNION ALL
SELECT 'PSSQLTEXTDEFN'     , 2, COUNT(*) FROM PSSQLTEXTDEFN   UNION ALL
SELECT 'PSAEAPPLDEFN'      , 2, COUNT(*) FROM PSAEAPPLDEFN    UNION ALL
SELECT 'PSAESECTDEFN'      , 2, COUNT(*) FROM PSAESECTDEFN    UNION ALL
SELECT 'PSAESTEPDEFN'      , 2, COUNT(*) FROM PSAESTEPDEFN    UNION ALL
SELECT 'PSAESTMTDEFN'      , 2, COUNT(*) FROM PSAESTMTDEFN    UNION ALL
SELECT 'PSPRCSDEFN'        , 2, COUNT(*) FROM PSPRCSDEFN      UNION ALL
SELECT 'PSJOBDEFN'         , 2, COUNT(*) FROM PSJOBDEFN       UNION ALL
SELECT 'PSPRCSJOBITEM'     , 2, COUNT(*) FROM PSPRCSJOBITEM   UNION ALL
SELECT 'PSRECURDEFN'       , 2, COUNT(*) FROM PSRECURDEFN     UNION ALL
SELECT 'PSQRYDEFN'         , 2, COUNT(*) FROM PSQRYDEFN       UNION ALL
SELECT 'PSQRYRECORD'       , 2, COUNT(*) FROM PSQRYRECORD     UNION ALL
SELECT 'PSQRYFIELD'        , 2, COUNT(*) FROM PSQRYFIELD      UNION ALL
SELECT 'PSQRYCRITERIA'     , 2, COUNT(*) FROM PSQRYCRITERIA   UNION ALL
SELECT 'PSNODEDEFN'        , 2, COUNT(*) FROM PSNODEDEFN      UNION ALL
SELECT 'PSOPERATION'       , 2, COUNT(*) FROM PSOPERATION     UNION ALL
SELECT 'PSMSGDEFN'         , 2, COUNT(*) FROM PSMSGDEFN       UNION ALL
SELECT 'PSROLEDEFN'        , 3, COUNT(*) FROM PSROLEDEFN      UNION ALL
SELECT 'PSCLASSDEFN'       , 3, COUNT(*) FROM PSCLASSDEFN     UNION ALL
SELECT 'PSAUTHITEM'        , 3, COUNT(*) FROM PSAUTHITEM      UNION ALL
SELECT 'PSROLECLASS'       , 3, COUNT(*) FROM PSROLECLASS     UNION ALL
SELECT 'PSROLEUSER'        , 3, COUNT(*) FROM PSROLEUSER      UNION ALL
SELECT 'PSOPRDEFN'         , 3, COUNT(*) FROM PSOPRDEFN       UNION ALL
SELECT 'PSTREEDEFN'        , 3, COUNT(*) FROM PSTREEDEFN      UNION ALL
SELECT 'PSTREENODE'        , 3, COUNT(*) FROM PSTREENODE      UNION ALL
SELECT 'PSTREELEAF'        , 3, COUNT(*) FROM PSTREELEAF      UNION ALL
SELECT 'PSPRCSRQST'        , 4, COUNT(*) FROM PSPRCSRQST      UNION ALL
SELECT 'PSACCESSLOG'       , 4, COUNT(*) FROM PSACCESSLOG     UNION ALL
SELECT 'PSPROJECTDEFN'     , 5, COUNT(*) FROM PSPROJECTDEFN   UNION ALL
SELECT 'PSPROJECTITEM'     , 5, COUNT(*) FROM PSPROJECTITEM;
-- Add the Pack 3 setup tables from the generator's own count output
-- (03 §3.7) — that list is instance-specific by design.

-- ------------------------------------------------------------
-- 6.3 MANIFEST ROW GENERATOR — emits ready-to-paste manifest lines
-- for every Pack 3 setup table the generator selected. Saves the
-- hand-typing that made v1's manifest a formality rather than a control.
-- ------------------------------------------------------------
SELECT '<INSTANCE>_P3_' || d.RECNAME || '.csv|<INSTANCE>|3|' ||
       d.RECNAME || '||' || TO_CHAR(SYSDATE,'YYYY-MM-DD') ||
       '|<EXTRACTED_BY>|owner=' || d.OBJECTOWNERID AS MANIFEST_ROW
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND (EXISTS (SELECT 1 FROM PSRECFIELDDB f
                 WHERE f.RECNAME = d.RECNAME
                   AND f.FIELDNAME IN ('SETID','BUSINESS_UNIT')
                   AND BITAND(f.USEEDIT,1) = 1)
     OR EXISTS (SELECT 1 FROM PSRECFIELD p WHERE p.EDITTABLE = d.RECNAME))
   AND NOT EXISTS (SELECT 1 FROM PSRECFIELDDB x
                    WHERE x.RECNAME = d.RECNAME
                      AND x.FIELDNAME IN ('EMPLID','NATIONAL_ID','VENDOR_ID',
                                          'CUST_ID','STDNT_CAR_NBR'))
 ORDER BY d.RECNAME;

-- ------------------------------------------------------------
-- 6.4 SENSITIVITY CLASSIFICATION — machine-assigned, per file
-- Every landed file must carry a classification. v1 had a sensitivity
-- table in the README and no per-file stamp, which puts the burden on
-- whoever happens to open the file next.
-- ------------------------------------------------------------
SELECT SOURCE_OBJECT, PACK,
       CASE PACK
         WHEN 1 THEN 'PUBLIC_INTERNAL'      -- structural metadata only
         WHEN 2 THEN 'INTERNAL'             -- business logic
         WHEN 3 THEN 'INTERNAL'             -- configuration
         WHEN 4 THEN 'INTERNAL_RESTRICTED'  -- includes user IDs
         WHEN 5 THEN 'PUBLIC_INTERNAL'
         ELSE 'INTERNAL' END AS CLASSIFICATION,
       CASE WHEN SOURCE_OBJECT IN ('PSOPRDEFN','PSROLEUSER','PSACCESSLOG',
                                   'PSPRCSRQST','PSQRYEXECLOG','PSOPRALIAS',
                                   'PS_EOAW_USER_LIST','PS_EODL_REQUEST')
            THEN 'Y' ELSE 'N' END AS CONTAINS_USER_IDS
  FROM (SELECT 'PSOPRDEFN' AS SOURCE_OBJECT, 3 AS PACK FROM DUAL
        UNION ALL SELECT 'PSROLEUSER', 3 FROM DUAL
        UNION ALL SELECT 'PSACCESSLOG', 4 FROM DUAL
        UNION ALL SELECT 'PSPRCSRQST', 4 FROM DUAL
        UNION ALL SELECT 'PSRECDEFN', 1 FROM DUAL);
-- Extend the inline list, or drive it from 6.2's output, as suits your
-- intake tooling. The point is that classification travels with the file.

-- ------------------------------------------------------------
-- 6.5 PRE-LANDING CHECKS — run and record answers before upload
-- ------------------------------------------------------------
-- (a) Did any extracted setup table sneak in a person key? Must be empty.
SELECT d.RECNAME, f.FIELDNAME
  FROM PSRECDEFN d
  JOIN PSRECFIELDDB f ON f.RECNAME = d.RECNAME
 WHERE d.RECTYPE = 0
   AND f.FIELDNAME IN ('EMPLID','NATIONAL_ID','SSN','BIRTHDATE',
                       'BANK_ACCOUNT_NUM','CREDIT_CARD_NBR')
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB k
                WHERE k.RECNAME = d.RECNAME
                  AND k.FIELDNAME IN ('SETID','BUSINESS_UNIT')
                  AND BITAND(k.USEEDIT,1) = 1)
 ORDER BY d.RECNAME;

-- (b) Any URL definitions carrying embedded credentials? Redact first.
SELECT URL_ID, URL_DESCR FROM PSURLDEFN
 WHERE UPPER(URLSTRING) LIKE '%PASSWORD%'
    OR UPPER(URLSTRING) LIKE '%PWD=%'
    OR URLSTRING LIKE '%:%@%';

-- (c) Confirm no password or token columns are in any extract list
SELECT RECNAME, FIELDNAME FROM PSRECFIELDDB
 WHERE FIELDNAME IN ('OPERPSWD','ENCRYPTED','PTOPRPSWDCTL','ACCESSID',
                     'ACCESSPSWD','SYMBOLICID','TOKEN','PSTOKEN')
 ORDER BY RECNAME;

-- ------------------------------------------------------------
-- 6.6 EXTRACT COMPLETENESS SCORECARD
-- Run at the end. Land as <instance>_P0_COMPLETENESS.csv and put it in
-- front of the programme every time the extract is refreshed.
-- ------------------------------------------------------------
SELECT 'Structure (P1)'          AS AREA, 'PSRECDEFN present'        AS CHECK_ITEM,
       CASE WHEN (SELECT COUNT(*) FROM PSRECDEFN) > 0 THEN 'PASS' ELSE 'FAIL' END AS RESULT FROM DUAL
UNION ALL
SELECT 'Lineage (P1)', 'EDITTABLE relationships found',
       CASE WHEN (SELECT COUNT(*) FROM PSRECFIELD WHERE EDITTABLE <> ' ') > 0
            THEN 'PASS' ELSE 'FAIL — PSRECFIELD not extracted' END FROM DUAL
UNION ALL
SELECT 'Tableset (P3)', 'SET_CNTRL_REC populated',
       CASE WHEN (SELECT COUNT(*) FROM PS_SET_CNTRL_REC) > 0
            THEN 'PASS' ELSE 'FAIL — SETID data uninterpretable' END FROM DUAL
UNION ALL
SELECT 'Approvals (P2C)', 'AWE transactions registered',
       CASE WHEN (SELECT COUNT(*) FROM PS_EOAW_TXN) > 0
            THEN 'PASS' ELSE 'CHECK — AWE may not be in use' END FROM DUAL
UNION ALL
SELECT 'Integration (P2D)', 'Service operations defined',
       CASE WHEN (SELECT COUNT(*) FROM PSOPERATION) > 0
            THEN 'PASS' ELSE 'CHECK — IB may not be in use' END FROM DUAL
UNION ALL
SELECT 'Usage (P4)', 'Process history retained',
       CASE WHEN (SELECT COUNT(*) FROM PSPRCSRQST) > 1000
            THEN 'PASS' ELSE 'FAIL — history purged, extend retention now' END FROM DUAL
UNION ALL
SELECT 'Usage (P4)', 'Query execution logging enabled',
       CASE WHEN (SELECT COUNT(*) FROM PSQRYEXECLOG) > 0
            THEN 'PASS' ELSE 'FAIL — enable prospectively' END FROM DUAL
UNION ALL
SELECT 'Usage (P4)', 'Performance Monitor enabled',
       CASE WHEN (SELECT COUNT(*) FROM PSPMTRANSHIST) > 0
            THEN 'PASS' ELSE 'FAIL — enable today; cannot be backfilled' END FROM DUAL
UNION ALL
SELECT 'Customization (P5)', 'App Designer compare obtained',
       'MANUAL — confirm with App Admin' FROM DUAL;
-- Wrap any branch whose table may not exist in your own error handling;
-- on Oracle a missing table raises ORA-00942 and stops the script.
