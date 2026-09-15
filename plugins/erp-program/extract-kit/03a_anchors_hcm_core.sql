-- ============================================================
-- 03a_anchors_hcm_core.sql  (KIT v2) — run on the HCM instance
-- Core HR: org structure, jobs, positions, compensation framework.
-- Payroll is in 03b. Benefits and Time & Labor are in 03c.
--
-- ** v2 STRUCTURAL FIX **
-- v1's anchor files listed 25 tables in the existence guard and then
-- hand-wrote SELECTs for only 17 of them. GARN_RULE_TBL, BEN_DEFN_PLAN,
-- HOLIDAY_SCHED_TBL, SHIFT_TBL, ABS_TYPE_TBL, SCH_DEFN_TBL, JOB_FAMILY_TBL
-- and COMP_RATECD_TBL were guarded and then never extracted. That drift
-- is invisible at run time and produces a silently incomplete extract.
-- v2 removes hand-written SELECT lists entirely: the guard GENERATES the
-- extract statements, so guard and extract cannot diverge.
-- ============================================================

-- ------------------------------------------------------------
-- 3a.1 Anchor list → existence check → generated extract statements
-- Run this; then run its output as a script.
-- ------------------------------------------------------------
WITH anchors AS (
  SELECT 'COMPANY_TBL'       AS RECNAME, 'Legal employers'                 AS PURPOSE FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_HR'         , 'HR business units'                        FROM DUAL UNION ALL
  SELECT 'SETID_TBL'               , 'Tableset IDs'                             FROM DUAL UNION ALL
  SELECT 'DEPT_TBL'                , 'Department master (HR side)'              FROM DUAL UNION ALL
  SELECT 'LOCATION_TBL'            , 'Work locations'                           FROM DUAL UNION ALL
  SELECT 'ESTABLISHMENT_TBL'       , 'Establishments (reg reporting)'           FROM DUAL UNION ALL
  SELECT 'JOBCODE_TBL'             , 'Job codes'                                FROM DUAL UNION ALL
  SELECT 'JOB_FAMILY_TBL'          , 'Job families'                             FROM DUAL UNION ALL
  SELECT 'JOB_SUBFUNC_TBL'         , 'Job sub-functions'                        FROM DUAL UNION ALL
  SELECT 'JOB_FUNCTION_TBL'        , 'Job functions'                            FROM DUAL UNION ALL
  SELECT 'POSITION_DATA'           , 'Position master (org design, no person)'  FROM DUAL UNION ALL
  SELECT 'SAL_PLAN_TBL'            , 'Salary plans'                             FROM DUAL UNION ALL
  SELECT 'SAL_GRADE_TBL'           , 'Salary grades'                            FROM DUAL UNION ALL
  SELECT 'SAL_STEP_TBL'            , 'Salary steps'                             FROM DUAL UNION ALL
  SELECT 'SAL_RATECD_TBL'          , 'Salary rate codes'                        FROM DUAL UNION ALL
  SELECT 'COMP_RATECD_TBL'         , 'Compensation rate codes'                  FROM DUAL UNION ALL
  SELECT 'COMP_RATE_MATRIX'        , 'Rate matrices'                            FROM DUAL UNION ALL
  SELECT 'ACTION_TBL'              , 'Job actions (hire, promote, term)'        FROM DUAL UNION ALL
  SELECT 'ACTN_REASON_TBL'         , 'Action reasons — the HR event taxonomy'   FROM DUAL UNION ALL
  SELECT 'UNION_TBL'               , 'Bargaining units — CBA discovery anchor'  FROM DUAL UNION ALL
  SELECT 'LABOR_AGRMNT_TBL'        , 'Labour agreements'                        FROM DUAL UNION ALL
  SELECT 'REG_REGION_TBL'          , 'Regulatory regions'                       FROM DUAL UNION ALL
  SELECT 'EMPL_CLASS_TBL'          , 'Employee classes'                         FROM DUAL UNION ALL
  SELECT 'EMPL_CTG_TBL'            , 'Employee categories'                      FROM DUAL UNION ALL
  SELECT 'FULL_PART_TBL'           , 'Full/part-time codes'                     FROM DUAL UNION ALL
  SELECT 'STD_HOURS_TBL'           , 'Standard hours defaults'                  FROM DUAL UNION ALL
  SELECT 'SUPV_LVL_TBL'            , 'Supervisor levels'                        FROM DUAL UNION ALL
  SELECT 'FREQUENCY_TBL'           , 'Pay frequencies'                          FROM DUAL UNION ALL
  SELECT 'CURRENCY_CD_TBL'         , 'Currencies'                               FROM DUAL UNION ALL
  SELECT 'COUNTRY_TBL'             , 'Countries'                                FROM DUAL UNION ALL
  SELECT 'STATE_NAMES_TBL'         , 'States/provinces'                         FROM DUAL UNION ALL
  SELECT 'INSTALLATION'            , 'HCM installation options'                 FROM DUAL UNION ALL
  SELECT 'INSTALLATION_HR'         , 'HR installation options'                  FROM DUAL
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
-- SQL Server: drop "FROM DUAL" from each UNION ALL branch.

-- ------------------------------------------------------------
-- 3a.2 Org structure as reported — department hierarchy with rollup
-- DEPT_TBL is flat; the hierarchy is in the DEPARTMENT tree (03i).
-- This gives the flat view with the tree node attached.
-- ------------------------------------------------------------
SELECT d.SETID, d.DEPTID, d.EFFDT, d.EFF_STATUS, d.DESCR,
       d.COMPANY, d.LOCATION, d.MANAGER_ID, d.BUDGET_LVL,
       d.GL_EXPENSE, d.EEO4_FUNCTION
  FROM PS_DEPT_TBL d
 WHERE d.EFFDT = (SELECT MAX(d2.EFFDT) FROM PS_DEPT_TBL d2
                   WHERE d2.SETID = d.SETID AND d2.DEPTID = d.DEPTID
                     AND d2.EFFDT <= SYSDATE)
 ORDER BY d.SETID, d.DEPTID;
-- SQL Server: SYSDATE → GETDATE()
-- Note GL_EXPENSE: this is the HR→GL chartfield link. Reconcile it
-- against the FSCM chartfields extracted in 03d — mismatches here are a
-- standing source of payroll posting failures and will bite at cutover.

-- ------------------------------------------------------------
-- 3a.3 Position management profile — is it position-driven or job-driven?
-- Determines a large part of the target-ERP design and is answerable
-- from data rather than opinion.
-- ------------------------------------------------------------
SELECT POSITION_MGMT_OPT, COUNT(*) AS BUSINESS_UNITS
  FROM PS_BUS_UNIT_TBL_HR GROUP BY POSITION_MGMT_OPT;

SELECT COUNT(*) AS POSITIONS,
       SUM(CASE WHEN EFF_STATUS = 'A' THEN 1 ELSE 0 END) AS ACTIVE_POSITIONS,
       COUNT(DISTINCT DEPTID) AS DEPARTMENTS_WITH_POSITIONS
  FROM PS_POSITION_DATA;

-- ------------------------------------------------------------
-- 3a.4 Action/reason usage — which HR events actually occur.
-- Aggregate only; PS_JOB is person data and is NOT extracted.
-- ------------------------------------------------------------
SELECT ACTION, ACTION_REASON, COUNT(*) AS EVENTS,
       MIN(EFFDT) AS FIRST_USED, MAX(EFFDT) AS LAST_USED
  FROM PS_JOB
 GROUP BY ACTION, ACTION_REASON
 ORDER BY EVENTS DESC;
-- This aggregate carries no person identifiers and is the single best
-- evidence of which HR transactions the target ERP must support.

-- ------------------------------------------------------------
-- 3a.5 Workforce shape — sizing, aggregate only
-- ------------------------------------------------------------
SELECT j.COMPANY, j.PAYGROUP, j.EMPL_TYPE, j.FULL_PART_TIME, j.REG_TEMP,
       COUNT(*) AS HEADCOUNT
  FROM PS_JOB j
 WHERE j.EFFDT = (SELECT MAX(j2.EFFDT) FROM PS_JOB j2
                   WHERE j2.EMPLID = j.EMPLID AND j2.EMPL_RCD = j.EMPL_RCD
                     AND j2.EFFDT <= SYSDATE)
   AND j.EMPL_STATUS IN ('A','L','P','S','W')
 GROUP BY j.COMPANY, j.PAYGROUP, j.EMPL_TYPE, j.FULL_PART_TIME, j.REG_TEMP
 ORDER BY HEADCOUNT DESC;
