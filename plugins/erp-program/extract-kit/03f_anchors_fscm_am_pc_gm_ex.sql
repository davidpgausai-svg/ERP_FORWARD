-- ============================================================
-- 03f_anchors_fscm_am_pc_gm_ex.sql  (KIT v2) — NEW FILE, run on FSCM
-- Asset Management, Project Costing, Grants, Travel & Expenses.
--
-- v1's README claimed FSCM coverage including "Projects/Grants/Assets"
-- but the FSCM anchor file contained no AM, PC, GM or EX tables at all.
-- For a higher-ed or public-sector institution, Grants and Projects are
-- often the most rule-heavy part of the finance estate and the hardest
-- to reproduce in a target ERP.
--
-- Sensitivity: LOW (configuration). Award and asset transactional data
-- is excluded; aggregates only.
-- ============================================================

-- ------------------------------------------------------------
-- 3f.1 Guard + generate
-- ------------------------------------------------------------
WITH anchors AS (
  -- Asset Management ----------------------------------------------
  SELECT 'PROFILE_TBL'       AS RECNAME, 'Asset profiles — depreciation defaults' AS PURPOSE FROM DUAL UNION ALL
  SELECT 'ASSET_CLASS_TBL'         , 'Asset classes'                             FROM DUAL UNION ALL
  SELECT 'ASSET_TYPE_TBL'          , 'Asset types'                               FROM DUAL UNION ALL
  SELECT 'ASSET_SUBTYPE_TBL'       , 'Asset subtypes'                            FROM DUAL UNION ALL
  SELECT 'AM_BU_BOOK_TBL'          , 'BU-to-book assignment'                     FROM DUAL UNION ALL
  SELECT 'BOOK_TBL'                , 'Depreciation books'                        FROM DUAL UNION ALL
  SELECT 'DEPR_CONV_TBL'           , 'Depreciation conventions'                  FROM DUAL UNION ALL
  SELECT 'DEPR_SCHED_TBL'          , 'Depreciation schedules'                    FROM DUAL UNION ALL
  SELECT 'COST_TYPE_TBL'           , 'Cost types'                                FROM DUAL UNION ALL
  SELECT 'AM_DIST_TMPL'            , 'Asset accounting entry templates'          FROM DUAL UNION ALL
  SELECT 'ASSET_LOC_TBL'           , 'Asset locations'                           FROM DUAL UNION ALL
  SELECT 'CAP_THRESHOLD'           , 'Capitalisation thresholds'                 FROM DUAL UNION ALL
  SELECT 'INSTALLATION_AM'         , 'AM installation options'                   FROM DUAL UNION ALL
  -- Project Costing -----------------------------------------------
  SELECT 'PROJ_TYPE_TBL'           , 'Project types'                             FROM DUAL UNION ALL
  SELECT 'PROJ_STATUS_TBL'         , 'Project statuses'                          FROM DUAL UNION ALL
  SELECT 'PROJ_ROLE_TBL'           , 'Project roles'                             FROM DUAL UNION ALL
  SELECT 'PC_ANALYSIS_TBL'         , 'Analysis types — the PC transaction taxonomy' FROM DUAL UNION ALL
  SELECT 'PC_AN_GRP_TBL'           , 'Analysis groups'                           FROM DUAL UNION ALL
  SELECT 'PC_SOURCE_TBL'           , 'PC source types'                           FROM DUAL UNION ALL
  SELECT 'PC_CATEGORY_TBL'         , 'PC categories'                             FROM DUAL UNION ALL
  SELECT 'PC_SUB_CAT_TBL'          , 'PC subcategories'                          FROM DUAL UNION ALL
  SELECT 'PC_ACTIVITY_TYPE'        , 'Activity types'                            FROM DUAL UNION ALL
  SELECT 'PC_RATE_SET'             , 'Rate sets (billing/costing rates)'          FROM DUAL UNION ALL
  SELECT 'PC_RATE_DTL'             , 'Rate set detail'                           FROM DUAL UNION ALL
  SELECT 'PC_INT_TMPL'             , 'PC integration templates'                  FROM DUAL UNION ALL
  SELECT 'BUS_UNIT_TBL_PC'         , 'PC business units'                         FROM DUAL UNION ALL
  SELECT 'INSTALLATION_PC'         , 'PC installation options'                   FROM DUAL UNION ALL
  -- Grants --------------------------------------------------------
  SELECT 'SPONSOR_TBL'             , 'Sponsors'                                  FROM DUAL UNION ALL
  SELECT 'GM_AWARD_TYPE'           , 'Award types'                               FROM DUAL UNION ALL
  SELECT 'GM_PURPOSE_TBL'          , 'Award purposes'                            FROM DUAL UNION ALL
  SELECT 'GM_CFDA_TBL'             , 'CFDA / assistance listing codes'           FROM DUAL UNION ALL
  SELECT 'FA_RATE_TBL'             , 'F&A (indirect cost) rates'                 FROM DUAL UNION ALL
  SELECT 'FA_RATE_TYPE'            , 'F&A rate types'                            FROM DUAL UNION ALL
  SELECT 'FA_BASE_TBL'             , 'F&A bases'                                 FROM DUAL UNION ALL
  SELECT 'CST_SHARE_TBL'           , 'Cost sharing setup'                        FROM DUAL UNION ALL
  SELECT 'GM_PROTOCOL_TYPE'        , 'Protocol types (IRB/IACUC)'                FROM DUAL UNION ALL
  SELECT 'INSTALLATION_GM'         , 'Grants installation options'               FROM DUAL UNION ALL
  -- Travel & Expenses ---------------------------------------------
  SELECT 'EX_TYPE_TBL'             , 'Expense types'                             FROM DUAL UNION ALL
  SELECT 'EX_TYPE_DTL'             , 'Expense type detail'                       FROM DUAL UNION ALL
  SELECT 'EX_LOCATION_TBL'         , 'Expense locations'                         FROM DUAL UNION ALL
  SELECT 'EX_LOC_AMT_TBL'          , 'Per-diem / location amounts'               FROM DUAL UNION ALL
  SELECT 'EX_PMNT_TYPE'            , 'Expense payment types'                     FROM DUAL UNION ALL
  SELECT 'EX_APPR_TBL'             , 'Expense approval setup'                    FROM DUAL UNION ALL
  SELECT 'EX_BUS_PURPOSE'          , 'Business purposes'                         FROM DUAL UNION ALL
  SELECT 'EX_ACCTG_TMPL'           , 'Expense accounting templates'              FROM DUAL UNION ALL
  SELECT 'INSTALLATION_EX'         , 'Expenses installation options'             FROM DUAL
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
-- 3f.2 Asset estate profile — aggregate only
-- ------------------------------------------------------------
SELECT BUSINESS_UNIT, ASSET_STATUS, COUNT(*) AS ASSETS
  FROM PS_ASSET GROUP BY BUSINESS_UNIT, ASSET_STATUS ORDER BY 3 DESC;

SELECT BOOK, COUNT(DISTINCT ASSET_ID) AS ASSETS_IN_BOOK
  FROM PS_ASSET_BOOK GROUP BY BOOK ORDER BY 2 DESC;

-- ------------------------------------------------------------
-- 3f.3 Project and award estate profile — aggregate only
-- ------------------------------------------------------------
SELECT BUSINESS_UNIT, PROJECT_TYPE, PROJECT_STATUS, COUNT(*) AS PROJECTS
  FROM PS_PROJECT GROUP BY BUSINESS_UNIT, PROJECT_TYPE, PROJECT_STATUS
 ORDER BY 4 DESC;

SELECT BUSINESS_UNIT, AWARD_TYPE, COUNT(*) AS AWARDS,
       COUNT(DISTINCT SPONSOR_ID) AS SPONSORS
  FROM PS_GM_AWARD GROUP BY BUSINESS_UNIT, AWARD_TYPE ORDER BY 3 DESC;
-- Table name is PS_AWARD on some releases; adjust per the guard output.

-- ------------------------------------------------------------
-- 3f.4 F&A rate configuration — the grants rule most often mis-migrated
-- ------------------------------------------------------------
SELECT SETID, FA_RATE_ID, EFFDT, EFF_STATUS, DESCR, FA_RATE_TYPE, FA_RATE_PCT
  FROM PS_FA_RATE_TBL ORDER BY SETID, FA_RATE_ID, EFFDT;
-- Column names vary; if rejected, list them from PSRECFIELDDB first.

-- ------------------------------------------------------------
-- 3f.5 Expense policy profile — per diem and threshold rules
-- ------------------------------------------------------------
SELECT SETID, EXPENSE_TYPE, EFFDT, EFF_STATUS, DESCR,
       PREPAID_FLG, EXPENSE_TYPE_CATEGORY
  FROM PS_EX_TYPE_TBL ORDER BY SETID, EXPENSE_TYPE, EFFDT;

SELECT SETID, EXPENSE_TYPE, EXPENSE_LOCATION, EFFDT, CURRENCY_CD, MAX_AMOUNT
  FROM PS_EX_LOC_AMT_TBL ORDER BY 1,2,3,4;
