-- ============================================================
-- 03d_security_trees.sql — WHO CAN DO WHAT + ORG/REPORTING STRUCTURES
-- Pillar-agnostic. Sensitivity: MODERATE (user IDs) — classify INTERNAL.
-- Security is a process-discovery goldmine: page access by role by
-- department reveals who actually performs each transaction.
-- ============================================================

-- Security model
SELECT * FROM PSROLEDEFN;      -- roles
SELECT * FROM PSCLASSDEFN;     -- permission lists
SELECT * FROM PSAUTHITEM;      -- permission list -> menu/component/page access (the access matrix)
SELECT * FROM PSROLECLASS;     -- role -> permission list
SELECT * FROM PSROLEUSER;      -- user -> role (who holds what)
SELECT OPRID, OPRDEFNDESC, EMPLID, OPRCLASS, ACCTLOCK, LASTSIGNONDTTM
  FROM PSOPRDEFN;              -- user accounts (columns trimmed; excludes password hashes)

-- Trees — org hierarchies, chartfield rollups, security trees.
-- Finance reporting structure and HR department hierarchy both live here.
SELECT * FROM PSTREESTRCT;
SELECT * FROM PSTREEDEFN;
SELECT * FROM PSTREENODE;
SELECT * FROM PSTREELEAF;

-- HCM row-level (department) security, if present on this instance:
SELECT RECNAME FROM PSRECDEFN WHERE RECNAME IN ('SCRTY_TBL_DEPT','SJT_DEPT','SJT_CLASS_ALL');
SELECT * FROM PS_SCRTY_TBL_DEPT;   -- extract those that exist
