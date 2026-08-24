-- ============================================================
-- 03d_anchors_fscm_core.sql  (KIT v2) — run on the FSCM instance
-- General Ledger core: chartfields, ledgers, calendars, business units.
-- Procure-to-pay is 03e; AM/PC/GM/EX/IN is 03f; Commitment Control,
-- combo edits and journal generator are 03g.
--
-- v1 guarded 34 FSCM tables and extracted 13. COMBO_RULE_TBL, PROJECT,
-- CHARTFIELD1/2/3_TBL, CAL_DETP_TBL, ALTACCT_TBL, PRODUCT_TBL,
-- ORIGIN_TBL, CATEGORY_TBL, UNSPSC_TBL, SHIPTO_TBL, ITM_CAT_TBL,
-- MASTER_ITEM_TBL, BU_ITEMS_INV, INSTALLATION_FS and the AP/AR/PM/PO
-- business unit tables were all guarded and then dropped.
-- As in 03a, the guard now generates the extract statements.
-- ============================================================

-- ------------------------------------------------------------
-- 3d.1 Guard + generate
-- ------------------------------------------------------------
WITH anchors AS (
  -- Installation & business units ---------------------------------
  SELECT 'INSTALLATION_FS'  AS RECNAME, 'FSCM installation options'         AS PURPOSE FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_FS'         , 'FS business units (the master list)'       FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_GL'         , 'GL business units'                         FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_AP'         , 'AP business units'                         FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_AR'         , 'AR business units'                         FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_BI'         , 'Billing business units'                    FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_PO'         , 'Purchasing business units'                 FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_PM'         , 'Project business units'                    FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_IN'         , 'Inventory business units'                  FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_AM'         , 'Asset Management business units'           FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_EX'         , 'Expenses business units'                   FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_GM'         , 'Grants business units'                     FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_OPT_GL'         , 'GL business unit options'                  FROM DUAL UNION ALL
  -- Chartfields ---------------------------------------------------
  SELECT 'GL_ACCOUNT_TBL'          , 'Account chartfield'                        FROM DUAL UNION ALL
  SELECT 'ALTACCT_TBL'             , 'Alternate account'                         FROM DUAL UNION ALL
  SELECT 'DEPT_TBL'                , 'Department chartfield (FSCM side)'         FROM DUAL UNION ALL
  SELECT 'FUND_TBL'                , 'Fund chartfield'                           FROM DUAL UNION ALL
  SELECT 'PROGRAM_TBL'             , 'Program chartfield'                        FROM DUAL UNION ALL
  SELECT 'CLASS_CF_TBL'            , 'Class chartfield'                          FROM DUAL UNION ALL
  SELECT 'OPER_UNIT_TBL'           , 'Operating unit chartfield'                 FROM DUAL UNION ALL
  SELECT 'BUD_REF_TBL'             , 'Budget reference chartfield'               FROM DUAL UNION ALL
  SELECT 'PRODUCT_TBL'             , 'Product chartfield'                        FROM DUAL UNION ALL
  SELECT 'CHARTFIELD1_TBL'         , 'Chartfield1'                               FROM DUAL UNION ALL
  SELECT 'CHARTFIELD2_TBL'         , 'Chartfield2'                               FROM DUAL UNION ALL
  SELECT 'CHARTFIELD3_TBL'         , 'Chartfield3'                               FROM DUAL UNION ALL
  SELECT 'PROJECT'                 , 'Project chartfield / project master'       FROM DUAL UNION ALL
  SELECT 'SPEEDTYP_TBL'            , 'Speedtypes (chartfield shortcuts)'         FROM DUAL UNION ALL
  SELECT 'SPEEDTYPE_KEY'           , 'Speedtype detail'                          FROM DUAL UNION ALL
  SELECT 'CF_ATTRIB_TBL'           , 'Chartfield attributes'                     FROM DUAL UNION ALL
  SELECT 'CF_VALUE_TBL'            , 'Chartfield attribute values'               FROM DUAL UNION ALL
  -- Ledgers & calendars -------------------------------------------
  SELECT 'LED_DEFN_TBL'            , 'Ledger definitions'                        FROM DUAL UNION ALL
  SELECT 'LED_GRP_TBL'             , 'Ledger groups'                             FROM DUAL UNION ALL
  SELECT 'LED_TMPLT_TBL'           , 'Ledger templates'                          FROM DUAL UNION ALL
  SELECT 'LEDGER_SETS'             , 'Ledger sets'                               FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_LED_GRP'        , 'BU-to-ledger-group assignment'             FROM DUAL UNION ALL
  SELECT 'CAL_DEFN_TBL'            , 'Calendar definitions'                      FROM DUAL UNION ALL
  SELECT 'CAL_DETP_TBL'            , 'Detail period calendar'                    FROM DUAL UNION ALL
  SELECT 'CAL_SUMP_TBL'            , 'Summary period calendar'                   FROM DUAL UNION ALL
  SELECT 'CAL_BUSDAY_TBL'          , 'Business day calendar'                     FROM DUAL UNION ALL
  SELECT 'OPEN_PERIOD'             , 'Open period control — close calendar'      FROM DUAL UNION ALL
  -- Journals & sources --------------------------------------------
  SELECT 'JRNL_SOURCE_TBL'         , 'Journal sources — feeder fingerprints'     FROM DUAL UNION ALL
  SELECT 'JRNL_CLASS_TBL'          , 'Journal classes'                           FROM DUAL UNION ALL
  SELECT 'DOC_TYPE_TBL'            , 'Document types'                            FROM DUAL UNION ALL
  SELECT 'JRNL_TMPLT_TBL'          , 'Journal entry templates'                   FROM DUAL UNION ALL
  SELECT 'STAT_CODE_TBL'           , 'Statistical codes'                         FROM DUAL UNION ALL
  SELECT 'STAT_ACCT_TBL'           , 'Statistical accounts'                      FROM DUAL UNION ALL
  -- Currency & rates ----------------------------------------------
  SELECT 'CURRENCY_CD_TBL'         , 'Currencies'                                FROM DUAL UNION ALL
  SELECT 'RT_TYPE_TBL'             , 'Rate types'                                FROM DUAL UNION ALL
  SELECT 'RT_INDEX_TBL'            , 'Rate indexes'                              FROM DUAL UNION ALL
  SELECT 'CURR_RATE_TBL'           , 'Exchange rates'                            FROM DUAL UNION ALL
  -- Trees / consolidation -----------------------------------------
  SELECT 'CONSOL_LEDGER'           , 'Consolidation ledger setup'                FROM DUAL UNION ALL
  SELECT 'ALLOC_STEP_TBL'          , 'Allocation steps'                          FROM DUAL UNION ALL
  SELECT 'ALLOC_GROUP_TBL'         , 'Allocation groups'                         FROM DUAL
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
-- 3d.2 CHARTFIELD MODEL PROFILE  ** new in v2 **
-- Which chartfields are actually turned on, and how many active values
-- each carries. This one result set frames the entire target-ERP
-- chart-of-accounts design conversation.
-- ------------------------------------------------------------
SELECT 'ACCOUNT'        AS CHARTFIELD, COUNT(*) AS ACTIVE_VALUES FROM PS_GL_ACCOUNT_TBL WHERE EFF_STATUS='A' UNION ALL
SELECT 'ALTACCT'             , COUNT(*) FROM PS_ALTACCT_TBL     WHERE EFF_STATUS='A' UNION ALL
SELECT 'DEPTID'              , COUNT(*) FROM PS_DEPT_TBL        WHERE EFF_STATUS='A' UNION ALL
SELECT 'FUND_CODE'           , COUNT(*) FROM PS_FUND_TBL        WHERE EFF_STATUS='A' UNION ALL
SELECT 'PROGRAM_CODE'        , COUNT(*) FROM PS_PROGRAM_TBL     WHERE EFF_STATUS='A' UNION ALL
SELECT 'CLASS_FLD'           , COUNT(*) FROM PS_CLASS_CF_TBL    WHERE EFF_STATUS='A' UNION ALL
SELECT 'OPERATING_UNIT'      , COUNT(*) FROM PS_OPER_UNIT_TBL   WHERE EFF_STATUS='A' UNION ALL
SELECT 'BUDGET_REF'          , COUNT(*) FROM PS_BUD_REF_TBL     WHERE EFF_STATUS='A' UNION ALL
SELECT 'PRODUCT'             , COUNT(*) FROM PS_PRODUCT_TBL     WHERE EFF_STATUS='A' UNION ALL
SELECT 'CHARTFIELD1'         , COUNT(*) FROM PS_CHARTFIELD1_TBL WHERE EFF_STATUS='A' UNION ALL
SELECT 'CHARTFIELD2'         , COUNT(*) FROM PS_CHARTFIELD2_TBL WHERE EFF_STATUS='A' UNION ALL
SELECT 'CHARTFIELD3'         , COUNT(*) FROM PS_CHARTFIELD3_TBL WHERE EFF_STATUS='A' UNION ALL
SELECT 'PROJECT_ID'          , COUNT(*) FROM PS_PROJECT         WHERE EFF_STATUS='A';
-- Drop any branch whose table the guard reported ABSENT.

-- 3d.2b Which chartfields are actually POPULATED in the ledger — the
-- difference between "configured" and "used" in the chart of accounts.
SELECT COUNT(*) AS LEDGER_ROWS,
       COUNT(DISTINCT ACCOUNT)        AS DISTINCT_ACCOUNTS,
       COUNT(DISTINCT DEPTID)         AS DISTINCT_DEPTS,
       COUNT(DISTINCT FUND_CODE)      AS DISTINCT_FUNDS,
       COUNT(DISTINCT PROGRAM_CODE)   AS DISTINCT_PROGRAMS,
       COUNT(DISTINCT CLASS_FLD)      AS DISTINCT_CLASSES,
       COUNT(DISTINCT PROJECT_ID)     AS DISTINCT_PROJECTS,
       COUNT(DISTINCT OPERATING_UNIT) AS DISTINCT_OPER_UNITS,
       COUNT(DISTINCT CHARTFIELD1)    AS DISTINCT_CF1,
       COUNT(DISTINCT CHARTFIELD2)    AS DISTINCT_CF2,
       COUNT(DISTINCT CHARTFIELD3)    AS DISTINCT_CF3
  FROM PS_LEDGER;
-- Aggregate only — no ledger balances leave the system.

-- ------------------------------------------------------------
-- 3d.3 Accounting calendar and close profile
-- ------------------------------------------------------------
SELECT SETID, CALENDAR_ID, FISCAL_YEAR, ACCOUNTING_PERIOD,
       BEGIN_DT, END_DT, PERIOD_NAME
  FROM PS_CAL_DETP_TBL ORDER BY SETID, CALENDAR_ID, FISCAL_YEAR, ACCOUNTING_PERIOD;

SELECT * FROM PS_OPEN_PERIOD ORDER BY SETID, BUSINESS_UNIT, FISCAL_YEAR, ACCOUNTING_PERIOD;

-- ------------------------------------------------------------
-- 3d.4 Ledger volume by year — conversion sizing, aggregate only
-- ------------------------------------------------------------
SELECT LEDGER, BUSINESS_UNIT, FISCAL_YEAR, COUNT(*) AS LEDGER_ROWS
  FROM PS_LEDGER GROUP BY LEDGER, BUSINESS_UNIT, FISCAL_YEAR
 ORDER BY FISCAL_YEAR DESC, LEDGER_ROWS DESC;

-- ------------------------------------------------------------
-- 3d.5 Journal source activity — which feeders are alive
-- ------------------------------------------------------------
SELECT h.SOURCE, s.DESCR, h.FISCAL_YEAR, COUNT(*) AS JOURNALS
  FROM PS_JRNL_HEADER h
  LEFT JOIN PS_JRNL_SOURCE_TBL s ON s.SOURCE = h.SOURCE
 GROUP BY h.SOURCE, s.DESCR, h.FISCAL_YEAR
 ORDER BY h.FISCAL_YEAR DESC, JOURNALS DESC;

-- ------------------------------------------------------------
-- 3d.6 PAYROLL–GL RECONCILIATION, FSCM half  ** pairs with 03b §3b.2b **
-- Extract the valid chartfield combinations so the HCM payroll account
-- codes can be validated against them in Databricks.
-- ------------------------------------------------------------
SELECT SETID, ACCOUNT, EFF_STATUS, DESCR, ACCOUNT_TYPE
  FROM PS_GL_ACCOUNT_TBL WHERE EFF_STATUS = 'A';
SELECT SETID, DEPTID, EFF_STATUS, DESCR FROM PS_DEPT_TBL WHERE EFF_STATUS = 'A';
SELECT SETID, FUND_CODE, EFF_STATUS, DESCR FROM PS_FUND_TBL WHERE EFF_STATUS = 'A';
