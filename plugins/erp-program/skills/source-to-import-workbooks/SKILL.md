---
name: source-to-import-workbooks
description: Convert ERP FORWARD discovery documents — DOCX, PDF, Visio/VSDX and diagram exports, workshop packs, fit-gap workbooks, inventory lists — into stage-ready import workbooks for the Program System of Record's Import Review module, plus a separate review pack holding extraction evidence, confidence, and everything not safe to import. Use this whenever someone wants to turn documents into import files, mentions Import Review, /imports, staging or bulk-creating draft records from documents, converting an inventory list or fit-gap workbook or process map into records, or asks how to get what's in Word/PDF/Visio into the record layer.
---

# Source Documents → Import Workbooks

The program already knows a great deal that is trapped in documents. This skill moves that knowledge into the governed record layer *safely*: it prepares files a human then stages, reviews, and commits. It is document-to-draft preparation — never a data migration, and never a shortcut around review.

## The boundary that defines this skill

**Produce files. Touch nothing.** Never call the API, MCP, or database; never create, update, or link a record; never submit for review, choose an approver, or record an approval. Everything this skill makes is a file the user uploads themselves. Import Review remains the authority for validation, audit, draft creation, and routing — and committing a batch creates DRAFT records, never approved ones.

Two corollaries that matter in practice: never fabricate an owner, workstream UUID, approver, decision, disposition, severity, priority, or classification to fill a required field. And never treat a filename, document author, swimlane label, org chart, committee, or advisory body as an authoritative owner or decision unless the source says so explicitly. A blank field with a reviewer action is always better than a plausible invention.

## What can be staged

Read `references/import-contract.md` before building anything — it holds family selection guidance and the interpretive rules. `references/import-contract.json` is the machine-readable contract (exact field keys, required-ness, allowed values) and wins over any other description if they ever disagree.

Six families only: `legacy_system`, `legacy_object`, `shadow_system`, `crosswalk_domain` (purpose INVENTORY), `requirement` (REQUIREMENTS), `raid_item` (RAID). Business processes, configuration objects, decisions, meetings, milestones, policies, evidence links, record links, and approval requests **cannot be staged** — a process map may *support* a requirement, RAID item, crosswalk domain, or estate object, but must never be forced into an unsupported family.

## Workflow

**1. Intake — confirm before extracting.** Ask, and don't assume: which files are authoritative vs. reference-only vs. superseded; which outputs are wanted (inventory, requirements, RAID, or several separate files); whether confirmed workstream UUIDs exist or `workstreamId` stays blank; whether classification is supplied per-record or the INTERNAL default is acceptable for ordinary program evidence; whether source titles and identifiers must be preserved verbatim; and what target-platform or vendor information is actually confirmed versus still undecided. Keep this short — a few grouped questions, not an interrogation.

**2. Extract with evidence.** Follow `references/extraction-protocol.md` for DOCX, PDF, and Visio/diagram specifics. Every candidate carries its provenance from the moment it is created: source file, locator, excerpt, extraction method, confidence, and the rationale for the family and values chosen. Candidates without evidence do not exist.

**3. Triage honestly.** Each candidate gets a `reviewStatus`: `READY_FOR_IMPORT`, `NEEDS_CONFIRMATION`, `EXCLUDED`, or `DUPLICATE_CANDIDATE`. **Only READY_FOR_IMPORT candidates go into a stage-ready file.** Everything else goes to the review pack, where it is useful rather than dangerous. Resist the pull to maximize the import count — a batch of forty defensible rows plus a review pack of twenty questions is a far better deliverable than sixty rows a reviewer cannot trust. Never raise a candidate's confidence just because a plausible reading exists.

**4. Build the files.** One record family per file, header row first, data on the first worksheet, exact field keys as headers (so automatic matching works without a mapping profile), static values only — no formulas, macros, merged cells, commentary sheets, or cover sheets ahead of the data. Keep each file under 8 MB, `.csv` (UTF-8) or `.xlsx`. Put a compact source reference in `description` (`Source: <file> | <locator> | <context>`), because unknown columns are dropped on record creation and richer provenance belongs in the review pack.

**5. Validate before handing over — always.** Run the bundled validator on every stage-ready file:

```bash
python scripts/validate_stage_ready.py <run-name>/stage-ready/*.xlsx
```

It checks extension, size, worksheet count, formulas, merged cells, required fields, allowed values, ISO dates, booleans, UUID-shaped `workstreamId`, and duplicate titles. Fix everything it reports and re-run until clean. Shipping a file that fails this check wastes a reviewer's time on errors that were avoidable, which is precisely what this skill exists to prevent.

**6. Hand off with instructions.** Tell the user exactly which purpose and family to select for each file, and walk them through: upload one file → select purpose and family → Stage & Validate (this creates a reviewable batch, not records) → review every proposed row and validation error → correct the *workbook or source* and stage a fresh batch rather than editing a prior one → commit only valid, accurate rows → then review each resulting DRAFT and submit it through the normal chain of command when its content is ready.

## Output package

```
<run-name>/
  README.md
  stage-ready/     one file per family, only where valid candidates exist
  review/          <run-name>-review-pack.xlsx  +  <run-name>-conversion-summary.md
```

The review pack is never uploaded to Import Review — say so in the README. The README states: source files and their authority status; each stage-ready file with the exact purpose and family to select; counts (extracted, ready, needs confirmation, excluded, possible duplicates); whether classification and workstream IDs were supplied, defaulted, or left blank; known limits (scanned pages, ambiguous diagrams); and the stage → review → correct → re-stage → commit sequence.

## Normalization and duplicates

Normalize only what cannot change meaning: whitespace, repeated headers, line breaks, obvious OCR damage. Preserve source identifiers, document IDs, and requirement IDs exactly unless the user authorizes a rule. Flag possible duplicates by comparing title plus core identity fields — never silently merge or drop them. Keep one candidate per distinct system, object, requirement, RAID item, or mapping domain; do not collapse many source rows into a generic summary record.
