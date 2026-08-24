-- ============================================================
-- 03e_anchors_fscm_p2p_ar_bi.sql  (KIT v2) — NEW FILE, run on FSCM
-- Procure-to-pay (Purchasing, eProcurement, Payables), order-to-cash
-- (Billing, Receivables), Cash/Treasury, and Inventory reference setup.
--
-- v1 offered PYMT_TRMS_TBL and BANK_CD_TBL from this whole domain, and
-- guarded ORIGIN_TBL / CATEGORY_TBL / UNSPSC_TBL / SHIPTO_TBL /
-- ITM_CAT_TBL / MASTER_ITEM_TBL / BU_ITEMS_INV without extracting any.
--
-- Sensitivity: LOW. NOTE the explicit exclusions in §3e.4 — supplier and
-- customer master records are person/entity data and are OUT OF SCOPE.
-- ============================================================

-- ------------------------------------------------------------
-- 3e.1 Guard + generate
-- ------------------------------------------------------------
WITH anchors AS (
  -- Purchasing / eProcurement -------------------------------------
  SELECT 'ITM_CAT_TBL'       AS RECNAME, 'Item categories'                  AS PURPOSE FROM DUAL UNION ALL
  SELECT 'CATEGORY_TBL'            , 'Purchasing categories'                     FROM DUAL UNION ALL
  SELECT 'UNSPSC_TBL'              , 'UNSPSC classification'                     FROM DUAL UNION ALL
  SELECT 'SHIPTO_TBL'              , 'Ship-to locations'                         FROM DUAL UNION ALL
  SELECT 'SHIPTO_DEFAULT'          , 'Ship-to defaults'                          FROM DUAL UNION ALL
  SELECT 'ORIGIN_TBL'              , 'Transaction origins'                       FROM DUAL UNION ALL
  SELECT 'BUYER_TBL'               , 'Buyers'                                    FROM DUAL UNION ALL
  SELECT 'REQUESTOR_TBL'           , 'Requesters'                                FROM DUAL UNION ALL
  SELECT 'PO_TYPE_TBL'             , 'Purchase order types'                      FROM DUAL UNION ALL
  SELECT 'PO_ORIGIN_TBL'           , 'PO origins'                                FROM DUAL UNION ALL
  SELECT 'DISTRIB_TMPLT_TBL'       , 'Distribution templates'                    FROM DUAL UNION ALL
  SELECT 'CNTRCT_TYPE_TBL'         , 'Contract types'                            FROM DUAL UNION ALL
  SELECT 'FREIGHT_TERMS_TBL'       , 'Freight terms'                             FROM DUAL UNION ALL
  SELECT 'SHIP_VIA_TBL'            , 'Ship-via codes'                            FROM DUAL UNION ALL
  SELECT 'UNIT_OF_MEASURE'         , 'Units of measure'                          FROM DUAL UNION ALL
  SELECT 'MATCH_RULE_HDR'          , 'Matching rules (2/3/4-way)'                FROM DUAL UNION ALL
  SELECT 'MATCH_RULE_CTL'          , 'Match rule control'                        FROM DUAL UNION ALL
  SELECT 'RECV_TYPE_TBL'           , 'Receipt types'                             FROM DUAL UNION ALL
  SELECT 'INSTALLATION_PO'         , 'Purchasing installation options'           FROM DUAL UNION ALL
  -- Payables ------------------------------------------------------
  SELECT 'PYMT_TRMS_TBL'           , 'Payment terms'                             FROM DUAL UNION ALL
  SELECT 'PYMT_TRMS_HDR'           , 'Payment terms header'                      FROM DUAL UNION ALL
  SELECT 'PYMNT_TERMS_STD'         , 'Standard payment terms'                    FROM DUAL UNION ALL
  SELECT 'PYMNT_MTHD_TBL'          , 'Payment methods'                           FROM DUAL UNION ALL
  SELECT 'PYCYCL_DEFN'             , 'Pay cycle definitions'                     FROM DUAL UNION ALL
  SELECT 'PYCYCL_SEL_CRIT'         , 'Pay cycle selection criteria'              FROM DUAL UNION ALL
  SELECT 'VNDR_CLASS_TBL'          , 'Supplier classes (config, not suppliers)'  FROM DUAL UNION ALL
  SELECT 'VNDR_TYPE_TBL'           , 'Supplier types'                            FROM DUAL UNION ALL
  SELECT 'VCHR_ORIGIN_TBL'         , 'Voucher origins'                           FROM DUAL UNION ALL
  SELECT 'VCHR_STYLE_TBL'          , 'Voucher styles'                            FROM DUAL UNION ALL
  SELECT 'ENTRY_TYPE_AP'           , 'AP entry types'                            FROM DUAL UNION ALL
  SELECT 'WTHD_TYPE_TBL'           , 'Withholding types (1099)'                  FROM DUAL UNION ALL
  SELECT 'WTHD_CLASS_TBL'          , 'Withholding classes'                       FROM DUAL UNION ALL
  SELECT 'WTHD_JUR_TBL'            , 'Withholding jurisdictions'                 FROM DUAL UNION ALL
  SELECT 'INSTALLATION_AP'         , 'AP installation options'                   FROM DUAL UNION ALL
  -- Receivables / Billing -----------------------------------------
  SELECT 'ITEM_ENTRY_TYPE'         , 'AR item entry types'                       FROM DUAL UNION ALL
  SELECT 'ENTRY_REASON_TBL'        , 'AR entry reasons'                          FROM DUAL UNION ALL
  SELECT 'ENTRY_USE_TBL'           , 'AR entry use'                              FROM DUAL UNION ALL
  SELECT 'AGING_TBL'               , 'Aging categories'                          FROM DUAL UNION ALL
  SELECT 'DUNNING_ID_TBL'          , 'Dunning setup'                             FROM DUAL UNION ALL
  SELECT 'COLL_TBL'                , 'Collection codes'                          FROM DUAL UNION ALL
  SELECT 'CUST_TYPE_TBL'           , 'Customer types (config, not customers)'    FROM DUAL UNION ALL
  SELECT 'BI_TYPE_TBL'             , 'Bill types'                                FROM DUAL UNION ALL
  SELECT 'BI_SOURCE_TBL'           , 'Bill sources'                              FROM DUAL UNION ALL
  SELECT 'BI_CYCLE_TBL'            , 'Bill cycles'                               FROM DUAL UNION ALL
  SELECT 'IDENTIFIER_TBL'          , 'Charge identifiers'                        FROM DUAL UNION ALL
  SELECT 'DISTRIB_CODE_TBL'        , 'Distribution codes — AR/BI to GL mapping'  FROM DUAL UNION ALL
  SELECT 'INSTALLATION_AR'         , 'AR installation options'                   FROM DUAL UNION ALL
  SELECT 'INSTALLATION_BI'         , 'Billing installation options'              FROM DUAL UNION ALL
  -- Cash / Treasury -----------------------------------------------
  SELECT 'BANK_CD_TBL'             , 'Bank codes'                                FROM DUAL UNION ALL
  SELECT 'BANK_BRANCH_TBL'         , 'Bank branches'                             FROM DUAL UNION ALL
  SELECT 'BANK_ACCT_DEFN'          , 'Bank account definitions — REVIEW BEFORE EXPORT' FROM DUAL UNION ALL
  SELECT 'BANK_ACCT_TYPE'          , 'Bank account types'                        FROM DUAL UNION ALL
  SELECT 'EFT_LAYOUT_TBL'          , 'EFT layouts'                               FROM DUAL UNION ALL
  SELECT 'DEPOSIT_TYPE_TBL'        , 'Deposit types'                             FROM DUAL UNION ALL
  -- Inventory reference -------------------------------------------
  SELECT 'INV_ITEM_TYPE'           , 'Inventory item types'                      FROM DUAL UNION ALL
  SELECT 'INV_ITEM_GROUP'          , 'Item groups'                               FROM DUAL UNION ALL
  SELECT 'STOR_LOC_TBL'            , 'Storage locations'                         FROM DUAL UNION ALL
  SELECT 'INSTALLATION_IN'         , 'Inventory installation options'            FROM DUAL
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
-- 3e.2 BANK_ACCT_DEFN CAUTION  ** new in v2 **
-- v1 said "verify columns before export" on BANK_CD_TBL and left it
-- there. Do it properly: list the columns first and confirm no account
-- numbers are present, or select an explicit safe column list.
-- ------------------------------------------------------------
SELECT FIELDNAME, FIELDNUM FROM PSRECFIELDDB
 WHERE RECNAME IN ('BANK_ACCT_DEFN','BANK_CD_TBL','SRC_BANK')
 ORDER BY RECNAME, FIELDNUM;
-- Extract with an explicit column list that excludes BANK_ACCOUNT_NUM,
-- IBAN, DFI_ID_QUAL and any encrypted-token column. If in doubt, treat
-- this table as out of scope: bank account setup is rarely needed for
-- discovery and is always needed for an incident report if it leaks.

-- ------------------------------------------------------------
-- 3e.3 P2P policy profile — the rules that actually gate spending
-- ------------------------------------------------------------
-- Matching rules in force
SELECT MATCH_RULE_ID, EFFDT, EFF_STATUS, DESCR, MATCH_RULE_TYPE
  FROM PS_MATCH_RULE_HDR ORDER BY MATCH_RULE_ID, EFFDT;

-- Requisition/PO approval thresholds live in AWE (02c) — cross-reference
-- PS_EOAW_CRITERIA for the transactions REQ_LINE / PO_AMT_APPR.

-- Pay cycle configuration — how money actually leaves the institution
SELECT PAY_CYCLE, EFFDT, DESCR, PYMNT_SELCT_CRIT_ID
  FROM PS_PYCYCL_DEFN ORDER BY PAY_CYCLE, EFFDT;

-- ------------------------------------------------------------
-- 3e.4 OUT OF SCOPE — do not extract in this pack
-- ------------------------------------------------------------
-- PS_VENDOR, PS_VENDOR_ADDR, PS_VENDOR_LOC, PS_VNDR_BANK_ACCT
-- PS_CUSTOMER, PS_CUST_ADDRESS, PS_CUST_CREDIT
-- PS_VOUCHER, PS_VCHR_ACCTG_LINE, PS_PYMNT_VCHR_XREF
-- PS_PO_HDR, PS_PO_LINE, PS_REQ_HDR, PS_REQ_LINE
-- PS_ITEM (AR items), PS_BI_HDR, PS_BI_LINE
-- These are supplier, customer and transactional records. They belong to
-- the data-conversion workstream with its own governance, not discovery.
-- The aggregates below give the sizing without moving the data:
SELECT 'VOUCHERS' AS OBJ, COUNT(*) AS ROWS_CNT FROM PS_VOUCHER   UNION ALL
SELECT 'PO_HEADERS'      , COUNT(*)            FROM PS_PO_HDR    UNION ALL
SELECT 'REQ_HEADERS'     , COUNT(*)            FROM PS_REQ_HDR   UNION ALL
SELECT 'AR_ITEMS'        , COUNT(*)            FROM PS_ITEM      UNION ALL
SELECT 'BILLS'           , COUNT(*)            FROM PS_BI_HDR    UNION ALL
SELECT 'SUPPLIERS'       , COUNT(*)            FROM PS_VENDOR    UNION ALL
SELECT 'CUSTOMERS'       , COUNT(*)            FROM PS_CUSTOMER;

-- 3e.4b Transaction volume by year — conversion and archive sizing
SELECT 'VOUCHER' AS TXN, TO_CHAR(ACCOUNTING_DT,'YYYY') AS YR, COUNT(*) AS CNT
  FROM PS_VOUCHER GROUP BY TO_CHAR(ACCOUNTING_DT,'YYYY')
 UNION ALL
SELECT 'PO', TO_CHAR(PO_DT,'YYYY'), COUNT(*) FROM PS_PO_HDR GROUP BY TO_CHAR(PO_DT,'YYYY')
 ORDER BY 1,2;
-- SQL Server: TO_CHAR(x,'YYYY') → CAST(YEAR(x) AS VARCHAR(4))
