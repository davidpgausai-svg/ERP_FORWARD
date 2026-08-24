-- ============================================================
-- 03i_security_trees.sql  (KIT v2) — WHO CAN DO WHAT + HIERARCHIES
-- Pillar-agnostic. Sensitivity: MODERATE (user IDs) — classify INTERNAL.
--
-- Security is the best process-discovery source in the system: page
-- access by role by department tells you who actually performs each
-- transaction, without a single interview.
--
-- v2 changes vs v1:
--   + process/job security (PSAUTHPRCS, PSPRCSPRFL) — v1 had none, so
--     "who can run payroll" was unanswerable from the v1 extract
--   + query security trees and definition security (PSAUTHOBJ)
--   + PSOPRALIAS (OPRID → EMPLID linkage) for people-to-access joins
--   + TREE VOLUME GUARD — v1's bare SELECT * FROM PSTREENODE/PSTREELEAF
--     is a genuine operational hazard: on a large FSCM instance these
--     run to tens of millions of rows and will fill the export target
--   + effective-dated tree filtering
--   + derived role/access matrices, so the analyst gets answers not tables
-- ============================================================

-- ------------------------------------------------------------
-- 3i.1 Core security model
-- ------------------------------------------------------------
SELECT * FROM PSROLEDEFN;       -- roles
SELECT * FROM PSCLASSDEFN;      -- permission lists
SELECT * FROM PSROLECLASS;      -- role → permission list
SELECT * FROM PSROLEUSER;       -- user → role
SELECT * FROM PSAUTHITEM;       -- permission list → menu/component/page access
SELECT * FROM PSAUTHBUSCOMP;    -- component interface access  ** new in v2 **
SELECT * FROM PSAUTHSIGNON;     -- sign-on times, where present
SELECT * FROM PSAUTHOBJ;        -- ** new ** definition security (App Designer)

-- User accounts — explicit column list, no password hashes, no tokens
SELECT OPRID, OPRDEFNDESC, EMPLID, OPRCLASS, ROWSECCLASS,
       ACCTLOCK, FAILEDLOGINS, LASTSIGNONDTTM, LASTUPDDTTM,
       OPRTYPE, DEFAULTNAVHP
  FROM PSOPRDEFN;
SELECT * FROM PSOPRALIAS;       -- ** new ** OPRID → EMPLID/vendor alias linkage

-- ------------------------------------------------------------
-- 3i.2 PROCESS AND JOB SECURITY  ** entirely missing from v1 **
-- Batch authority is separate from page authority in PeopleSoft. Without
-- these tables you cannot answer "who can run the payroll", "who can
-- post journals", or "who can void a payment" — three questions every
-- ERP security design starts with.
-- ------------------------------------------------------------
SELECT * FROM PSAUTHPRCS;       -- permission list → process group
SELECT * FROM PSPRCSPRFL;       -- process profile permissions
SELECT * FROM PSPRCSGRPS;       -- process → process group  (PS_PRCSDEFNGRP on some releases)

-- 3i.2b Readable batch-authority matrix
SELECT r.ROLENAME, rc.CLASSID AS PERMISSION_LIST,
       ap.PRCSGRP AS PROCESS_GROUP, p.PRCSNAME, p.PRCSTYPE, pd.DESCR
  FROM PSROLEDEFN   r
  JOIN PSROLECLASS  rc ON rc.ROLENAME = r.ROLENAME
  JOIN PSAUTHPRCS   ap ON ap.CLASSID  = rc.CLASSID
  LEFT JOIN PSPRCSGRPS p ON p.PRCSGRP = ap.PRCSGRP
  LEFT JOIN PSPRCSDEFN pd ON pd.PRCSNAME = p.PRCSNAME AND pd.PRCSTYPE = p.PRCSTYPE
 ORDER BY r.ROLENAME, ap.PRCSGRP, p.PRCSNAME;

-- ------------------------------------------------------------
-- 3i.3 ACCESS MATRIX  ** the deliverable **
-- Role → permission list → component, with the navigation path and the
-- number of users holding it. Export as
-- <instance>_P3I_ACCESS_MATRIX.csv. This single file answers most
-- who-does-what questions in the discovery phase.
-- ------------------------------------------------------------
SELECT r.ROLENAME,
       r.DESCR                AS ROLE_DESCR,
       rc.CLASSID             AS PERMISSION_LIST,
       c.DESCR                AS PERMLIST_DESCR,
       ai.MENUNAME,
       ai.BARNAME,
       ai.BARITEMNAME         AS COMPONENT,
       ai.DISPLAYONLY,
       ai.AUTHORIZEDACTIONS,
       (SELECT COUNT(*) FROM PSROLEUSER ru WHERE ru.ROLENAME = r.ROLENAME) AS USERS_WITH_ROLE
  FROM PSROLEDEFN   r
  JOIN PSROLECLASS  rc ON rc.ROLENAME = r.ROLENAME
  JOIN PSCLASSDEFN  c  ON c.CLASSID   = rc.CLASSID
  JOIN PSAUTHITEM   ai ON ai.CLASSID  = rc.CLASSID
 ORDER BY r.ROLENAME, ai.MENUNAME, ai.BARITEMNAME;
-- AUTHORIZEDACTIONS is a bit mask: 1=Add 2=Update/Display
-- 4=Update/Display All 8=Correction 16=DataEntry. Decode downstream.

-- ------------------------------------------------------------
-- 3i.4 Role population — how access is really distributed
-- ------------------------------------------------------------
SELECT ru.ROLENAME, rd.DESCR, COUNT(DISTINCT ru.ROLEUSER) AS USERS
  FROM PSROLEUSER ru
  LEFT JOIN PSROLEDEFN rd ON rd.ROLENAME = ru.ROLENAME
 GROUP BY ru.ROLENAME, rd.DESCR ORDER BY USERS DESC;

-- 3i.4b Roles held by nobody — decommission candidates
SELECT rd.ROLENAME, rd.DESCR, rd.LASTUPDOPRID, rd.LASTUPDDTTM
  FROM PSROLEDEFN rd
 WHERE NOT EXISTS (SELECT 1 FROM PSROLEUSER ru WHERE ru.ROLENAME = rd.ROLENAME)
 ORDER BY rd.ROLENAME;

-- 3i.4c Over-provisioning profile — users by role count
SELECT ROLE_COUNT, COUNT(*) AS USERS FROM (
  SELECT ROLEUSER, COUNT(*) AS ROLE_COUNT FROM PSROLEUSER GROUP BY ROLEUSER)
 GROUP BY ROLE_COUNT ORDER BY ROLE_COUNT;

-- ------------------------------------------------------------
-- 3i.5 SEGREGATION-OF-DUTIES INPUT  ** new in v2 **
-- Not an SoD ruleset — that is a workshop output. This is the raw pair
-- data the workshop needs: users holding access to two components that
-- the finance team will want separated.
-- ------------------------------------------------------------
SELECT ru.ROLEUSER AS OPRID,
       COUNT(DISTINCT ai.BARITEMNAME) AS DISTINCT_COMPONENTS,
       COUNT(DISTINCT rc.CLASSID)     AS PERMISSION_LISTS,
       COUNT(DISTINCT ru.ROLENAME)    AS ROLES
  FROM PSROLEUSER  ru
  JOIN PSROLECLASS rc ON rc.ROLENAME = ru.ROLENAME
  JOIN PSAUTHITEM  ai ON ai.CLASSID  = rc.CLASSID
 GROUP BY ru.ROLEUSER
 ORDER BY DISTINCT_COMPONENTS DESC;

-- ------------------------------------------------------------
-- 3i.6 HCM row-level (department) security — guard then extract
-- ------------------------------------------------------------
SELECT RECNAME FROM PSRECDEFN
 WHERE RECNAME IN ('SCRTY_TBL_DEPT','SJT_DEPT','SJT_CLASS_ALL','SJT_OPR_CLS',
                   'SCRTY_CLASS','SCRTY_TBL_HR','SEC_BU_CLS','SEC_SETID_CLS');
-- Extract each name the guard returns, e.g.
--   SELECT * FROM PS_SCRTY_TBL_DEPT;
--   SELECT * FROM PS_SJT_CLASS_ALL;
-- SJT_* tables can be large (one row per person per security key) —
-- check counts first and extract the CLASS-level tables in preference
-- to the person-level ones.
SELECT 'SCRTY_TBL_DEPT' AS T, COUNT(*) AS CNT FROM PS_SCRTY_TBL_DEPT UNION ALL
SELECT 'SJT_CLASS_ALL'       , COUNT(*)       FROM PS_SJT_CLASS_ALL;

-- ------------------------------------------------------------
-- 3i.7 TREES — with the volume guard v1 lacked
-- ------------------------------------------------------------
-- Step 1: always safe — structures and definitions
SELECT * FROM PSTREESTRCT;
SELECT * FROM PSTREEDEFN;

-- Step 2: measure before extracting nodes and leaves
SELECT t.SETID, t.SETCNTRLVALUE, t.TREE_NAME, t.EFFDT, t.TREE_STRCT_ID,
       t.DESCR, t.LASTUPDOPRID, t.LASTUPDDTTM,
       (SELECT COUNT(*) FROM PSTREENODE n
         WHERE n.SETID = t.SETID AND n.TREE_NAME = t.TREE_NAME
           AND n.EFFDT = t.EFFDT) AS NODE_COUNT,
       (SELECT COUNT(*) FROM PSTREELEAF l
         WHERE l.SETID = t.SETID AND l.TREE_NAME = t.TREE_NAME
           AND l.EFFDT = t.EFFDT) AS LEAF_COUNT
  FROM PSTREEDEFN t
 ORDER BY NODE_COUNT + LEAF_COUNT DESC;

-- Step 3: extract CURRENT effective-dated trees only, tree by tree.
-- Do not run an unqualified SELECT * on these tables.
SELECT n.* FROM PSTREENODE n
  JOIN (SELECT SETID, SETCNTRLVALUE, TREE_NAME, MAX(EFFDT) AS EFFDT
          FROM PSTREEDEFN WHERE EFFDT <= SYSDATE
         GROUP BY SETID, SETCNTRLVALUE, TREE_NAME) cur
    ON cur.SETID = n.SETID AND cur.TREE_NAME = n.TREE_NAME
   AND cur.EFFDT = n.EFFDT AND cur.SETCNTRLVALUE = n.SETCNTRLVALUE
 WHERE n.TREE_NAME IN ('DEPARTMENT','DEPT_SECURITY')   -- name the trees explicitly
 ORDER BY n.TREE_NAME, n.TREE_NODE_NUM;

SELECT l.* FROM PSTREELEAF l
  JOIN (SELECT SETID, SETCNTRLVALUE, TREE_NAME, MAX(EFFDT) AS EFFDT
          FROM PSTREEDEFN WHERE EFFDT <= SYSDATE
         GROUP BY SETID, SETCNTRLVALUE, TREE_NAME) cur
    ON cur.SETID = l.SETID AND cur.TREE_NAME = l.TREE_NAME
   AND cur.EFFDT = l.EFFDT AND cur.SETCNTRLVALUE = l.SETCNTRLVALUE
 WHERE l.TREE_NAME IN ('DEPARTMENT','DEPT_SECURITY')
 ORDER BY l.TREE_NAME, l.TREE_NODE_NUM, l.RANGE_FROM;

-- 3i.7b Which trees are load-bearing — prioritise these for extraction
--   * trees named in KK budget definitions (03g §3g.2b TRANSLATE_TREE)
--   * trees used by nVision reports (02b §2b.2b)
--   * DEPT_SECURITY and any tree referenced by PS_SCRTY_TBL_DEPT
--   * QUERY access group trees (02 §2.5)
-- Everything else can wait.
SELECT TREE_NAME, COUNT(*) AS DEFINITIONS FROM PSTREEDEFN
 GROUP BY TREE_NAME ORDER BY 2 DESC;

-- ------------------------------------------------------------
-- 3i.8 Account hygiene — feeds both security design and the
-- change-management audience list
-- ------------------------------------------------------------
SELECT CASE WHEN ACCTLOCK = 1 THEN 'LOCKED' ELSE 'ACTIVE' END AS ACCT_STATUS,
       CASE WHEN LASTSIGNONDTTM IS NULL THEN 'NEVER'
            WHEN LASTSIGNONDTTM > SYSDATE - 90  THEN 'LAST_90_DAYS'
            WHEN LASTSIGNONDTTM > SYSDATE - 365 THEN 'LAST_YEAR'
            ELSE 'OVER_A_YEAR' END AS LAST_SIGNON_BAND,
       COUNT(*) AS ACCOUNTS
  FROM PSOPRDEFN GROUP BY 1,2 ORDER BY 1,2;
