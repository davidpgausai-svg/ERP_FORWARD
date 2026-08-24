# Extraction Protocol — By Source Type

Extraction is a claims exercise, not a text-scraping exercise: every candidate is a claim about the program that a reviewer must be able to check against the source in under a minute. That standard drives everything below.

## Candidate record (kept for every candidate, ready or not)

| Field | Content |
|---|---|
| candidateId | Stable ID tying the candidate to its import row or exception (e.g. `C-014`) |
| targetRecordType | One of the six families, or `EXCEPTION` |
| sourceFile | Exact filename |
| sourceLocator | DOCX heading/table; PDF page + section/table; Visio page/shape/lane |
| sourceExcerpt | Short quote, cell text, or diagram label supporting the claim |
| extractionMethod | TEXT, TABLE, DIAGRAM, or MANUAL_REVIEW |
| confidence | HIGH / MEDIUM / LOW — never a substitute for human review |
| mappingRationale | Why this family, and why these values |
| reviewStatus | READY_FOR_IMPORT / NEEDS_CONFIRMATION / EXCLUDED / DUPLICATE_CANDIDATE |
| reviewerAction | The specific decision or missing source fact needed |

Confidence is about *evidence strength*, not about how sensible the interpretation feels. A single unlabeled diagram box supporting a plausible reading is LOW confidence, not HIGH.

## DOCX

Read headings, body text, lists, tables, captions, and appendices; read comments only when they carry substantive content rather than editorial chatter. Treat tables as likely-structured sources but preserve the table title, column headers, row label, and containing section — a value ripped out of its table loses the meaning that made it usable. Capture a quote or tight snippet for every material fact. Heading hierarchy is often the best available context for scope (which module, which population, which phase) — carry it into `mappingRationale`.

## PDF

Extract text and tables first. Then look at page renderings, because layout carries meaning that text extraction drops: figure callouts, side-by-side comparisons, tables whose column grouping changes the reading, struck-through or annotated content. Track every candidate to a page number plus section or table label.

Scanned or visually ambiguous pages: do not guess. Route them to exceptions with the page range and the reason, and say so plainly in the README's known-limits section. A reviewer who knows pages 12–18 weren't machine-readable can assign someone to read them; a reviewer who receives confident rows invented from a blurry scan cannot.

## Visio / VSDX and diagram exports

Prefer native shape text and metadata when the file is readable; otherwise work from exported PDF/image pages. Capture the diagram name, page, swimlanes, systems, actors, steps, decisions, handoffs, inputs and outputs, controls, exceptions, and annotations.

The discipline that matters here: **a workflow step is not a record because it exists.** Diagrams describe how work flows; the record layer holds systems, objects, requirements, RAID, and mappings. Convert only where the diagram states something in one of those shapes:

- **legacy_system / legacy_object** — only for explicitly *named* systems, interfaces, reports, tables, extracts, or tools. A box labeled "approval" is not a system; a box labeled "Kronos" is.
- **crosswalk_domain** — only where an explicit source-to-target mapping is drawn or annotated.
- **requirement** — only where a required capability, rule, control, obligation, or unmet need is stated, not merely implied by a step existing.
- **raid_item** — only where a risk, issue, dependency, or assumption is explicit or unambiguously labelled (a red annotation reading "manual — error prone" qualifies; a plain step does not).

Send to the review pack: unlabeled connectors, ambiguous lane ownership, implied ownership from lane titles, anything that reads as future-state design, and any interpretation that required you to fill a gap. Lane labels in particular are a trap — they name a team or role, not an accountable `businessOwner`, and a diagram is not a governance artifact.

## Working across a document set

Process authoritative sources first and let reference-only material corroborate rather than originate candidates; a fact appearing only in a superseded deck is an exception, not a row. When two authoritative sources conflict, emit neither — raise it as a NEEDS_CONFIRMATION candidate quoting both, since a conflict discovered now is far cheaper than one discovered after records exist. Where a source is genuinely rich (a fit-gap workbook, an inventory appendix), keep one candidate per distinct item rather than collapsing rows into a summary; the whole value of the exercise is granularity a reviewer can act on.
