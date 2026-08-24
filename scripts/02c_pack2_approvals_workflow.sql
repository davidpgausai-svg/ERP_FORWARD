-- ============================================================
-- 02c_pack2_approvals_workflow.sql  (KIT v2) — NEW PACK
-- Approval Workflow Engine (AWE / Approval Framework) CONFIGURED ROUTES.
--
-- v1 handled this with a generator that emitted "SELECT * FROM <every
-- EOAW table>" and no interpretation. That produces the right files but
-- gives the analyst nothing to work with. This pack names the core
-- tables, orders them, and adds the joins that turn them into a
-- readable approval-route inventory — the single highest-value artefact
-- for current-state process mapping in finance and HR.
--
-- Sensitivity: LOW-MODERATE (approver user lists include OPRIDs).
-- ============================================================

-- ------------------------------------------------------------
-- 2c.0 Existence guard — table membership varies by tools release
-- ------------------------------------------------------------
SELECT TABLE_NAME FROM ALL_TABLES
 WHERE TABLE_NAME LIKE 'PS_EOAW%' OR TABLE_NAME LIKE 'PS_EOWF%'
    OR TABLE_NAME LIKE 'PS_APPR%'
 ORDER BY TABLE_NAME;
-- SQL Server: FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' AND ...

-- ------------------------------------------------------------
-- 2c.1 Transaction registry — WHICH business transactions are
-- approval-enabled at all. Start here; everything else hangs off it.
-- ------------------------------------------------------------
SELECT * FROM PS_EOAW_TXN;          -- registered approval transactions
SELECT * FROM PS_EOAW_TXN_LVL;      -- transaction levels, where present
SELECT * FROM PS_EOAW_TXNCOMP;      -- component linkage

-- ------------------------------------------------------------
-- 2c.2 Process definitions, stages, paths, steps — the route itself
-- ------------------------------------------------------------
SELECT * FROM PS_EOAW_PRCS;         -- approval process definitions
SELECT * FROM PS_EOAW_STAGE;        -- stages
SELECT * FROM PS_EOAW_PATH;         -- paths within a stage
SELECT * FROM PS_EOAW_STEP;         -- steps within a path (the approver levels)
SELECT * FROM PS_EOAW_STEP_APPR;    -- step approver config, where present

-- ------------------------------------------------------------
-- 2c.3 Criteria — the conditions that select a route
-- This is where dollar thresholds, business-unit rules and
-- exception routing live. Read these before any design workshop.
-- ------------------------------------------------------------
SELECT * FROM PS_EOAW_CRITERIA;
SELECT * FROM PS_EOAW_CRIT_FLD;     -- criteria field-level detail
SELECT * FROM PS_EOAW_CRIT_APPD;    -- app-defined criteria classes

-- ------------------------------------------------------------
-- 2c.4 User lists — WHO approves
-- Sensitivity: MODERATE. These resolve to OPRIDs, roles, SQL, or
-- application-class logic.
-- ------------------------------------------------------------
SELECT * FROM PS_EOAW_USER_LIST;
SELECT * FROM PS_EOAW_USRLST_DEF;   -- definition detail, where present
SELECT * FROM PS_EOAW_ADMIN;        -- approval administrators

-- ------------------------------------------------------------
-- 2c.5 Notifications — the emails the process actually sends
-- Change management needs this: every one of these is a message
-- that will stop arriving on cutover day.
-- ------------------------------------------------------------
SELECT * FROM PS_EOAW_NOTIFY;
SELECT * FROM PS_EOAWNOTIFYTMPL;    -- templates, where present
SELECT * FROM PSMSGCATDEFN WHERE MESSAGE_SET_NR IN (
  SELECT DISTINCT MESSAGE_SET_NR FROM PS_EOAW_NOTIFY);

-- ------------------------------------------------------------
-- 2c.6 READABLE APPROVAL ROUTE INVENTORY  ** the deliverable **
-- One row per transaction / process / stage / path / step, with the
-- criteria and approver list attached. Export as
-- <instance>_P2C_APPROVAL_ROUTES.csv and hand it straight to the
-- process-mapping workstream.
-- ------------------------------------------------------------
SELECT t.EOAWPRCS_ID,
       t.DESCR                 AS TRANSACTION_DESCR,
       p.EOAWPRCS_ID           AS PROCESS_ID,
       s.EOAWSTAGE_ID          AS STAGE_ID,
       s.DESCR                 AS STAGE_DESCR,
       pa.EOAWPATH_ID          AS PATH_ID,
       pa.DESCR                AS PATH_DESCR,
       pa.EOAWUSERLIST_ID      AS PATH_USER_LIST,
       st.EOAWSTEP_ID          AS STEP_ID,
       st.DESCR                AS STEP_DESCR,
       st.EOAWUSERLIST_ID      AS STEP_USER_LIST,
       st.SELF_APPROVE_SW,
       st.SKIP_SW
  FROM PS_EOAW_TXN   t
  LEFT JOIN PS_EOAW_PRCS  p  ON p.EOAWPRCS_ID  = t.EOAWPRCS_ID
  LEFT JOIN PS_EOAW_STAGE s  ON s.EOAWPRCS_ID  = p.EOAWPRCS_ID
  LEFT JOIN PS_EOAW_PATH  pa ON pa.EOAWPRCS_ID = s.EOAWPRCS_ID
                            AND pa.EOAWSTAGE_ID = s.EOAWSTAGE_ID
  LEFT JOIN PS_EOAW_STEP  st ON st.EOAWPRCS_ID  = pa.EOAWPRCS_ID
                            AND st.EOAWSTAGE_ID = pa.EOAWSTAGE_ID
                            AND st.EOAWPATH_ID  = pa.EOAWPATH_ID
 ORDER BY 1,3,4,6,9;
-- Column names drift across tools releases (8.53 → 8.60). If a column
-- is rejected, check ALL_TAB_COLUMNS for that table and adjust; the
-- join grain (txn → prcs → stage → path → step) is stable.

-- ------------------------------------------------------------
-- 2c.7 Delegation framework — who can approve on someone's behalf
-- Frequently forgotten in target-state role design, always noticed
-- the first time an approver goes on leave after go-live.
-- ------------------------------------------------------------
SELECT RECNAME FROM PSRECDEFN WHERE RECNAME LIKE 'EODL%';
SELECT * FROM PS_EODL_TRAN;         -- delegable transactions
SELECT * FROM PS_EODL_REQUEST;      -- active/expired delegations (MODERATE: user IDs)

-- ------------------------------------------------------------
-- 2c.8 Live approval volumes — is a configured route actually used?
-- Header-level aggregate only. Do NOT export approval instance detail:
-- it references live transactions (vouchers, requisitions, job changes).
-- ------------------------------------------------------------
SELECT EOAWPRCS_ID,
       TRUNC(LASTUPDDTTM,'MM') AS ACTIVITY_MONTH,
       COUNT(*) AS INSTANCES
  FROM PS_EOAW_INST
 GROUP BY EOAWPRCS_ID, TRUNC(LASTUPDDTTM,'MM')
 ORDER BY 1,2;
-- SQL Server: DATEFROMPARTS(YEAR(LASTUPDDTTM),MONTH(LASTUPDDTTM),1)

-- ------------------------------------------------------------
-- 2c.9 Configured-but-dead routes — approval config nobody uses.
-- Straight input to the "do not rebuild this" list.
-- ------------------------------------------------------------
SELECT p.EOAWPRCS_ID, p.DESCR, p.LASTUPDOPRID, p.LASTUPDDTTM
  FROM PS_EOAW_PRCS p
 WHERE NOT EXISTS (SELECT 1 FROM PS_EOAW_INST i
                    WHERE i.EOAWPRCS_ID = p.EOAWPRCS_ID)
 ORDER BY p.EOAWPRCS_ID;
