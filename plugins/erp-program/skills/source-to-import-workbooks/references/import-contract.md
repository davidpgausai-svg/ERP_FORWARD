# Import Review Contract — Family Selection and Rules

`import-contract.json` in this folder is the authoritative machine-readable contract (field keys, required-ness, allowed values, formats, limits). Read it when building files; the validator reads the same file. This document holds the judgment that JSON can't express: which family a candidate belongs to, and when *not* to emit a row.

## Purposes and families

| Purpose | Family | Use it for | Do NOT use it for |
|---|---|---|---|
| INVENTORY | legacy_system | A named system in the estate: PeopleSoft modules, bolt-ons, adjacent/supported systems | Processes, requirements, transaction data, approval decisions |
| INVENTORY | legacy_object | A table, module, report, interface, extract, or configuration item | A process map on its own |
| INVENTORY | shadow_system | A locally managed or unofficial system, with evidence it is so | A system merely mentioned, with no evidence it is shadow |
| INVENTORY | crosswalk_domain | An explicitly documented source-to-target mapping domain | Unvalidated or inferred mappings |
| REQUIREMENTS | requirement | An assessed requirement with a fit-gap disposition | General meeting notes, unassessed ideas |
| RAID | raid_item | An explicit risk, assumption, issue, or dependency | Decisions, action lists, vague concerns without a RAID classification |

**Not stageable at all:** business_process, configuration_object, decision, meeting, milestone, policy, evidence_link, record_link, approval_request. If the best home for a candidate is one of these, it belongs in the review pack with a note on where it should eventually live — not force-fitted into a supported family.

## Universal columns (every file)

`title` (required, unique, meaningful) · `description` (optional, but the only place a source reference persists onto the created record — use `Source: <file> | <locator> | <short context>`) · `classification` (optional, defaults INTERNAL) · `workstreamId` (optional, real UUID only).

Two rules that generate most avoidable errors:

- **`workstreamId` is a UUID or it is blank.** A workstream *name* is not acceptable and will fail. If a confirmed UUID lookup isn't available, leave it blank and flag it for the reviewer — the record can be assigned after creation.
- **Never invent a sensitive classification.** PAYROLL_SENSITIVE, SECURITY_SENSITIVE, RESTRICTED, and CONFIDENTIAL are meaningful controls, not descriptive adjectives. Apply them only when the source or the user says so. When sensitivity is genuinely unclear, use the INTERNAL default *and note it in the review pack* so a human can raise it.

## The judgment calls

**Requirements: `fitGapDisposition` is the gate.** Staging rejects `NOT_ASSESSED`. That value exists in the record schema but cannot be imported — so an unassessed requirement is not import material. Put it in the review pack with a reviewer action asking for the assessment. Never guess a disposition to get a row through; STANDARD vs. GAP is a design conclusion with real consequences.

**Shadow systems need evidence of being shadow.** A spreadsheet named in a workflow diagram is not automatically a shadow system. Look for indications of local management, no central IT ownership, or unofficial status. Absent that, it may be a `legacy_system` or `legacy_object` — or a review-pack question.

**Crosswalk domains need a documented target.** If the source shows a legacy concept but the target-side mapping is inferred, proposed, or "probably," it is not a crosswalk domain row. The target platform decision may not even be final; inventing target mappings creates false precision that survives into design.

**Dispositions, severities, priorities, criticality, lifecycle status, and risk levels are conclusions, not vibes.** Words like "important," "legacy," "should probably go away," or "at risk" do not map to CRITICAL, RETIRE, MUST, or HIGH. If a required value isn't stated or derivable from an explicit user-supplied rule, the candidate goes to the review pack. This is the single most common way an import batch becomes untrustworthy.

**`businessOwner` and `mappingOwner` are stated or blank.** A swimlane label, a document author, a committee, or the team that happened to write the document is not an owner. Where the family requires an owner and none is stated, the candidate cannot be a stage-ready row.

**Advisory bodies are never approvers.** `advisoryBodies` on a requirement records consultation input only. Nothing this skill produces may imply approval authority.

## File mechanics

One family per file · header row first · data on the first worksheet (Import Review reads only that one) · exact field keys as headers · static values (no formulas, macros, merged cells) · no commentary or cover sheets · UTF-8 for CSV · ISO `YYYY-MM-DD` dates · booleans as true/false/yes/no/1/0 · under 8 MB · `.csv` or `.xlsx`.

Unknown columns are ignored on record creation — they do not error, but they also do not persist. That is why provenance beyond the compact `description` reference belongs in the review pack, which also remains attached to the staged batch's audit trail through the user's own upload.

Run `scripts/validate_stage_ready.py` on every file before handing it over. It enforces everything mechanical in this document.
