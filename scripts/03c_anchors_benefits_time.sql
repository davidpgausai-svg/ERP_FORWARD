-- ============================================================
-- 03c_anchors_benefits_time.sql  (KIT v2) — NEW FILE, run on HCM
-- Benefits, Benefits Administration, Absence, and Time & Labor config.
--
-- v1 guarded BEN_DEFN_PGM / BEN_DEFN_PLAN / ABS_TYPE_TBL / SCH_DEFN_TBL
-- and extracted only BEN_DEFN_PGM. Time & Labor — workgroups, task
-- groups, rule programs, time reporting codes — was absent entirely,
-- which matters because in most PeopleSoft estates T&L is where the
-- genuinely site-specific labour rules live.
--
-- Sensitivity: LOW (plan and rule configuration; no enrolments).
-- ============================================================

-- ------------------------------------------------------------
-- 3c.1 Guard + generate
-- ------------------------------------------------------------
WITH anchors AS (
  -- Base benefits -------------------------------------------------
  SELECT 'BEN_DEFN_PGM'      AS RECNAME, 'Benefit programs'                  AS PURPOSE FROM DUAL UNION ALL
  SELECT 'BEN_DEFN_PLAN'           , 'Benefit plans (v1 guarded, never got)'      FROM DUAL UNION ALL
  SELECT 'BEN_DEFN_OPTN'           , 'Benefit options'                            FROM DUAL UNION ALL
  SELECT 'BEN_PROG_PARTIC'         , 'Program participation rules'                FROM DUAL UNION ALL
  SELECT 'BENEF_PLAN_TBL'          , 'Benefit plan table'                         FROM DUAL UNION ALL
  SELECT 'BENEFIT_PLAN_TBL'        , 'Benefit plan definitions (alt name)'        FROM DUAL UNION ALL
  SELECT 'COVRG_CD_TBL'            , 'Coverage codes'                             FROM DUAL UNION ALL
  SELECT 'BENEF_RT_TBL'            , 'Benefit rate tables'                        FROM DUAL UNION ALL
  SELECT 'CALC_RULES_TBL'          , 'Benefit calculation rules'                  FROM DUAL UNION ALL
  SELECT 'ELIG_RULES_TBL'          , 'Eligibility rules'                          FROM DUAL UNION ALL
  SELECT 'EVENT_RULES_TBL'         , 'Event rules (BenAdmin)'                     FROM DUAL UNION ALL
  SELECT 'EVENT_CLASS_TBL'         , 'Event classes'                              FROM DUAL UNION ALL
  SELECT 'BAS_SCHED_TBL'           , 'BenAdmin processing schedules'              FROM DUAL UNION ALL
  SELECT 'VENDOR_TBL_BN'           , 'Benefit providers'                          FROM DUAL UNION ALL
  SELECT 'INSTALLATION_BN'         , 'Benefits installation options'              FROM DUAL UNION ALL
  -- Absence -------------------------------------------------------
  SELECT 'ABS_TYPE_TBL'            , 'Absence types (v1 guarded, never got)'      FROM DUAL UNION ALL
  SELECT 'LEAVE_PLAN_TBL'          , 'Leave plans'                                FROM DUAL UNION ALL
  SELECT 'LEAVE_ACCRL_TBL'         , 'Leave accrual rules'                        FROM DUAL UNION ALL
  SELECT 'FMLA_PLAN_TBL'           , 'FMLA plan setup'                            FROM DUAL UNION ALL
  -- Time & Labor --------------------------------------------------
  SELECT 'TL_TRC_TBL'              , 'Time reporting codes'                       FROM DUAL UNION ALL
  SELECT 'TL_TRC_PGM_TBL'          , 'TRC programs'                               FROM DUAL UNION ALL
  SELECT 'TL_TRC_PGM_DTL'          , 'TRC program detail'                         FROM DUAL UNION ALL
  SELECT 'TL_WRKGRP_TBL'           , 'Workgroups — the T&L rule container'        FROM DUAL UNION ALL
  SELECT 'TL_TASKGRP_TBL'          , 'Task groups'                                FROM DUAL UNION ALL
  SELECT 'TL_TASKPRFL_TBL'         , 'Task profiles'                              FROM DUAL UNION ALL
  SELECT 'TL_RULE_HDR'             , 'T&L rule headers'                           FROM DUAL UNION ALL
  SELECT 'TL_RULE_PGM_TBL'         , 'Rule programs'                              FROM DUAL UNION ALL
  SELECT 'TL_RULE_PGM_DTL'         , 'Rule program detail'                        FROM DUAL UNION ALL
  SELECT 'TL_RULE_ELEMENT'         , 'Rule elements'                              FROM DUAL UNION ALL
  SELECT 'TL_COMP_RULE_TBL'        , 'Compensatory time rules'                    FROM DUAL UNION ALL
  SELECT 'TL_ROUND_RULE_TBL'       , 'Rounding rules'                             FROM DUAL UNION ALL
  SELECT 'SCH_DEFN_TBL'            , 'Schedule definitions (v1 guarded, never got)' FROM DUAL UNION ALL
  SELECT 'SCH_CLND_DTL'            , 'Schedule calendar detail'                   FROM DUAL UNION ALL
  SELECT 'PUNCH_TYPE_TBL'          , 'Punch types'                                FROM DUAL UNION ALL
  SELECT 'INSTALLATION_TL'         , 'T&L installation options'                   FROM DUAL
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

-- ------------------------------------------------------------
-- 3c.2 Benefit program shape — plans per program, aggregate
-- ------------------------------------------------------------
SELECT BENEFIT_PROGRAM, EFFDT, COUNT(DISTINCT PLAN_TYPE) AS PLAN_TYPES,
       COUNT(*) AS PLAN_ROWS
  FROM PS_BEN_DEFN_PGM
 GROUP BY BENEFIT_PROGRAM, EFFDT ORDER BY 1,2;

-- ------------------------------------------------------------
-- 3c.3 T&L RULE INVENTORY — the site-specific labour logic
-- Every custom TL rule is a requirement the target ERP must satisfy or
-- an over-engineered practice to retire. Either way it needs to be seen.
-- ------------------------------------------------------------
SELECT r.TL_RULE_ID, r.EFFDT, r.DESCR, r.TL_RULE_TYPE,
       r.SQL_OBJECT_ID, r.LASTUPDOPRID, r.LASTUPDDTTM,
       CASE WHEN r.LASTUPDOPRID NOT IN ('PPLSOFT',' ') THEN 'SITE_MODIFIED'
            ELSE 'DELIVERED' END AS ORIGIN
  FROM PS_TL_RULE_HDR r
 ORDER BY ORIGIN, r.TL_RULE_ID;
-- Rules whose ORIGIN is SITE_MODIFIED: pull the referenced SQL object
-- text from PSSQLTEXTDEFN (Pack 2 §2.2) using SQL_OBJECT_ID.

-- 3c.3b Workgroup → rule program → rules, the readable chain
SELECT w.WORKGROUP, w.EFFDT, w.DESCR AS WORKGROUP_DESCR,
       w.TL_RULE_PGM_ID, p.DESCR AS RULE_PROGRAM_DESCR,
       d.TL_RULE_ID, d.SEQ_NBR
  FROM PS_TL_WRKGRP_TBL w
  LEFT JOIN PS_TL_RULE_PGM_TBL p ON p.TL_RULE_PGM_ID = w.TL_RULE_PGM_ID
  LEFT JOIN PS_TL_RULE_PGM_DTL d ON d.TL_RULE_PGM_ID = w.TL_RULE_PGM_ID
 ORDER BY w.WORKGROUP, d.SEQ_NBR;

-- ------------------------------------------------------------
-- 3c.4 Time reporting code usage — which TRCs are live.
-- Aggregate over reported time; no EMPLID, no hours per person.
-- ------------------------------------------------------------
SELECT TRC, COUNT(*) AS REPORTED_LINES,
       MIN(DUR) AS FIRST_DATE, MAX(DUR) AS LAST_DATE
  FROM PS_TL_RPTD_TIME GROUP BY TRC ORDER BY 2 DESC;
-- Column name for the date is DUR on most releases; adjust if rejected.

-- 3c.4b Dormant TRCs
SELECT t.TRC, t.DESCR
  FROM PS_TL_TRC_TBL t
 WHERE NOT EXISTS (SELECT 1 FROM PS_TL_RPTD_TIME r WHERE r.TRC = t.TRC)
 GROUP BY t.TRC, t.DESCR ORDER BY t.TRC;

-- ------------------------------------------------------------
-- 3c.5 Absence/leave plan profile
-- ------------------------------------------------------------
SELECT PLAN_TYPE, BENEFIT_PLAN, EFFDT, EFF_STATUS, DESCR
  FROM PS_LEAVE_PLAN_TBL ORDER BY PLAN_TYPE, BENEFIT_PLAN, EFFDT;
