-- ============================================================
-- 03h_anchors_campus.sql  (KIT v2) — run on the Campus Solutions instance
-- Student pillar. Kept lighter than HCM/FSCM because the stated scope
-- for this cycle is finance, HR and payroll — but the crosswalk tables
-- matter to those pillars and are extracted here.
--
-- v1 guarded 17 CS tables and extracted 11 (ACAD_SUB_PLN_TBL,
-- ACAD_GROUP_TBL, SUBJECT_TBL, ACAD_CAL_TBL, ADM_APPL_CTR_TBL and
-- COMM_CATG_TBL were guarded and dropped). Same guard-generates-extract
-- fix as the other anchor files.
-- ============================================================

-- ------------------------------------------------------------
-- 3h.1 Guard + generate
-- ------------------------------------------------------------
WITH anchors AS (
  SELECT 'INSTITUTION_TBL'   AS RECNAME, 'Institutions'                     AS PURPOSE FROM DUAL UNION ALL
  SELECT 'ACAD_CAREER_TBL'         , 'Academic careers'                          FROM DUAL UNION ALL
  SELECT 'ACAD_PROG_TBL'           , 'Academic programs'                         FROM DUAL UNION ALL
  SELECT 'ACAD_PLAN_TBL'           , 'Academic plans'                            FROM DUAL UNION ALL
  SELECT 'ACAD_SUB_PLN_TBL'        , 'Academic sub-plans'                        FROM DUAL UNION ALL
  SELECT 'ACAD_GROUP_TBL'          , 'Academic groups'                           FROM DUAL UNION ALL
  SELECT 'ACAD_ORG_TBL'            , 'Academic orgs — HCM department crosswalk'  FROM DUAL UNION ALL
  SELECT 'SUBJECT_TBL'             , 'Subject areas'                             FROM DUAL UNION ALL
  SELECT 'TERM_TBL'                , 'Terms — feeds the cutover calendar'        FROM DUAL UNION ALL
  SELECT 'SESSION_TBL'             , 'Sessions'                                  FROM DUAL UNION ALL
  SELECT 'ACAD_CAL_TBL'            , 'Academic calendars'                        FROM DUAL UNION ALL
  SELECT 'TERM_VAL_TBL'            , 'Valid terms by career'                     FROM DUAL UNION ALL
  SELECT 'GRADE_SCHEME_TBL'        , 'Grading schemes'                           FROM DUAL UNION ALL
  SELECT 'GRADE_TBL'               , 'Grade values'                              FROM DUAL UNION ALL
  SELECT 'ITEM_TYPE_TBL'           , 'SF item types — charge/credit taxonomy'    FROM DUAL UNION ALL
  SELECT 'ITEM_TYPE_CF'            , 'Item type to GL chartfield mapping'        FROM DUAL UNION ALL
  SELECT 'TUIT_CALC_TBL'           , 'Tuition calculation setup'                 FROM DUAL UNION ALL
  SELECT 'TERM_FEE_TBL'            , 'Term fee setup'                            FROM DUAL UNION ALL
  SELECT 'SRVC_IND_CD_TBL'         , 'Service indicators (holds)'                FROM DUAL UNION ALL
  SELECT 'CHECKLIST_TBL'           , 'Checklists — student-side workflow'        FROM DUAL UNION ALL
  SELECT 'COMM_CATG_TBL'           , 'Communication categories'                  FROM DUAL UNION ALL
  SELECT 'ADM_APPL_CTR_TBL'        , 'Admissions application centres'            FROM DUAL UNION ALL
  SELECT 'ADM_ACTION_TBL'          , 'Admissions actions'                        FROM DUAL UNION ALL
  SELECT 'FA_ITEM_TYPE'            , 'Financial aid item types'                  FROM DUAL UNION ALL
  SELECT 'INSTALLATION_SF'         , 'Student Financials installation options'   FROM DUAL UNION ALL
  SELECT 'INSTALLATION_CS'         , 'CS installation options'                   FROM DUAL
)
SELECT a.RECNAME, a.PURPOSE,
       CASE WHEN d.RECNAME IS NULL THEN 'ABSENT' ELSE 'PRESENT' END AS STATUS,
       CASE WHEN d.RECNAME IS NULL THEN CHR(45)||CHR(45)||' not on this instance'
            ELSE 'SELECT * FROM ' ||
                 CASE WHEN d.SQLTABLENAME = ' ' OR d.SQLTABLENAME IS NULL
                      THEN 'PS_' || d.RECNAME ELSE d.SQLTABLENAME END || ';'
       END AS EXTRACT_STMT
  FROM anchors a
  LEFT JOIN PSRECDEFN d ON d.RECNAME = a.RECNAME AND d.RECTYPE = 0
 ORDER BY a.RECNAME;
-- Student Financials fee/tuition setup varies widely by configuration.
-- The 03 generator filtered on OBJECTOWNERID = 'SF' is authoritative for
-- the complete SF list; these are the first-asked tables.

-- ------------------------------------------------------------
-- 3h.2 STUDENT FINANCIALS → GL CROSSWALK  ** finance-relevant **
-- ITEM_TYPE_CF maps every student charge and credit to a GL chartfield
-- string. It is the CS equivalent of the payroll ACCT_CD_TBL seam, and
-- it belongs in the finance discovery even when the student pillar is
-- out of scope for this cycle.
-- ------------------------------------------------------------
SELECT SETID, ITEM_TYPE, EFFDT, CHARTFIELD_NAME, CHARTFIELD_VALUE,
       BUSINESS_UNIT_GL, PERCENT_DISTRIB
  FROM PS_ITEM_TYPE_CF ORDER BY SETID, ITEM_TYPE, EFFDT;
-- Column names vary by release; list them first if any is rejected.

-- ------------------------------------------------------------
-- 3h.3 ACADEMIC ORG ↔ HR DEPARTMENT crosswalk
-- Academic orgs and HR departments are separate hierarchies that
-- describe the same institution. Reconciling them is a named
-- deliverable in most higher-ed ERP programmes; here is the raw input.
-- ------------------------------------------------------------
SELECT SETID, ACAD_ORG, EFFDT, EFF_STATUS, DESCR, DESCRSHORT
  FROM PS_ACAD_ORG_TBL WHERE EFF_STATUS = 'A' ORDER BY SETID, ACAD_ORG;
-- Compare against PS_DEPT_TBL from the HCM instance (03a §3a.2) in
-- Databricks. Report matched, unmatched-academic and unmatched-HR counts.

-- ------------------------------------------------------------
-- 3h.4 Term calendar — drives cutover timing
-- ------------------------------------------------------------
SELECT INSTITUTION, ACAD_CAREER, STRM, DESCR,
       TERM_BEGIN_DT, TERM_END_DT, ACAD_YEAR
  FROM PS_TERM_TBL ORDER BY TERM_BEGIN_DT DESC;
-- Overlay these dates on the payroll calendar (03b §3b.5) and the GL
-- close calendar (03d §3d.3) to find the windows where a cutover is
-- least destructive. Very few institutions have more than two per year.

-- ------------------------------------------------------------
-- 3h.5 Volume profile — aggregate only, no student records
-- ------------------------------------------------------------
SELECT 'ACTIVE_TERMS'  AS OBJ, COUNT(*) AS CNT FROM PS_TERM_TBL
 WHERE TERM_END_DT >= SYSDATE - 730                                    UNION ALL
SELECT 'ACAD_PROGRAMS'      , COUNT(*) FROM PS_ACAD_PROG_TBL           UNION ALL
SELECT 'ACAD_PLANS'         , COUNT(*) FROM PS_ACAD_PLAN_TBL           UNION ALL
SELECT 'SF_ITEM_TYPES'      , COUNT(*) FROM PS_ITEM_TYPE_TBL           UNION ALL
SELECT 'SERVICE_INDICATORS' , COUNT(*) FROM PS_SRVC_IND_CD_TBL;
