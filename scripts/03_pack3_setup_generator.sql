-- ============================================================
-- 03_pack3_setup_generator.sql — WHAT THE SYSTEM IS CONFIGURED TO DO
-- The enterprise trick: DO NOT hand-list setup tables per pillar.
-- PeopleSoft setup tables are identifiable from metadata — they are
-- SQL tables keyed by SETID or BUSINESS_UNIT. This script derives the
-- complete inventory for THIS instance (works identically on HCM,
-- FSCM, and Campus Solutions), then generates the extract statements.
-- Sensitivity: low (reference/config data; no person-level rows)
-- ============================================================

-- 3.1 Inventory: all SETID-keyed setup records (Oracle BITAND; SQL Server: (USEEDIT & 1) = 1)
SELECT d.RECNAME,
       d.RECDESCR,
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
       d.OBJECTOWNERID,          -- owning module (HR, GL, SR, etc.) — your pillar grouping
       d.LASTUPDOPRID, d.LASTUPDDTTM
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0                                   -- physical SQL tables only
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME
                  AND f.FIELDNAME = 'SETID'
                  AND BITAND(f.USEEDIT, 1) = 1)        -- SETID is a key
 ORDER BY d.OBJECTOWNERID, d.RECNAME;

-- 3.2 Inventory: BUSINESS_UNIT-keyed configuration records
SELECT d.RECNAME, d.RECDESCR,
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
       d.OBJECTOWNERID, d.LASTUPDOPRID, d.LASTUPDDTTM
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME
                  AND f.FIELDNAME = 'BUSINESS_UNIT'
                  AND BITAND(f.USEEDIT, 1) = 1)
 ORDER BY d.OBJECTOWNERID, d.RECNAME;

-- 3.3 Row counts for the inventory (prioritize what to extract first;
-- skip empty tables). Generate the count statements:
SELECT 'SELECT ''' || RECNAME || ''' AS RECNAME, COUNT(*) AS CNT FROM ' ||
       CASE WHEN SQLTABLENAME = ' ' OR SQLTABLENAME IS NULL
            THEN 'PS_' || RECNAME ELSE SQLTABLENAME END || ' UNION ALL' AS COUNT_STMT
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME AND f.FIELDNAME IN ('SETID','BUSINESS_UNIT')
                  AND BITAND(f.USEEDIT, 1) = 1);

-- 3.4 Generate the extract statements themselves (run output as a script,
-- spooling each to <instance>_P3_<RECNAME>.csv; skip zero-row tables)
SELECT 'SELECT * FROM ' ||
       CASE WHEN SQLTABLENAME = ' ' OR SQLTABLENAME IS NULL
            THEN 'PS_' || RECNAME ELSE SQLTABLENAME END || ';' AS EXTRACT_STMT
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME AND f.FIELDNAME IN ('SETID','BUSINESS_UNIT')
                  AND BITAND(f.USEEDIT, 1) = 1)
 ORDER BY d.RECNAME;

-- NOTE: OBJECTOWNERID in 3.1/3.2 groups records by owning product
-- (HR, PY, BN, GL, AP, PO, SR, SF, AD, etc.) — that column is how the
-- one generator serves finance, student, HR, payroll, and supply chain
-- at once. Extract PSOBJGROUP if you want the owner-ID decode table.
