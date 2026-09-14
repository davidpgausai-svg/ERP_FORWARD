# Research protocol

Everything in a build guide traces back to a retrieved document. This file covers where
to retrieve from and how to avoid the failure modes.

## Establish the target first

Call `vendor_status_get` before anything else. It returns the active vendor, the target
ERP, operating mode, and how many documents are actually captured and searchable. Two
things this prevents:

- Writing an Oracle build guide when the tenant is Workday.
- Confidently researching a corpus that turns out to be empty. If the document count is
  zero or the capture failed, say so rather than filling the gap from training data.

## Lane routing

The MCP has four retrieval lanes and they are not interchangeable. Using the wrong one
returns nothing and looks like the topic is uncovered.

| Lane | Tools | Use for |
|---|---|---|
| Governed evidence | `vendor_search`, `vendor_guidance_get` | Human-approved, pinnable evidence. Use when the claim needs to survive an audit. Often sparse. |
| Functional and admin config | `admin_docs_search`, `admin_docs_get` | The main lane for build guides. Task names, setup steps, tenant settings, security domains, business process guidelines. |
| Developer API reference | `developer_docs_search`, `developer_docs_get` | Web services, REST endpoints, integration payloads. |
| Paradox / Olivia | `paradox_docs_search`, `paradox_docs_get` | Candidate experience questions only. |

If `vendor_search` returns nothing, that does not mean the topic is uncovered. Try
`admin_docs_search` before concluding anything. The governed lane and the raw capture
lane have very different coverage.

## Search technique

Search returns snippets. Get the full page with the matching `_get` tool before relying
on it, because the sequence and field detail you need is usually below the snippet.

Pages whose titles begin with **Steps:** are the highest-value retrievals. They contain
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
