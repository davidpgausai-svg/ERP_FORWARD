-- ============================================================
-- 05_pack5_customization.sql — WHAT YOU CHANGED (pillar-agnostic)
-- The one-WHERE-clause customization scanner: delivered objects carry
-- LASTUPDOPRID = 'PPLSOFT'; anything else was touched by your org.
-- Caveat: admin-applied patches can stamp non-PPLSOFT IDs — treat as a
-- first cut; the formal method is an App Designer compare vs DEMO.
-- Sensitivity: none (metadata only).
-- ============================================================

-- 5.1 Summary: customization counts by object type
SELECT 'RECORD' AS OBJTYPE, COUNT(*) AS CUSTOMIZED FROM PSRECDEFN    WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'PAGE'            , COUNT(*) FROM PSPNLDEFN    WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'COMPONENT'       , COUNT(*) FROM PSPNLGRPDEFN WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'MENU'            , COUNT(*) FROM PSMENUDEFN   WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'PEOPLECODE'      , COUNT(*) FROM PSPCMPROG    WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'SQL_OBJECT'      , COUNT(*) FROM PSSQLDEFN    WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'APP_ENGINE'      , COUNT(*) FROM PSAEAPPLDEFN WHERE LASTUPDOPRID <> 'PPLSOFT' UNION ALL
SELECT 'PROCESS_DEFN'    , COUNT(*) FROM PSPRCSDEFN   WHERE LASTUPDOPRID <> 'PPLSOFT';

-- 5.2 Detail: the customized-object inventory (one extract per type)
SELECT 'RECORD' AS OBJTYPE, RECNAME AS OBJNAME, RECDESCR AS DESCR,
       LASTUPDOPRID, LASTUPDDTTM
  FROM PSRECDEFN WHERE LASTUPDOPRID <> 'PPLSOFT';

SELECT 'PAGE', PNLNAME, ' ', LASTUPDOPRID, LASTUPDDTTM
  FROM PSPNLDEFN WHERE LASTUPDOPRID <> 'PPLSOFT';

SELECT 'COMPONENT', PNLGRPNAME, ' ', LASTUPDOPRID, LASTUPDDTTM
  FROM PSPNLGRPDEFN WHERE LASTUPDOPRID <> 'PPLSOFT';

SELECT 'PEOPLECODE', OBJECTVALUE1 || ':' || OBJECTVALUE2 || ':' || OBJECTVALUE3,
       ' ', LASTUPDOPRID, LASTUPDDTTM
  FROM PSPCMPROG WHERE LASTUPDOPRID <> 'PPLSOFT';

SELECT 'APP_ENGINE', AE_APPLID, ' ', LASTUPDOPRID, LASTUPDDTTM
  FROM PSAEAPPLDEFN WHERE LASTUPDOPRID <> 'PPLSOFT';

-- 5.3 Custom-built (not just modified) objects — common site convention
-- is names starting with the institution's prefix (e.g., 'UM', 'Z', 'X').
-- Adjust the patterns to your naming standard:
SELECT RECNAME, RECDESCR, LASTUPDOPRID, LASTUPDDTTM
  FROM PSRECDEFN
 WHERE RECNAME LIKE 'UM%' OR RECNAME LIKE 'Z%' OR RECNAME LIKE 'X%';

-- 5.4 Queries — user-authored by definition; inventory public vs private
SELECT QRYNAME, OPRID, QRYTYPE,
       CASE WHEN OPRID = ' ' THEN 'PUBLIC' ELSE 'PRIVATE' END AS VISIBILITY,
       LASTUPDDTTM
  FROM PSQRYDEFN;

-- 5.5 Migration history — every project ever migrated (your change log)
SELECT * FROM PSPROJECTDEFN;
SELECT * FROM PSPROJECTITEM;

-- 5.6 Formal method (not SQL — note for the App Admin):
-- App Designer -> Tools -> Compare and Report against the delivered DEMO
-- database, by object type. Produces the authoritative delivered-vs-
-- modified report. Run after this first-cut sweep identifies hot areas.
