-- ============================================================
-- 05_pack5_customization.sql  (KIT v2) — WHAT YOU CHANGED
-- Sensitivity: NONE (metadata only).
--
-- v2 changes vs v1:
--   + LASTUPDOPRID <> 'PPLSOFT' corrected. On real instances that
--     predicate silently drops rows where LASTUPDOPRID is blank or NULL
--     (Oracle: NULL <> 'PPLSOFT' is UNKNOWN, so the row is excluded).
--     v2 uses NOT IN ('PPLSOFT',' ') with an explicit NULL branch and
--     reports the blank/NULL population separately rather than hiding it.
--   + CUSTOM FIELDS ON DELIVERED RECORDS — the commonest and sneakiest
--     customization type, and completely absent from v1. A delivered
--     record with three site-added columns still reports
--     LASTUPDOPRID='PPLSOFT' at record level on some releases, and every
--     one of those columns is a hidden requirement.
--   + custom prefixes derived from data (00_discovery §0.9), not guessed
--   + modification recency and clustering, so you can tell a live
--     customization estate from a fossil one
--   + patch-noise control: exclude operator IDs that stamp bulk updates
--   + project history joined to object type
-- ============================================================

-- ------------------------------------------------------------
-- 5.0 Patch-noise control — identify bulk-stamping operator IDs first
-- An admin who applied a maintenance pack can stamp tens of thousands
-- of delivered objects with their own OPRID. Without this step the
-- customization count is inflated by an order of magnitude and the
-- whole pack loses credibility with the technical team.
-- ------------------------------------------------------------
SELECT LASTUPDOPRID, COUNT(*) AS OBJECTS,
       MIN(LASTUPDDTTM) AS FIRST_TOUCH, MAX(LASTUPDDTTM) AS LAST_TOUCH,
       COUNT(DISTINCT TRUNC(LASTUPDDTTM)) AS DISTINCT_DAYS
  FROM PSRECDEFN GROUP BY LASTUPDOPRID
 ORDER BY OBJECTS DESC;
-- An OPRID with tens of thousands of objects touched across one or two
-- days is a patch application, not a customization programme. Add those
-- IDs to the PATCH_OPRIDS list used below and re-run.
-- Suggested working list (edit for your site):
--   PATCH_OPRIDS = ('PPLSOFT',' ','PS','SYSADM','CONVERT','UPGRADE')

-- ------------------------------------------------------------
-- 5.1 Summary — customization counts by object type
-- ------------------------------------------------------------
SELECT 'RECORD' AS OBJTYPE,
       COUNT(*) AS TOTAL,
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END) AS BLANK_OPRID,
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END) AS CUSTOMISED
  FROM PSRECDEFN
UNION ALL
SELECT 'PAGE', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSPNLDEFN
UNION ALL
SELECT 'COMPONENT', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSPNLGRPDEFN
UNION ALL
SELECT 'MENU', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSMENUDEFN
UNION ALL
SELECT 'PEOPLECODE', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSPCMPROG
UNION ALL
SELECT 'SQL_OBJECT', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSSQLDEFN
UNION ALL
SELECT 'APP_ENGINE', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSAEAPPLDEFN
UNION ALL
SELECT 'PROCESS_DEFN', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSPRCSDEFN
UNION ALL
SELECT 'FIELD', COUNT(*),
       SUM(CASE WHEN LASTUPDOPRID IS NULL OR LASTUPDOPRID = ' ' THEN 1 ELSE 0 END),
       SUM(CASE WHEN LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
                 AND LASTUPDOPRID IS NOT NULL THEN 1 ELSE 0 END)
  FROM PSDBFIELD;

-- ------------------------------------------------------------
-- 5.2 Detail — the customised-object inventory, one row per object
-- ------------------------------------------------------------
SELECT 'RECORD' AS OBJTYPE, RECNAME AS OBJNAME, RECDESCR AS DESCR,
       OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSRECDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

SELECT 'PAGE', PNLNAME, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPNLDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

SELECT 'COMPONENT', PNLGRPNAME, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPNLGRPDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

SELECT 'PEOPLECODE',
       OBJECTVALUE1 || ':' || OBJECTVALUE2 || ':' || OBJECTVALUE3 || ':' || OBJECTVALUE4,
       ' ', ' ', LASTUPDOPRID, LASTUPDDTTM
  FROM PSPCMPROG
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

SELECT 'APP_ENGINE', AE_APPLID, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSAEAPPLDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

SELECT 'SQL_OBJECT', SQLID, ' ', ' ', LASTUPDOPRID, LASTUPDDTTM
  FROM PSSQLDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

SELECT 'PROCESS_DEFN', PRCSNAME || ':' || PRCSTYPE, DESCR,
       OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPRCSDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL;

-- ------------------------------------------------------------
-- 5.3 CUSTOM FIELDS ON DELIVERED RECORDS  ** new in v2 **
-- The most-missed customization type. A site-added column on a
-- delivered table is a business requirement that exists nowhere in
-- documentation, carries live data, and will not appear in any
-- record-level customization count.
-- ------------------------------------------------------------
SELECT d.RECNAME, d.RECDESCR, d.OBJECTOWNERID,
       f.FIELDNAME AS CUSTOM_FIELD,
       b.FIELDTYPE, b.LENGTH, b.LASTUPDOPRID AS FIELD_CREATED_BY,
       b.LASTUPDDTTM AS FIELD_CREATED_ON
  FROM PSRECDEFN   d
  JOIN PSRECFIELD  f ON f.RECNAME = d.RECNAME
  JOIN PSDBFIELD   b ON b.FIELDNAME = f.FIELDNAME
 WHERE d.RECTYPE = 0
   AND b.LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ')
   AND b.LASTUPDOPRID IS NOT NULL
 ORDER BY d.OBJECTOWNERID, d.RECNAME, f.FIELDNAME;

-- 5.3b Same thing by naming convention, for releases where the
-- LASTUPDOPRID stamp on PSDBFIELD is unreliable. Replace the prefixes
-- with the ones 00_discovery §0.9 actually found at your site.
SELECT d.RECNAME, d.RECDESCR, f.FIELDNAME AS CUSTOM_FIELD, d.OBJECTOWNERID
  FROM PSRECDEFN  d
  JOIN PSRECFIELD f ON f.RECNAME = d.RECNAME
 WHERE d.RECTYPE = 0
   AND (f.FIELDNAME LIKE 'UM%' OR f.FIELDNAME LIKE 'Z%' OR f.FIELDNAME LIKE 'X%')
 ORDER BY d.RECNAME, f.FIELDNAME;

-- 5.3c Which custom fields carry data — the ones that matter.
-- Generates a count statement per custom field; run the output.
SELECT 'SELECT ''' || d.RECNAME || '.' || f.FIELDNAME || ''' AS OBJ, COUNT(*) AS POPULATED FROM ' ||
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END ||
       ' WHERE ' || f.FIELDNAME || ' IS NOT NULL AND ' || f.FIELDNAME || ' <> '' '' UNION ALL'
       AS COUNT_STMT
  FROM PSRECDEFN  d
  JOIN PSRECFIELD f ON f.RECNAME = d.RECNAME
 WHERE d.RECTYPE = 0
   AND (f.FIELDNAME LIKE 'UM%' OR f.FIELDNAME LIKE 'Z%' OR f.FIELDNAME LIKE 'X%');
-- A custom field that is 100% empty is a decommission candidate.
-- A custom field that is 100% populated is a target-ERP requirement.

-- ------------------------------------------------------------
-- 5.4 Custom-BUILT objects (not merely modified)
-- Prefixes come from 00_discovery §0.9 — do not guess.
-- ------------------------------------------------------------
SELECT 'RECORD' AS OBJTYPE, RECNAME AS OBJNAME, RECDESCR, OBJECTOWNERID,
       LASTUPDOPRID, LASTUPDDTTM
  FROM PSRECDEFN
 WHERE RECNAME LIKE 'UM%' OR RECNAME LIKE 'Z%' OR RECNAME LIKE 'X%'
UNION ALL
SELECT 'PAGE', PNLNAME, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPNLDEFN
 WHERE PNLNAME LIKE 'UM%' OR PNLNAME LIKE 'Z%' OR PNLNAME LIKE 'X%'
UNION ALL
SELECT 'COMPONENT', PNLGRPNAME, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPNLGRPDEFN
 WHERE PNLGRPNAME LIKE 'UM%' OR PNLGRPNAME LIKE 'Z%' OR PNLGRPNAME LIKE 'X%'
UNION ALL
SELECT 'APP_ENGINE', AE_APPLID, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSAEAPPLDEFN
 WHERE AE_APPLID LIKE 'UM%' OR AE_APPLID LIKE 'Z%' OR AE_APPLID LIKE 'X%'
UNION ALL
SELECT 'PROCESS', PRCSNAME, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPRCSDEFN
 WHERE PRCSNAME LIKE 'UM%' OR PRCSNAME LIKE 'Z%' OR PRCSNAME LIKE 'X%';

-- ------------------------------------------------------------
-- 5.5 MODIFICATION RECENCY  ** new in v2 **
-- Is this a living customization estate or a fossil? The answer changes
-- the migration strategy: a fossil estate can often be dropped wholesale;
-- a living one means active business demand the target ERP must absorb.
-- ------------------------------------------------------------
SELECT TO_CHAR(LASTUPDDTTM,'YYYY') AS MOD_YEAR, COUNT(*) AS OBJECTS_TOUCHED
  FROM PSRECDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL
 GROUP BY TO_CHAR(LASTUPDDTTM,'YYYY') ORDER BY 1 DESC;

-- 5.5b Where the customizations cluster, by owning module — tells you
-- which pillar's design workshops need the most legacy-requirements time
SELECT OBJECTOWNERID, COUNT(*) AS CUSTOMISED_RECORDS
  FROM PSRECDEFN
 WHERE LASTUPDOPRID NOT IN ('PPLSOFT','PS','SYSADM',' ') AND LASTUPDOPRID IS NOT NULL
 GROUP BY OBJECTOWNERID ORDER BY 2 DESC;

-- ------------------------------------------------------------
-- 5.6 Queries — user-authored by definition
-- ------------------------------------------------------------
SELECT QRYNAME, OPRID, QRYTYPE,
       CASE WHEN OPRID = ' ' THEN 'PUBLIC' ELSE 'PRIVATE' END AS VISIBILITY,
       LASTUPDDTTM
  FROM PSQRYDEFN ORDER BY VISIBILITY, QRYNAME;

-- ------------------------------------------------------------
-- 5.7 Migration history — the change log
-- ------------------------------------------------------------
SELECT * FROM PSPROJECTDEFN;
SELECT * FROM PSPROJECTITEM;

-- 5.7b Project activity over time — the delivery cadence of the
-- customization estate, and who has been doing the work
SELECT TO_CHAR(p.LASTUPDDTTM,'YYYY') AS PROJECT_YEAR,
       COUNT(DISTINCT p.PROJECTNAME) AS PROJECTS,
       COUNT(i.PROJECTNAME) AS OBJECTS_MIGRATED
  FROM PSPROJECTDEFN p
  LEFT JOIN PSPROJECTITEM i ON i.PROJECTNAME = p.PROJECTNAME
 GROUP BY TO_CHAR(p.LASTUPDDTTM,'YYYY') ORDER BY 1 DESC;

-- ------------------------------------------------------------
-- 5.8 Formal method — not SQL, and still required
-- App Designer → Tools → Compare and Report, against the delivered DEMO
-- database, by object type. That is the authoritative delivered-vs-
-- modified report. Everything in this file is a first cut whose purpose
-- is to tell the technical team WHERE to point the compare.
--
-- Ask the App Admin for the compare report output as CSV/XLSX and land
-- it in the same Databricks location as pack 5, named
-- <instance>_P5_APPDESIGNER_COMPARE.csv. Without it, every count in
-- this pack should be described as indicative, not authoritative.
-- ------------------------------------------------------------
