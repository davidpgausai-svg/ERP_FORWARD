-- ============================================================
-- 03a_anchors_hcm.sql — HCM anchor setup tables (run on HCM instance)
-- The generator (03) finds everything; these anchors are the tables
-- the ERP program will ask about FIRST. Verify existence, then extract.
-- ============================================================

-- Existence guard — extract only names this returns:
SELECT RECNAME FROM PSRECDEFN WHERE RECNAME IN (
 'COMPANY_TBL','BUS_UNIT_TBL_HR','DEPT_TBL','LOCATION_TBL','JOBCODE_TBL',
 'JOB_FAMILY_TBL','POSITION_DATA','SAL_PLAN_TBL','SAL_GRADE_TBL','SAL_STEP_TBL',
 'COMP_RATECD_TBL','PAYGROUP_TBL','PAY_CALENDAR','EARNINGS_TBL','DEDUCTION_TBL',
 'GARN_RULE_TBL','BEN_DEFN_PGM','BEN_DEFN_PLAN','ACTION_TBL','ACTN_REASON_TBL',
 'UNION_TBL','HOLIDAY_SCHED_TBL','SHIFT_TBL','ABS_TYPE_TBL','SCH_DEFN_TBL');

-- Then, for each existing name:
SELECT * FROM PS_COMPANY_TBL;
SELECT * FROM PS_BUS_UNIT_TBL_HR;
SELECT * FROM PS_DEPT_TBL;
SELECT * FROM PS_LOCATION_TBL;
SELECT * FROM PS_JOBCODE_TBL;
SELECT * FROM PS_SAL_PLAN_TBL;
SELECT * FROM PS_SAL_GRADE_TBL;
SELECT * FROM PS_SAL_STEP_TBL;
SELECT * FROM PS_PAYGROUP_TBL;
SELECT * FROM PS_PAY_CALENDAR;
SELECT * FROM PS_EARNINGS_TBL;
SELECT * FROM PS_DEDUCTION_TBL;
SELECT * FROM PS_BEN_DEFN_PGM;
SELECT * FROM PS_ACTION_TBL;
SELECT * FROM PS_ACTN_REASON_TBL;
SELECT * FROM PS_UNION_TBL;          -- bargaining units — CBA discovery anchor
-- POSITION_DATA is position master (org design), no person data:
SELECT * FROM PS_POSITION_DATA;
