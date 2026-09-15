-- ============================================================
-- 03g_anchors_fscm_kk_comboedit.sql  (KIT v2) — NEW FILE, run on FSCM
-- Commitment Control (budget checking), ChartField combination edits,
-- and Journal Generator. Absent from v1 in its entirety.
--
-- Why this matters: in a public-sector or higher-ed institution,
-- Commitment Control IS the spending control framework. Every
-- requisition, PO and voucher passes through it. A target-ERP design
-- that has not seen the KK ledger and rule configuration will
-- rediscover it during UAT at considerable cost.
--
-- Sensitivity: LOW (configuration and aggregates).
-- ============================================================

-- ------------------------------------------------------------
-- 3g.1 Guard + generate
-- ------------------------------------------------------------
WITH anchors AS (
  -- Commitment Control --------------------------------------------
  SELECT 'KK_BUDGET_TYPE'    AS RECNAME, 'Budget types'                     AS PURPOSE FROM DUAL UNION ALL
  SELECT 'KK_SUBTYPE'              , 'Budget subtypes'                           FROM DUAL UNION ALL
  SELECT 'KK_BD_DEFN'              , 'Control budget definitions — the core rule' FROM DUAL UNION ALL
  SELECT 'KK_BD_DEFN_CF'           , 'Budget definition chartfields (key structure)' FROM DUAL UNION ALL
  SELECT 'KK_BD_DEFN_TL'           , 'Budget definition translations/rules'      FROM DUAL UNION ALL
  SELECT 'KK_BUDG_ATTRIB'          , 'Budget attributes'                         FROM DUAL UNION ALL
  SELECT 'KK_SOURCE_TRAN'          , 'Source transaction definitions'            FROM DUAL UNION ALL
  SELECT 'KK_SOURCE_HDR'           , 'Source transaction headers'                FROM DUAL UNION ALL
  SELECT 'KK_REF_DATA_TBL'         , 'KK reference data'                         FROM DUAL UNION ALL
  SELECT 'KK_EXCPTN_OVER'          , 'Budget exception override rules'           FROM DUAL UNION ALL
  SELECT 'KK_CLOSE_RULE'           , 'Budget close rules'                        FROM DUAL UNION ALL
  SELECT 'KK_CLOSE_SET'            , 'Budget close sets'                         FROM DUAL UNION ALL
  SELECT 'KK_INSTALLATION'         , 'KK installation options'                   FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_KK'         , 'KK business unit options'                  FROM DUAL UNION ALL
  -- ChartField combination edits ----------------------------------
  SELECT 'COMBO_RULE_TBL'          , 'Combo edit rules (v1 guarded, never got)'  FROM DUAL UNION ALL
  SELECT 'COMBO_RULE_DEFN'         , 'Combo rule definitions'                    FROM DUAL UNION ALL
  SELECT 'COMBO_GROUP_TBL'         , 'Combo groups'                              FROM DUAL UNION ALL
  SELECT 'COMBO_GRP_RULE'          , 'Combo group to rule mapping'               FROM DUAL UNION ALL
  SELECT 'COMBO_SEL_TBL'           , 'Combo selection criteria'                  FROM DUAL UNION ALL
  SELECT 'COMBO_DATA_TBL'          , 'Combo valid-value data'                    FROM DUAL UNION ALL
  SELECT 'COMBO_BU_TBL'            , 'Combo edit by business unit'               FROM DUAL UNION ALL
  SELECT 'COMBO_LEDGER_TBL'        , 'Combo edit by ledger'                      FROM DUAL UNION ALL
  -- Journal Generator ---------------------------------------------
  SELECT 'JRNLGEN_APPL_ID'         , 'Journal generator templates'               FROM DUAL UNION ALL
  SELECT 'JRNLGEN_APPL_CF'         , 'Journal generator chartfield mapping'      FROM DUAL UNION ALL
  SELECT 'ACCT_ENTRY_TMPL'         , 'Accounting entry templates'                FROM DUAL UNION ALL
  SELECT 'ACCTG_TMPL_TBL'          , 'Accounting templates (alt name)'           FROM DUAL UNION ALL
  SELECT 'JRNL_TMPLT_TBL'          , 'Journal entry templates'                   FROM DUAL
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
-- 3g.2 CONTROL BUDGET PROFILE  ** the deliverable **
-- One row per control budget: what it controls, at what chartfield
-- level, with what tolerance. This is the spending-control model.
-- ------------------------------------------------------------
SELECT b.BUSINESS_UNIT, b.LEDGER_GROUP, b.KK_BUDGET_TYPE, b.EFFDT,
       b.DESCR, b.KK_ENTRY_EVENT, b.KK_TOLERANCE_PCT, b.KK_TOLERANCE_AMT,
       b.BUDGET_PERIOD_TYPE, b.KK_STAT_BUD_OPT
  FROM PS_KK_BD_DEFN b
 ORDER BY b.BUSINESS_UNIT, b.LEDGER_GROUP, b.EFFDT;
-- Column names drift between 9.0 and 9.2. If a column is rejected:
--   SELECT FIELDNAME FROM PSRECFIELDDB WHERE RECNAME='KK_BD_DEFN' ORDER BY FIELDNUM;

-- 3g.2b Budget key structure — which chartfields each budget controls on
SELECT BUSINESS_UNIT, LEDGER_GROUP, EFFDT, FIELDNAME, KK_KEY_TYPE, TRANSLATE_TREE
  FROM PS_KK_BD_DEFN_CF
 ORDER BY BUSINESS_UNIT, LEDGER_GROUP, EFFDT, FIELDNAME;
-- TRANSLATE_TREE names the tree used to roll transactions up to budget
-- level. Those trees are extracted in 03i — cross-reference them; a
-- budget tree is load-bearing config, not reporting convenience.

-- ------------------------------------------------------------
-- 3g.3 Source transactions — what gets budget-checked
-- ------------------------------------------------------------
SELECT KK_SOURCE_TRAN, DESCR, KK_TRAN_TYPE, KK_AMOUNT_TYPE
  FROM PS_KK_SOURCE_TRAN ORDER BY KK_SOURCE_TRAN;

-- ------------------------------------------------------------
-- 3g.4 Budget exception profile — where the controls actually bite.
-- Aggregate only; no transaction detail leaves the system.
-- This is unusually good evidence for design: it shows which controls
-- generate real friction today.
-- ------------------------------------------------------------
SELECT BUSINESS_UNIT, KK_SOURCE_TRAN, KK_EXCPTN_TYPE, COUNT(*) AS EXCEPTIONS
  FROM PS_KK_EXCPTN_TBL
 GROUP BY BUSINESS_UNIT, KK_SOURCE_TRAN, KK_EXCPTN_TYPE
 ORDER BY 4 DESC;
-- Table name varies (PS_KK_EXCPTN_TBL / PS_KK_EXCPTN_LN). Use whichever
-- the 00_discovery PS_KK_% scan reports.

-- ------------------------------------------------------------
-- 3g.5 Combo edit rule inventory — readable
-- Every rule here is a validation the target ERP must reproduce or a
-- control the institution consciously decides to drop.
-- ------------------------------------------------------------
SELECT r.SETID, r.COMBO_RULE, r.EFFDT, r.EFF_STATUS, r.DESCR,
       g.COMBO_GROUP, s.FIELDNAME AS RULE_FIELD
  FROM PS_COMBO_RULE_TBL r
  LEFT JOIN PS_COMBO_GRP_RULE g ON g.SETID = r.SETID AND g.COMBO_RULE = r.COMBO_RULE
  LEFT JOIN PS_COMBO_SEL_TBL  s ON s.SETID = r.SETID AND s.COMBO_RULE = r.COMBO_RULE
 ORDER BY r.SETID, r.COMBO_RULE, r.EFFDT;

-- 3g.5b Combo rule scale — how many valid combinations are enumerated
SELECT SETID, COMBO_RULE, COUNT(*) AS VALID_COMBINATIONS
  FROM PS_COMBO_DATA_TBL GROUP BY SETID, COMBO_RULE ORDER BY 3 DESC;

-- ------------------------------------------------------------
-- 3g.6 Journal generator map — which subsystems post to which ledger
-- The other half of the integration picture from 02d §2d.6.
-- ------------------------------------------------------------
SELECT JRNLGEN_APPL_ID, DESCR, SOURCE, LEDGER_GROUP, BUSINESS_UNIT_GL,
       JRNL_TMPLT_ID, SUMMARIZE_OPT
  FROM PS_JRNLGEN_APPL_ID ORDER BY JRNLGEN_APPL_ID;
