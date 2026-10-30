# Output Conventions (all ERP FORWARD skills)

Every skill in this plugin produces work that must outlive the chat session. Nothing canonical stays in chat — that is the program's founding rule.

## Where outputs land

1. **Record layer connected (preferred).** When the ERP Forward MCP connector is available, write structured outputs there: call `schema_get` for the record type first (never guess record types, field names, link types or allowed values; the schema registry is authoritative), call `record_search` to check for a duplicate, then create records with `record_create_draft` (or `business_process_submit_group` for a process and its children). Put source citations in the description (extract file + snapshot date, or document name + section).
   **You never submit or approve.** Review submission and approval decisions always refuse over MCP. When the drafts are ready, tell the person each record's key and title, that it is a DRAFT, and that they submit it in Keystone, where they choose the approval route.
2. **Record layer not connected (interim).** Produce the output as a file — markdown for narrative deliverables, CSV for inventories — and save it to the extract library's `/analysis/<topic>/` folder (or the session's working folder if the library isn't connected). Name it `<topic>_<instance>_<snapshot-date>.md|csv`. Structure CSVs so they can be imported into the record layer later without rework.

## Reading records

The connector's own instructions are authoritative; these are the rules that matter most for every skill.

- Carry each record's status into what you say. DRAFT is a proposal and IN_REVIEW is pending; only APPROVED is a program record. Never present a draft decision, date, phase or scope as settled.
- A citation written in a record says what the record cites, not that anyone read the source. Retrieve the source with an evidence tool before calling a claim supported.
- An EVALUATING SKU is under evaluation, not purchased.
- Refer to records by the stable `recordKey` from `record_search`, with its exact title and type label. If several records match a name, show them and ask which one the person means.
- Before saying something is not in ERP Forward or not in the documentation, call `glossary_lookup` on the term and search again with the words it returns. An empty search is not evidence of absence.
- Claude cannot upload files through MCP. A person uploads files in Keystone; the only authored content Claude can attach is BPMN XML, through `record_bpmn_attach`.

## Standard finding format

When a skill produces findings (issues, risks, anomalies, candidates), use this shape whether writing records or CSV rows:

- title (short, specific)
- description (what was observed, with numbers)
- evidence (source file, snapshot date, instance; example object names or rows)
- proposed disposition or action (a suggestion, clearly labeled as such)
- confidence: HIGH / MEDIUM / LOW, with one line on why
- owner_suggestion (role, not a named person, unless the human names one)

## Attribution and honesty

- Cite every factual claim to an extract file or document. An uncited claim is a hypothesis — label it as one.
- List what you could NOT determine and why (missing pack, telemetry gap, ambiguous data). The unknowns list is often the most valuable part of the output — it becomes the interview agenda for SMEs.
- Round numbers honestly; never present a sampled result as a full-population result.

## Tone for human-facing deliverables

Executive-ready: plain language, lead with the conclusion, keep internal object names in appendices with navigation breadcrumbs alongside. Black font, no horizontal divider bars in documents.
