-- ============================================================
-- 03c_anchors_campus.sql — Campus Solutions anchors (run on CS instance)
-- Student pillar. Generator (03) is authoritative; verify then extract.
-- ============================================================

SELECT RECNAME FROM PSRECDEFN WHERE RECNAME IN (
 'INSTITUTION_TBL','ACAD_CAREER_TBL','ACAD_PROG_TBL','ACAD_PLAN_TBL',
 'ACAD_SUB_PLN_TBL','ACAD_GROUP_TBL','ACAD_ORG_TBL','SUBJECT_TBL',
 'TERM_TBL','SESSION_TBL','ACAD_CAL_TBL','GRADE_SCHEME_TBL',
 'ITEM_TYPE_TBL','ADM_APPL_CTR_TBL','SRVC_IND_CD_TBL','CHECKLIST_TBL',
 'COMM_CATG_TBL');
-- Student Financials fee/tuition setup varies by config — rely on the
-- 03 generator (OBJECTOWNERID = SF) for the complete SF setup list.

SELECT * FROM PS_INSTITUTION_TBL;
SELECT * FROM PS_ACAD_CAREER_TBL;
SELECT * FROM PS_ACAD_PROG_TBL;
SELECT * FROM PS_ACAD_PLAN_TBL;
SELECT * FROM PS_ACAD_ORG_TBL;       -- academic org structure — maps to HCM departments; crosswalk anchor
SELECT * FROM PS_TERM_TBL;           -- academic calendar — feeds the cutover calendar layers
SELECT * FROM PS_SESSION_TBL;
SELECT * FROM PS_GRADE_SCHEME_TBL;
SELECT * FROM PS_ITEM_TYPE_TBL;      -- student financials item types (charge/credit taxonomy)
SELECT * FROM PS_SRVC_IND_CD_TBL;    -- service indicators (holds) — process-heavy config
SELECT * FROM PS_CHECKLIST_TBL;      -- checklists = student-side workflow definitions
