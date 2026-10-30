# Research protocol

Everything in a build guide traces back to a retrieved document. This file covers where
to retrieve from and how to avoid the failure modes.

## Establish the target first

Call `vendor_status_get` before anything else. It returns the active vendor, the target
ERP, the evaluation phase, which vendors' documentation is open, and how many documents
are actually captured and searchable. Two things this prevents:

- Writing a guide for the wrong ERP. While the ERP selection is unsigned
  (`evaluation.phase` is EVALUATING), every candidate ERP's documentation is open: if
  the person hasn't named a vendor, say the selection is open and ask which ERP the
  guide is for, or use `platform_docs_compare` to show the candidates side by side.
  Once the selection is signed, documentation is locked to the awarded ERP.
- Confidently researching a corpus that turns out to be empty. If the document count is
  zero or the capture failed, say so rather than filling the gap from training data.

## Lane routing

The MCP has several retrieval lanes and they are not interchangeable. Using the wrong one
returns nothing and looks like the topic is uncovered. Use only the lanes for the ERP the
guide is for: never answer about one ERP with another's words or pages.

| Lane | Tools | Use for |
|---|---|---|
| Governed evidence (both ERPs) | `vendor_search`, `vendor_guidance_get` | Human-approved, pinnable evidence. Use when the claim needs to survive an audit. Often sparse. |
| Workday functional and admin config | `admin_docs_search`, `admin_docs_get` | The main Workday lane for build guides. Task names, setup steps, tenant settings, security domains, business process guidelines. |
| Workday developer API reference | `developer_docs_search`, `developer_docs_get` | Web services, REST endpoints, integration payloads. |
| Paradox / Olivia (a Workday add-on) | `paradox_docs_search`, `paradox_docs_get` | Candidate experience questions only. Never part of an Oracle guide. |
| Oracle Fusion documentation | `oracle_docs_search`, `oracle_docs_get`, `oracle_docs_releases`, `oracle_docs_release_diff` | The main Oracle lane: implementation and setup tasks, by release. |
| Oracle reference | `oracle_reference_docs_search` | Oracle reference material that sits outside the release guides. |
| Candidate comparison | `platform_docs_compare` | While the selection is unsigned and no vendor is named: the same question against every candidate, side by side. Never declare a winner. |

Before concluding a topic isn't covered, call `glossary_lookup` on the term and search
again with the words it returns. Workday, Oracle and PeopleSoft often name one concept
differently (for example, PeopleSoft's DEPTID becomes Cost Center and Supervisory
Organization in Workday). `NO_EVIDENCE_IN_CORPUS` means the captured documentation
returned nothing for that query, not that the product lacks the capability.

If `vendor_search` returns nothing, that does not mean the topic is uncovered. Try
`admin_docs_search` before concluding anything. The governed lane and the raw capture
lane have very different coverage.

## Search technique

Search returns snippets. Get the full page with the matching `_get` tool before relying
on it, because the sequence and field detail you need is usually below the snippet.

For Workday, pages whose titles begin with **Steps:** are the highest-value retrievals. They contain
Workday's own ordered setup sequence with task names, and they link to the next page in
the chain. Pull the whole chain. For a module named X, search in roughly this order:

1. `Steps: Set Up X` and `Setup Considerations: X` — the sequence and the decisions
2. `Concept: X` — what the objects actually are
3. `Reference: X Terminology` — vocabulary, so the guide uses the tenant's words
4. Tenant setup pages — the switches that must be on
5. Business process guidelines for the relevant processes
6. Security pages — domains and the groups that need them
7. `Steps: Use X` — the operational runbook, which often reveals setup steps you missed

Course manual pages (`workday-education`) are worth searching separately. They explain
navigation and framework mechanics that the admin guide assumes you already know, which
is exactly what Stage 0 needs.

## The record layer

Before drafting, call `record_search` on the module name and `workstream_list`. This
tells you whether a record already exists, who owns it, and which workstreams are
affected. Extending an existing draft record beats creating a duplicate, and the
workstream IDs are what owner assignments in the guide should resolve to.

When an APPROVED business process covers the module, `business_process_build_plan_get`
returns its configuration objects in build order, with approved settings, build steps,
tests and the vendor guides each one pins (`externalDocumentId` and `documentVersionId`
for `vendor_guidance_get`). The program's approved settings decide what to enter; vendor
pages explain where and how. Carry each record's status into the guide: a DRAFT setting
is a proposal, not a decided value.

When a build guide surfaces new open decisions or risks, offer to log them through the
record layer rather than leaving them only in the document.

## Citation rules

- Cite the `canonicalUrl` from the result, as a link the reader can open.
- Group citations by topic in a sources appendix rather than footnoting inline, so the
  document stays readable.
- Never cite a page you did not retrieve.
- A retrieved page is evidence for what it says, not for what you wish it said. If the
  page covers the concept but not the specific configuration, say the specific
  configuration is unconfirmed.

## When the corpus does not cover something

State it plainly in the document, in the stage where it matters, and mark the claim as
drawn from general leading practice rather than from a cited source. Then offer to have
the page crawled so the next revision can be grounded properly. A labeled gap is
recoverable. An unlabeled guess is not.
