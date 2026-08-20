-- ============================================================
-- 03b_anchors_fscm.sql — FSCM anchor setup tables (run on FSCM instance)
-- Finance + supply chain. Generator (03) is authoritative; these are
-- the first-asked tables. Verify existence, then extract.
-- ============================================================

SELECT RECNAME FROM PSRECDEFN WHERE RECNAME IN (
 'BUS_UNIT_TBL_FS','BUS_UNIT_TBL_GL','BUS_UNIT_TBL_AP','BUS_UNIT_TBL_AR',
 'BUS_UNIT_TBL_PM','BUS_UNIT_TBL_PO','INSTALLATION_FS',
 'GL_ACCOUNT_TBL','ALTACCT_TBL','DEPT_TBL','FUND_TBL','CLASS_CF_TBL',
 'PROGRAM_TBL','PROJECT','CHARTFIELD1_TBL','CHARTFIELD2_TBL','CHARTFIELD3_TBL',
 'OPER_UNIT_TBL','PRODUCT_TBL','LED_DEFN_TBL','LED_GRP_TBL','CAL_DETP_TBL',
 'SPEEDTYP_TBL','COMBO_RULE_TBL','JRNL_SOURCE_TBL','BANK_CD_TBL',
 'PYMT_TRMS_TBL','ORIGIN_TBL','CATEGORY_TBL','UNSPSC_TBL','SHIPTO_TBL',
 'ITM_CAT_TBL','MASTER_ITEM_TBL','BU_ITEMS_INV');

-- Chartfields — the finance org structure:
SELECT * FROM PS_GL_ACCOUNT_TBL;
SELECT * FROM PS_DEPT_TBL;           -- chartfield department (FSCM side)
SELECT * FROM PS_FUND_TBL;
SELECT * FROM PS_PROGRAM_TBL;
SELECT * FROM PS_CLASS_CF_TBL;
SELECT * FROM PS_OPER_UNIT_TBL;
SELECT * FROM PS_SPEEDTYP_TBL;
-- Ledgers & calendars:
SELECT * FROM PS_LED_DEFN_TBL;
SELECT * FROM PS_LED_GRP_TBL;
-- Business units across modules:
SELECT * FROM PS_BUS_UNIT_TBL_FS;
SELECT * FROM PS_BUS_UNIT_TBL_GL;
-- Procure-to-pay reference:
SELECT * FROM PS_PYMT_TRMS_TBL;
SELECT * FROM PS_BANK_CD_TBL;        -- bank codes (setup, not account numbers — verify columns before export)
-- Journal sources (integration fingerprints — every feeder system has one):
SELECT * FROM PS_JRNL_SOURCE_TBL;
