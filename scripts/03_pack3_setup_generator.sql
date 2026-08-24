-- ============================================================
-- 03_pack3_setup_generator.sql  (KIT v2)
-- WHAT THE SYSTEM IS CONFIGURED TO DO — self-generating inventory.
--
-- ** THE KEY v2 CORRECTION **
-- v1 defined a setup table as "keyed by SETID or BUSINESS_UNIT".
-- That is a good rule for FSCM and a poor one for HCM. Most HCM setup
-- tables are keyed by neither: EARNINGS_TBL is keyed by ERNCD+EFFDT,
-- DEDUCTION_TBL by DEDCD+PLAN_TYPE, ACTION_TBL by ACTION, COMPANY_TBL
-- by COMPANY, STATE_TAX_TBL by STATE+EFFDT. v1's generator would have
-- missed essentially the entire payroll and benefits rule set and
-- reported clean coverage while doing it.
--
-- v2 uses FOUR detection strategies and unions them:
--   A. SETID-keyed          (FSCM tableset-controlled config)
--   B. BUSINESS_UNIT-keyed  (BU-scoped config)
--   C. PROMPT-TABLE-REFERENCED  ** the reliable one **
--      Any record used as an EDITTABLE by another record is, by
--      definition, reference/setup data. This catches EARNINGS_TBL,
--      ACTION_TBL, tax tables — everything strategy A misses.
--   D. NAME/OWNER heuristic (_TBL, _CD_TBL, _DEFN suffix + small row count)
-- then subtracts transactional tables by size and key shape.
--
-- Sensitivity: LOW (reference/config; no person-level rows) — with the
-- explicit exclusions in §3.6, which v1 did not have.
-- ============================================================

-- ------------------------------------------------------------
-- 3.0 TABLESET CONTROL FIRST  ** was missing in v1 **
-- Extract these before anything else. Without them, SETID-keyed setup
-- data cannot be attributed to a business unit and the whole of
-- strategy A is uninterpretable.
-- ------------------------------------------------------------
SELECT * FROM PS_SETID_TBL;         -- the SETIDs themselves
SELECT * FROM PS_TBLSET_TBL;        -- tableset descriptions, where present
SELECT * FROM PS_REC_GROUP_TBL;     -- record groups
SELECT * FROM PS_REC_GROUP_REC;     -- which records belong to which group
SELECT * FROM PS_SET_CNTRL_TBL;     -- set control values (usually = BU)
SELECT * FROM PS_SET_CNTRL_GROUP;   -- set control → record group → SETID
SELECT * FROM PS_SET_CNTRL_REC;     -- set control → record → SETID (the resolver)

-- 3.0b Readable tableset map — "which BU reads which SETID for which data"
SELECT g.SETCNTRLVALUE      AS BUSINESS_UNIT,
       g.REC_GROUP_ID,
       rg.DESCR             AS RECORD_GROUP_DESCR,
       g.SETID              AS RESOLVED_SETID
  FROM PS_SET_CNTRL_GROUP g
  LEFT JOIN PS_REC_GROUP_TBL rg ON rg.REC_GROUP_ID = g.REC_GROUP_ID
 ORDER BY 1,2;

-- ------------------------------------------------------------
-- 3.1 Strategy A — SETID-keyed records
-- ------------------------------------------------------------
SELECT 'A_SETID' AS DETECTED_BY,
       d.RECNAME, d.RECDESCR,
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
       d.OBJECTOWNERID, d.LASTUPDOPRID, d.LASTUPDDTTM
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME
                  AND f.FIELDNAME = 'SETID'
                  AND BITAND(f.USEEDIT,1) = 1)
 ORDER BY d.OBJECTOWNERID, d.RECNAME;
-- SQL Server: (f.USEEDIT & 1) = 1

-- ------------------------------------------------------------
-- 3.2 Strategy B — BUSINESS_UNIT-keyed records
-- ------------------------------------------------------------
SELECT 'B_BUSUNIT' AS DETECTED_BY,
       d.RECNAME, d.RECDESCR,
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
       d.OBJECTOWNERID, d.LASTUPDOPRID, d.LASTUPDDTTM
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND EXISTS (SELECT 1 FROM PSRECFIELDDB f
                WHERE f.RECNAME = d.RECNAME
                  AND f.FIELDNAME = 'BUSINESS_UNIT'
                  AND BITAND(f.USEEDIT,1) = 1)
 ORDER BY d.OBJECTOWNERID, d.RECNAME;

-- ------------------------------------------------------------
-- 3.3 Strategy C — PROMPT-TABLE REFERENCED  ** the important one **
-- A record that other records validate against is reference data.
-- REF_COUNT doubles as a value ranking: the most-referenced tables are
-- the ones the target ERP must reproduce first.
-- ------------------------------------------------------------
SELECT 'C_PROMPT' AS DETECTED_BY,
       d.RECNAME, d.RECDESCR,
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
       d.OBJECTOWNERID,
       COUNT(DISTINCT f.RECNAME) AS REFERENCED_BY_RECORDS,
       d.LASTUPDOPRID, d.LASTUPDDTTM
  FROM PSRECFIELD f
  JOIN PSRECDEFN  d ON d.RECNAME = f.EDITTABLE
 WHERE f.EDITTABLE IS NOT NULL AND f.EDITTABLE <> ' '
   AND d.RECTYPE = 0
 GROUP BY d.RECNAME, d.RECDESCR, d.SQLTABLENAME, d.OBJECTOWNERID,
          d.LASTUPDOPRID, d.LASTUPDDTTM
 ORDER BY REFERENCED_BY_RECORDS DESC;

-- ------------------------------------------------------------
-- 3.4 Strategy D — naming/owner heuristic, for the residue
-- ------------------------------------------------------------
SELECT 'D_NAMING' AS DETECTED_BY,
       d.RECNAME, d.RECDESCR,
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
       d.OBJECTOWNERID, d.LASTUPDOPRID, d.LASTUPDDTTM
  FROM PSRECDEFN d
 WHERE d.RECTYPE = 0
   AND (d.RECNAME LIKE '%\_TBL'  ESCAPE '\'
     OR d.RECNAME LIKE '%\_CD'   ESCAPE '\'
     OR d.RECNAME LIKE '%\_DEFN' ESCAPE '\'
     OR d.RECNAME LIKE '%\_TYPE' ESCAPE '\'
     OR d.RECNAME LIKE '%\_CDE'  ESCAPE '\'
     OR d.RECNAME LIKE '%\_SETUP' ESCAPE '\'
     OR d.RECNAME LIKE '%\_OPT'  ESCAPE '\'
     OR d.RECNAME LIKE '%\_RULE%' ESCAPE '\'
     OR d.RECNAME LIKE 'INSTALLATION%')
 ORDER BY d.OBJECTOWNERID, d.RECNAME;

-- ------------------------------------------------------------
-- 3.5 UNIFIED SETUP INVENTORY — union the four strategies
-- Export as <instance>_P3_SETUP_INVENTORY.csv. This drives everything
-- downstream, including the extract generator in §3.8.
-- ------------------------------------------------------------
WITH cand AS (
  SELECT d.RECNAME, d.RECDESCR, d.OBJECTOWNERID, d.LASTUPDOPRID, d.LASTUPDDTTM,
         CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
              THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END AS PHYSICAL_TABLE,
         MAX(CASE WHEN f.FIELDNAME='SETID'         AND BITAND(f.USEEDIT,1)=1 THEN 1 ELSE 0 END) AS BY_SETID,
         MAX(CASE WHEN f.FIELDNAME='BUSINESS_UNIT' AND BITAND(f.USEEDIT,1)=1 THEN 1 ELSE 0 END) AS BY_BU,
         MAX(CASE WHEN f.FIELDNAME='EFFDT'                                    THEN 1 ELSE 0 END) AS IS_EFFDATED,
         MAX(CASE WHEN f.FIELDNAME IN ('EMPLID','NATIONAL_ID','SSN','VENDOR_ID',
                                       'CUST_ID','APPLID','STDNT_CAR_NBR')    THEN 1 ELSE 0 END) AS HAS_PERSON_KEY
    FROM PSRECDEFN d
    LEFT JOIN PSRECFIELDDB f ON f.RECNAME = d.RECNAME
   WHERE d.RECTYPE = 0
   GROUP BY d.RECNAME, d.RECDESCR, d.OBJECTOWNERID, d.LASTUPDOPRID,
            d.LASTUPDDTTM, d.SQLTABLENAME
), prompted AS (
  SELECT f.EDITTABLE AS RECNAME, COUNT(DISTINCT f.RECNAME) AS REF_COUNT
    FROM PSRECFIELD f
   WHERE f.EDITTABLE IS NOT NULL AND f.EDITTABLE <> ' '
   GROUP BY f.EDITTABLE
)
SELECT c.RECNAME, c.PHYSICAL_TABLE, c.RECDESCR, c.OBJECTOWNERID,
       c.BY_SETID, c.BY_BU,
       NVL(p.REF_COUNT,0) AS REFERENCED_BY_RECORDS,
       c.IS_EFFDATED, c.HAS_PERSON_KEY,
       CASE WHEN c.BY_SETID = 1 THEN 'A_SETID'
            WHEN c.BY_BU    = 1 THEN 'B_BUSUNIT'
            WHEN NVL(p.REF_COUNT,0) > 0 THEN 'C_PROMPT'
            ELSE 'D_NAMING' END AS DETECTED_BY,
       c.LASTUPDOPRID, c.LASTUPDDTTM
  FROM cand c
  LEFT JOIN prompted p ON p.RECNAME = c.RECNAME
 WHERE (c.BY_SETID = 1 OR c.BY_BU = 1 OR NVL(p.REF_COUNT,0) > 0
        OR c.RECNAME LIKE '%\_TBL' ESCAPE '\'
        OR c.RECNAME LIKE 'INSTALLATION%')
   AND c.HAS_PERSON_KEY = 0            -- §3.6 exclusion, applied here
 ORDER BY c.OBJECTOWNERID, NVL(p.REF_COUNT,0) DESC, c.RECNAME;
-- SQL Server: NVL → ISNULL, BITAND(x,1)=1 → (x & 1)=1

-- ------------------------------------------------------------
-- 3.6 PERSON / TRANSACTION EXCLUSION  ** new in v2 **
-- v1 asserted "no pack extracts person-level rows" but had no mechanism
-- enforcing it — the generator would happily have emitted a SELECT * on
-- any SETID-keyed table that also carried EMPLID. This is the guard.
-- Run it and confirm the list is empty of anything you are extracting.
-- ------------------------------------------------------------
SELECT d.RECNAME, d.RECDESCR, f.FIELDNAME AS PERSON_KEY_FOUND
  FROM PSRECDEFN d
  JOIN PSRECFIELDDB f ON f.RECNAME = d.RECNAME
 WHERE d.RECTYPE = 0
   AND f.FIELDNAME IN ('EMPLID','NATIONAL_ID','SSN','BIRTHDATE','VENDOR_ID',
                       'CUST_ID','APPLID','STDNT_CAR_NBR','BANK_ACCOUNT_NUM',
                       'ACCOUNT_NUM','CREDIT_CARD_NBR')
 ORDER BY d.RECNAME;
-- Anything appearing here is OUT OF SCOPE for Pack 3. Person and
-- transactional data conversion is a separate exercise with its own
-- governance and its own approvals.

-- ------------------------------------------------------------
-- 3.7 Row counts for the inventory — prioritise, and skip empties
-- Run the generated statements, then feed results into the manifest.
-- ------------------------------------------------------------
SELECT 'SELECT ''' || RECNAME || ''' AS RECNAME, COUNT(*) AS CNT FROM ' ||
       CASE WHEN SQLTABLENAME = ' ' OR SQLTABLENAME IS NULL
            THEN 'PS_' || RECNAME ELSE SQLTABLENAME END || ' UNION ALL' AS COUNT_STMT
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
 ORDER BY RECNAME;

-- ------------------------------------------------------------
-- 3.8 EXTRACT STATEMENT GENERATOR
-- Run the output as a script, spooling each to
-- <instance>_P3_<RECNAME>.csv. Skip zero-row tables (§3.7).
-- v2 additions: person-key exclusion, a row-cap guard, and the
-- manifest line emitted alongside each statement.
-- ------------------------------------------------------------
SELECT 'SELECT * FROM ' ||
       CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
            THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END ||
       ';  ' || CHR(45)||CHR(45) || ' manifest: <INSTANCE>_P3_' || d.RECNAME || '.csv|' ||
       d.OBJECTOWNERID || '|' || d.RECNAME AS EXTRACT_STMT
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
 ORDER BY d.OBJECTOWNERID, d.RECNAME;

-- ------------------------------------------------------------
-- 3.9 Coverage reconciliation  ** new in v2 **
-- Prove the generator found the anchors. Any anchor listed in the 03a–03h
-- files that does NOT appear in §3.5 output is a generator blind spot —
-- report it rather than silently relying on the anchor file.
-- ------------------------------------------------------------
SELECT d.RECNAME,
       CASE WHEN EXISTS (SELECT 1 FROM PSRECFIELDDB f
                          WHERE f.RECNAME = d.RECNAME
                            AND f.FIELDNAME IN ('SETID','BUSINESS_UNIT')
                            AND BITAND(f.USEEDIT,1) = 1) THEN 'Y' ELSE 'N' END AS FOUND_BY_KEY,
       CASE WHEN EXISTS (SELECT 1 FROM PSRECFIELD p
                          WHERE p.EDITTABLE = d.RECNAME) THEN 'Y' ELSE 'N' END AS FOUND_BY_PROMPT
  FROM PSRECDEFN d
 WHERE d.RECNAME IN (
   -- paste your instance's anchor list here (from 03a/03b/.../03h)
   'COMPANY_TBL','EARNINGS_TBL','DEDUCTION_TBL','ACTION_TBL','STATE_TAX_TBL',
   'GL_ACCOUNT_TBL','FUND_TBL','LED_DEFN_TBL','JRNL_SOURCE_TBL','TERM_TBL')
 ORDER BY d.RECNAME;

-- NOTE on OBJECTOWNERID: it groups records by owning product
-- (HR, PY, BN, TL, GL, AP, AR, BI, AM, PC, GM, EX, PO, IN, SR, SF, AD).
-- That single column is what lets one generator serve finance, HR,
-- payroll, supply chain and student at once. PSOBJGROUP (extracted in
-- 00_discovery §0.2) is the decode table.
