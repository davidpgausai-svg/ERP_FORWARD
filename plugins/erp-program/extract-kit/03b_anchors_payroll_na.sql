-- ============================================================
-- 03b_anchors_payroll_na.sql  (KIT v2) — NEW FILE, run on HCM
-- NORTH AMERICAN PAYROLL configuration and rules.
--
-- ** THE LARGEST FUNCTIONAL GAP IN v1 **
-- v1's HCM anchor file offered eight payroll-adjacent tables
-- (PAYGROUP_TBL, PAY_CALENDAR, EARNINGS_TBL, DEDUCTION_TBL, and a
-- guarded-but-never-extracted GARN_RULE_TBL). Payroll rules in NA
-- Payroll live across roughly seventy configuration tables — tax
-- setup, earnings programs, deduction classes, subsets, garnishment
-- rules, retro pay, balance IDs, and the GL account-code mapping.
-- Extracting "the payroll config" without these produces a design
-- workshop where nobody can answer why a deduction behaves as it does.
--
-- Sensitivity: LOW. No employee payroll results are extracted — no
-- PS_PAY_EARNINGS, PS_PAY_CHECK, PS_PAY_DEDUCTION, PS_PAY_TAX rows.
-- Only the rules, plus aggregates.
-- ============================================================

-- ------------------------------------------------------------
-- 3b.1 Guard + generate. Run this, then run its output.
-- ------------------------------------------------------------
WITH anchors AS (
  -- Pay structure -------------------------------------------------
  SELECT 'PAYGROUP_TBL'      AS RECNAME, 'Pay groups'                       AS PURPOSE FROM DUAL UNION ALL
  SELECT 'PAY_CALENDAR'            , 'Pay calendars — the payroll cycle'         FROM DUAL UNION ALL
  SELECT 'PAY_CALENDAR_RUN'        , 'Calendar run IDs'                          FROM DUAL UNION ALL
  SELECT 'BALANCE_ID_TBL'          , 'Balance IDs (calendar vs fiscal)'          FROM DUAL UNION ALL
  SELECT 'BAL_ID_YR_TBL'           , 'Balance year definitions'                  FROM DUAL UNION ALL
  SELECT 'PAY_MESSAGE_TBL'         , 'Payroll message catalogue'                 FROM DUAL UNION ALL
  SELECT 'PAY_FORM_TBL'            , 'Cheque/advice form definitions'            FROM DUAL UNION ALL
  -- Earnings ------------------------------------------------------
  SELECT 'EARNINGS_TBL'            , 'Earnings codes — core rule set'            FROM DUAL UNION ALL
  SELECT 'ERNCD_TBL'               , 'Earnings code descriptions'                FROM DUAL UNION ALL
  SELECT 'EARNS_PROGRAM_TBL'       , 'Earnings programs'                         FROM DUAL UNION ALL
  SELECT 'EARNS_PROG_DTL'          , 'Earnings program detail'                   FROM DUAL UNION ALL
  SELECT 'SPCL_EARNS_TBL'          , 'Special accumulators'                      FROM DUAL UNION ALL
  SELECT 'SHIFT_TBL'               , 'Shift differentials'                       FROM DUAL UNION ALL
  SELECT 'HOLIDAY_SCHED_TBL'       , 'Holiday schedules'                         FROM DUAL UNION ALL
  SELECT 'HOLIDAY_DATE'            , 'Holiday dates'                             FROM DUAL UNION ALL
  -- Deductions ----------------------------------------------------
  SELECT 'DEDUCTION_TBL'           , 'Deduction codes — core rule set'           FROM DUAL UNION ALL
  SELECT 'DEDUCTION_CLASS'         , 'Deduction classes (before/after tax)'      FROM DUAL UNION ALL
  SELECT 'GENL_DEDCD'              , 'General deduction codes'                   FROM DUAL UNION ALL
  SELECT 'GENL_DED_FREQ'           , 'General deduction frequencies'             FROM DUAL UNION ALL
  SELECT 'DED_SUBSET_TBL'          , 'Deduction subsets'                         FROM DUAL UNION ALL
  SELECT 'DED_SUBSET_DTL'          , 'Deduction subset detail'                   FROM DUAL UNION ALL
  -- Garnishments --------------------------------------------------
  SELECT 'GARN_RULE_TBL'           , 'Garnishment rules (v1 guarded, never got)' FROM DUAL UNION ALL
  SELECT 'GARN_EXEMPT_TBL'         , 'Garnishment exemptions'                    FROM DUAL UNION ALL
  SELECT 'GARN_PRORATE_TBL'        , 'Garnishment proration'                     FROM DUAL UNION ALL
  SELECT 'GARN_LAW_TBL'            , 'Garnishment law codes'                     FROM DUAL UNION ALL
  -- Tax -----------------------------------------------------------
  SELECT 'FED_TAX_TBL'             , 'Federal tax rates'                         FROM DUAL UNION ALL
  SELECT 'STATE_TAX_TBL'           , 'State tax rates'                           FROM DUAL UNION ALL
  SELECT 'LOCAL_TAX_TBL'           , 'Local tax rates'                           FROM DUAL UNION ALL
  SELECT 'LOCAL_TAX_TBL2'          , 'Local tax detail'                          FROM DUAL UNION ALL
  SELECT 'STATE_NAMES_TBL'         , 'State/jurisdiction names'                  FROM DUAL UNION ALL
  SELECT 'TAX_LOCATION_TBL'        , 'Tax locations'                             FROM DUAL UNION ALL
  SELECT 'TAX_LOCATION_TBL1'       , 'Tax location detail'                       FROM DUAL UNION ALL
  SELECT 'COMPANY_TAX_TBL'         , 'Company tax IDs / EINs'                    FROM DUAL UNION ALL
  SELECT 'CO_STATE_TAX_TBL'        , 'Company state tax setup'                   FROM DUAL UNION ALL
  SELECT 'CO_LOCAL_TAX_TBL'        , 'Company local tax setup'                   FROM DUAL UNION ALL
  SELECT 'TAXFORM_TBL'             , 'Tax form definitions'                      FROM DUAL UNION ALL
  SELECT 'TAXFORM_BOX'             , 'Tax form box mapping (W-2 boxes)'          FROM DUAL UNION ALL
  SELECT 'TAX_BALANCE_CLASS'       , 'Tax balance classes'                       FROM DUAL UNION ALL
  SELECT 'TAXGR_DEFN_TBL'          , 'Tax gross-up definitions'                  FROM DUAL UNION ALL
  -- Retro / adjustments -------------------------------------------
  SELECT 'RETROPAY_RQST'           , 'Retro pay request types'                   FROM DUAL UNION ALL
  SELECT 'RETROPAY_PGM_TBL'        , 'Retro pay programs'                        FROM DUAL UNION ALL
  SELECT 'RETROPAY_ERNCD'          , 'Retro pay earnings mapping'                FROM DUAL UNION ALL
  -- Direct deposit / distribution ---------------------------------
  SELECT 'SRC_BANK'                , 'Source bank accounts (payroll disbursement)' FROM DUAL UNION ALL
  SELECT 'BANK_EC_TBL'             , 'Bank electronic commerce setup'            FROM DUAL UNION ALL
  -- GL interface  ** the finance/HR seam **
  SELECT 'ACCT_CD_TBL'             , 'Payroll account codes → GL chartfields'    FROM DUAL UNION ALL
  SELECT 'DEPT_BUDGET_ERN'         , 'Department budget earnings distribution'   FROM DUAL UNION ALL
  SELECT 'DEPT_BUDGET_DED'         , 'Department budget deduction distribution'  FROM DUAL UNION ALL
  SELECT 'DEPT_BUDGET_TAX'         , 'Department budget tax distribution'        FROM DUAL UNION ALL
  SELECT 'DEPT_BUDGET_HDR'         , 'Department budget header'                  FROM DUAL UNION ALL
  SELECT 'INSTALLATION_PY'         , 'Payroll installation options'              FROM DUAL
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
-- 3b.2 PAYROLL–GL SEAM  ** highest-value single query in this file **
-- ACCT_CD_TBL maps every payroll account code to a full FSCM chartfield
-- string. It is the contract between HR and Finance, it is nearly always
-- undocumented, and it is the thing most likely to be discovered late.
-- ------------------------------------------------------------
SELECT SETID, ACCT_CD, EFFDT, EFF_STATUS, DESCR,
       BUSINESS_UNIT_GL, ACCOUNT, DEPTID, FUND_CODE, PROGRAM_CODE,
       CLASS_FLD, PROJECT_ID, OPERATING_UNIT, CHARTFIELD1, CHARTFIELD2, CHARTFIELD3
  FROM PS_ACCT_CD_TBL
 ORDER BY SETID, ACCT_CD, EFFDT;
-- Column list varies with the site's chartfield configuration. If a
-- column is rejected, list the real ones:
--   SELECT FIELDNAME FROM PSRECFIELDDB WHERE RECNAME='ACCT_CD_TBL' ORDER BY FIELDNUM;

-- 3b.2b Orphan check — payroll account codes whose GL chartfields do not
-- exist in FSCM. Run the two halves on their own instances and compare
-- in Databricks; a non-empty result is a live data-quality issue AND a
-- cutover risk. Half one (HCM):
SELECT DISTINCT BUSINESS_UNIT_GL, ACCOUNT, DEPTID, FUND_CODE
  FROM PS_ACCT_CD_TBL WHERE EFF_STATUS = 'A';
-- Half two runs on FSCM: see 03d §3d.6.

-- ------------------------------------------------------------
-- 3b.3 Earnings and deduction rule profile — readable rule summary
-- ------------------------------------------------------------
SELECT e.ERNCD, e.EFFDT, e.EFF_STATUS, e.DESCR,
       e.EARN_TYPE, e.PAYMENT_TYPE, e.ADD_GROSS, e.SUBJECT_FWT,
       e.SUBJECT_FICA, e.SUBJECT_FUT, e.MAINT_BALANCES, e.HOURS_ONLY,
       e.AMOUNT_ONLY, e.MULT_FACTOR, e.RATE_MULTIPLIER
  FROM PS_EARNINGS_TBL e
 ORDER BY e.ERNCD, e.EFFDT;

SELECT d.DEDCD, d.PLAN_TYPE, d.EFFDT, d.EFF_STATUS, d.DESCR,
       d.DED_PRIORITY, d.DED_PARTIAL_ALLOWED, d.DED_ARREARS_ALLOWED,
       d.DED_SUBSET_ID
  FROM PS_DEDUCTION_TBL d
 ORDER BY d.PLAN_TYPE, d.DEDCD, d.EFFDT;
-- Column availability varies by release; trim any the parser rejects.

-- ------------------------------------------------------------
-- 3b.4 WHAT IS ACTUALLY IN USE — aggregates over payroll results.
-- No EMPLID, no amounts per person. This separates the earnings and
-- deduction codes that matter from the hundreds that are dormant.
-- ------------------------------------------------------------
SELECT ERNCD, COUNT(*) AS EARNINGS_LINES,
       MIN(PAY_END_DT) AS FIRST_PERIOD, MAX(PAY_END_DT) AS LAST_PERIOD
  FROM PS_PAY_EARNINGS pe
  JOIN PS_PAY_CHECK   pc ON pc.COMPANY = pe.COMPANY
                        AND pc.PAYGROUP = pe.PAYGROUP
                        AND pc.PAY_END_DT = pe.PAY_END_DT
 GROUP BY ERNCD ORDER BY 2 DESC;
-- If the join is awkward on your release, the simpler form is enough:
--   SELECT ERNCD, COUNT(*) FROM PS_PAY_EARNINGS GROUP BY ERNCD;

SELECT DEDCD, PLAN_TYPE, COUNT(*) AS DEDUCTION_LINES
  FROM PS_PAY_DEDUCTION GROUP BY DEDCD, PLAN_TYPE ORDER BY 3 DESC;

-- 3b.4b Dormant configuration — codes defined but never used.
-- Direct input to "do not migrate this".
SELECT e.ERNCD, e.DESCR, MAX(e.EFFDT) AS LATEST_EFFDT
  FROM PS_EARNINGS_TBL e
 WHERE NOT EXISTS (SELECT 1 FROM PS_PAY_EARNINGS p WHERE p.ERNCD = e.ERNCD)
 GROUP BY e.ERNCD, e.DESCR ORDER BY e.ERNCD;

-- ------------------------------------------------------------
-- 3b.5 Payroll cycle profile — how many payrolls, how often, how big
-- ------------------------------------------------------------
SELECT c.COMPANY, c.PAYGROUP, p.PAY_FREQUENCY, COUNT(*) AS CALENDARS,
       MIN(c.PAY_END_DT) AS EARLIEST, MAX(c.PAY_END_DT) AS LATEST
  FROM PS_PAY_CALENDAR c
  LEFT JOIN PS_PAYGROUP_TBL p ON p.COMPANY = c.COMPANY AND p.PAYGROUP = c.PAYGROUP
 GROUP BY c.COMPANY, c.PAYGROUP, p.PAY_FREQUENCY
 ORDER BY 1,2;

-- ------------------------------------------------------------
-- 3b.6 Payroll batch estate — the processes that run the payroll
-- Cross-reference with Pack 4 usage to build the payroll run book.
-- ------------------------------------------------------------
SELECT PRCSNAME, PRCSTYPE, DESCR, OBJECTOWNERID, LASTUPDOPRID, LASTUPDDTTM
  FROM PSPRCSDEFN
 WHERE OBJECTOWNERID IN ('PY','PA','BN','TL')
    OR PRCSNAME LIKE 'PSP%'      -- delivered NA Payroll COBOL/SQR family
    OR PRCSNAME LIKE 'PAY%'
    OR PRCSNAME LIKE 'TAX%'
 ORDER BY OBJECTOWNERID, PRCSNAME;
