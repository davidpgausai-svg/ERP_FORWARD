-- ============================================================
-- 01_pack1_structure.sql  (KIT v2) — WHAT THE SYSTEM IS
-- Pillar-agnostic. Sensitivity: NONE (no business data).
-- Export each result set to <instance>_P1_<object>.csv
--
-- v2 changes vs v1:
--   + PSRECFIELD added — v1 took only PSRECFIELDDB and therefore lost
--     EDITTABLE (prompt table) and DEFRECNAME. EDITTABLE is the field-to-
--     reference-table linkage: it IS the data-lineage graph and the basis
--     of the improved Pack 3 setup detection. Largest single omission in P1.
--   + derived FK/lineage edge list
--   + subrecord expansion map (PSRECDEFN RECTYPE=3)
--   + PSPNLFIELD volume-split guidance
--   + PSXLATITEM full history, not just EFF_STATUS='A'
--   + related-language and effective-dating profile
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Records (tables/views) — the object catalogue
-- RECTYPE: 0=SQL table 1=SQL view 2=derived/work 3=subrecord
--          5=dynamic view 6=query view 7=temporary table
-- ------------------------------------------------------------
SELECT * FROM PSRECDEFN;

-- Readable summary of the estate by owning product and record type
SELECT OBJECTOWNERID, RECTYPE, COUNT(*) AS CNT
  FROM PSRECDEFN GROUP BY OBJECTOWNERID, RECTYPE
 ORDER BY OBJECTOWNERID, RECTYPE;

-- ------------------------------------------------------------
-- 1.2 Fields — BOTH tables. They are not interchangeable.
--   PSRECFIELD   = as-designed, incl. subrecord references, EDITTABLE,
--                  DEFRECNAME, field ordering, audit flags.
--   PSRECFIELDDB = subrecords expanded to physical columns.
-- ------------------------------------------------------------
SELECT * FROM PSRECFIELD;        -- ** was missing from v1 **
SELECT * FROM PSRECFIELDDB;
SELECT * FROM PSDBFIELD;         -- field-level types, lengths, formats
SELECT * FROM PSDBFLDLABL;       -- long/short labels — makes extracts readable

-- 1.2b Key-field map (which columns key which table) — Oracle BITAND
SELECT f.RECNAME, f.FIELDNAME, f.FIELDNUM,
       CASE WHEN BITAND(f.USEEDIT,1)     = 1 THEN 'Y' ELSE 'N' END AS IS_KEY,
       CASE WHEN BITAND(f.USEEDIT,2)     = 2 THEN 'Y' ELSE 'N' END AS IS_DUPKEY,
       CASE WHEN BITAND(f.USEEDIT,4)     = 4 THEN 'Y' ELSE 'N' END AS IS_ALTSRCH,
       CASE WHEN BITAND(f.USEEDIT,16)    = 16 THEN 'Y' ELSE 'N' END AS IS_REQUIRED,
       CASE WHEN BITAND(f.USEEDIT,256)   = 256 THEN 'Y' ELSE 'N' END AS IS_DESCENDING,
       CASE WHEN BITAND(f.USEEDIT,1024)  = 1024 THEN 'Y' ELSE 'N' END AS AUDIT_ADD,
       CASE WHEN BITAND(f.USEEDIT,2048)  = 2048 THEN 'Y' ELSE 'N' END AS AUDIT_CHG,
       CASE WHEN BITAND(f.USEEDIT,4096)  = 4096 THEN 'Y' ELSE 'N' END AS AUDIT_DEL
  FROM PSRECFIELDDB f
 ORDER BY f.RECNAME, f.FIELDNUM;
-- SQL Server: replace BITAND(f.USEEDIT,n) = n  with  (f.USEEDIT & n) = n

-- ------------------------------------------------------------
-- 1.3 LINEAGE EDGE LIST  ** new in v2 **
-- Every field whose values are validated against another record.
-- This is the closest thing PeopleSoft has to a foreign-key graph and
-- it is what lets Databricks join the extract into a model instead of
-- 40,000 unrelated CSVs.
-- ------------------------------------------------------------
SELECT f.RECNAME        AS CHILD_RECORD,
       f.FIELDNAME      AS CHILD_FIELD,
       f.EDITTABLE      AS PARENT_RECORD,
       d.RECDESCR       AS PARENT_DESCR,
       d.RECTYPE        AS PARENT_RECTYPE,
       d.OBJECTOWNERID  AS PARENT_OWNER
  FROM PSRECFIELD f
  LEFT JOIN PSRECDEFN d ON d.RECNAME = f.EDITTABLE
 WHERE f.EDITTABLE IS NOT NULL
   AND f.EDITTABLE <> ' '
 ORDER BY f.RECNAME, f.FIELDNAME;

-- 1.3b Subrecord expansion map — which subrecords are embedded where
SELECT f.RECNAME AS PARENT_RECORD, f.FIELDNAME AS SUBRECORD_NAME
  FROM PSRECFIELD f
  JOIN PSRECDEFN s ON s.RECNAME = f.FIELDNAME AND s.RECTYPE = 3
 ORDER BY 1,2;

-- ------------------------------------------------------------
-- 1.4 Pages, components, menus — the UI surface
-- ------------------------------------------------------------
SELECT * FROM PSPNLDEFN;         -- pages
SELECT * FROM PSPNLGRPDEFN;      -- components (what users actually open)
SELECT * FROM PSPNLGROUP;        -- component-to-page membership  ** was missing in v1 **
SELECT * FROM PSMENUDEFN;
SELECT * FROM PSMENUITEM;

-- PSPNLFIELD is the single largest P1 object (often 1-3M rows).
-- Extract it in slices to keep files under the intake size limit:
SELECT * FROM PSPNLFIELD WHERE PNLNAME <  'H';
SELECT * FROM PSPNLFIELD WHERE PNLNAME >= 'H' AND PNLNAME < 'P';
SELECT * FROM PSPNLFIELD WHERE PNLNAME >= 'P';
-- Name the slices <instance>_P1_PSPNLFIELD_part1.csv etc. and record
-- all three in the manifest.

-- 1.4b Component → primary record → search record (drives process mapping)
SELECT g.PNLGRPNAME, g.MARKET, g.DESCR, g.SEARCHRECNAME,
       g.ADDSRCHRECNAME, g.OBJECTOWNERID, g.LASTUPDOPRID, g.LASTUPDDTTM
  FROM PSPNLGRPDEFN g
 ORDER BY g.PNLGRPNAME, g.MARKET;

-- ------------------------------------------------------------
-- 1.5 Portal registry — the navigation users actually see
-- ------------------------------------------------------------
SELECT * FROM PSPRSMDEFN;
SELECT * FROM PSPRSMPERM;        -- nav item → permission list  ** new in v2 **

-- 1.5b Readable navigation paths (Oracle hierarchical). Run once per
-- PORTAL_NAME returned by 00_discovery §0.8 — do not assume 'EMPLOYEE'.
SELECT PORTAL_NAME, PORTAL_OBJNAME, PORTAL_LABEL,
       PORTAL_URI_SEG1, PORTAL_URI_SEG2, PORTAL_URI_SEG3,
       PORTAL_REFTYPE, LEVEL AS NAV_DEPTH,
       SYS_CONNECT_BY_PATH(PORTAL_LABEL, ' > ') AS NAV_PATH
  FROM PSPRSMDEFN
 WHERE PORTAL_NAME = 'EMPLOYEE'                  -- repeat per portal
 START WITH PORTAL_PRNTOBJNAME = ' '
 CONNECT BY PRIOR PORTAL_OBJNAME = PORTAL_PRNTOBJNAME
        AND PORTAL_NAME = PRIOR PORTAL_NAME;
-- SQL Server equivalent:
--   WITH nav AS (
--     SELECT PORTAL_NAME, PORTAL_OBJNAME, PORTAL_PRNTOBJNAME, PORTAL_LABEL,
--            PORTAL_URI_SEG2, CAST(PORTAL_LABEL AS VARCHAR(4000)) AS NAV_PATH, 1 AS NAV_DEPTH
--       FROM PSPRSMDEFN WHERE PORTAL_PRNTOBJNAME = ' ' AND PORTAL_NAME='EMPLOYEE'
--     UNION ALL
--     SELECT c.PORTAL_NAME, c.PORTAL_OBJNAME, c.PORTAL_PRNTOBJNAME, c.PORTAL_LABEL,
--            c.PORTAL_URI_SEG2, CAST(p.NAV_PATH + ' > ' + c.PORTAL_LABEL AS VARCHAR(4000)), p.NAV_DEPTH+1
--       FROM PSPRSMDEFN c JOIN nav p
--         ON c.PORTAL_PRNTOBJNAME = p.PORTAL_OBJNAME AND c.PORTAL_NAME = p.PORTAL_NAME)
--   SELECT * FROM nav OPTION (MAXRECURSION 100);

-- ------------------------------------------------------------
-- 1.6 Translate values — every coded value in the system
-- v1 filtered EFF_STATUS='A'. Take the full history: inactive codes
-- explain legacy data you will meet during conversion.
-- ------------------------------------------------------------
SELECT * FROM PSXLATITEM;
SELECT * FROM PSXLATDEFN;        -- ** new in v2 ** (where present on your release)

-- ------------------------------------------------------------
-- 1.7 Effective-dating profile  ** new in v2 **
-- Which records are effective-dated tells conversion which tables
-- carry history and need an as-of rule.
-- ------------------------------------------------------------
SELECT d.RECNAME, d.RECDESCR, d.OBJECTOWNERID
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME AND f.FIELDNAME = 'EFFDT')
 ORDER BY d.OBJECTOWNERID, d.RECNAME;

-- ------------------------------------------------------------
-- 1.8 Indexes and physical build (sizing input for the target platform)
-- ------------------------------------------------------------
SELECT * FROM PSINDEXDEFN;
SELECT * FROM PSKEYDEFN;
