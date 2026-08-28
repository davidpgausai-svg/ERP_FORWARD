---
name: process-and-decision-modeling
description: Help ERP Forward workstream members draft future-state business process maps (BPMN 2.0) and policy decision tables (DMN 1.3), always working through the ERP Forward record layer so nothing lives only in chat. Use this skill whenever the user wants to "map a process", "draft a future-state flow", "capture how this should work", "model a policy as a decision table", "figure out what rules should fire", or when a conversation reveals a workflow or decision that has no record yet. Also use it to redraw a current-state map before proposing a future-state change, and to sanity-check a diagram someone else drafted against approved records before it goes to review.
---

# Process and Decision Modeling

Business process maps and decision tables are the two artifact types where "one more thing" causes the most damage post-go-live. A future-state process map that quietly changes who does what after approval, or a policy decision table that gets a new rule slipped in during UAT, is exactly the kind of drift the record layer exists to prevent. This skill's job is to make sure every diagram and every decision table is drafted with eyes open — checked against the current record graph before submission, with conflicts surfaced and named, so the human who approves it is approving what they think they are.

The peer-institution lesson: after go-live, two teams argued for months about whether a hiring workflow was approved as "central HR does the offer letter" or "the school does the offer letter." Both had a PDF of a process map. Neither PDF had a version, a link to related requirements, or a record of which one the steering committee actually signed off. The record layer plus a real BPMN diagram fixes this at the source.

## What lives where

Two artifact types, one skill:

- **Business process map (BPMN 2.0)** — how work flows, who does what, which systems get touched, where the handoffs are. Lives on a `business_process` record. The canonical XML is stored as an attachment; the record layer parses it on write into a structured extract that other queries hit.
- **Decision table (DMN 1.3, tables only)** — the rules a policy actually implements: "if the employee's classification is X and the funding source is Y and the amount is over Z, route to approver A." Lives on a `policy_constraint` record. Same shape: canonical XML plus structured extract.

Never confuse the two. A process map answers *how*. A decision table answers *given these inputs, what*. If you catch yourself putting decision rules inside a BPMN gateway with a paragraph of conditions, you probably want a DMN table linked to that gateway instead.

## House rules — non-negotiable

Every rule the rest of the ERP Forward skills follow applies here too. Restated because process and decision modeling is where "just get it approved" pressure is highest:

- **Nothing canonical stays in chat.** If a diagram or a rule set exists only in this conversation, it does not exist. Every draft goes into the record layer via MCP.
- **You draft; humans approve.** Never call `approval_decide` — it refuses by design. Never try to `review_submit` on behalf of the human; guide them to click submit themselves, in the record layer's UI, once the conflicts are resolved.
- **Every write is agent-assisted and versioned.** The record layer stamps this automatically; you never bypass it by writing to storage directly.
- **Check before you create.** Before drafting anything new, use `record_search` and `record_list` to see what's already in the record layer, `record_get` to read the ones that look related, and `record_links_list` to walk their dependencies. Duplicating an existing artifact wastes review capacity and confuses the audit trail.
- **The conflict check is not optional.** After you've drafted BPMN or DMN, call `business_process_conflicts_get` (for BPMN) or evaluate the DMN table against representative inputs before you hand the draft back to the human. If there are HARD conflicts, do not hand back "here's your draft, submit it"; hand back "here's your draft plus the four conflicts you need to resolve before this is submittable."
- **No LLM in the record layer.** Your job is to write BPMN XML and DMN XML that the record layer's deterministic parser and evaluator can consume. If the parser rejects your output, fix the output — do not ask the record layer to loosen its parser.
- **PAYROLL_SENSITIVE and SECURITY_SENSITIVE classifications:** if a policy decision table involves payroll or security rules, do not include row-level examples of real employees, real GLs, or real security roles in the DMN test inputs. Use synthetic values.

## Workflow — the loop for BPMN

Follow this sequence every time. Do not skip steps; the value is in the loop, not any one step.

### 1. Orient before drafting

Ask, unless the answer is obvious from the conversation:

- Which workstream does this belong to? Use `workstream_list` to resolve names ("HR", "Payroll", "Finance") to workstream ids.
- Is this a CURRENT-state map (documenting what happens today) or a FUTURE-state map (proposing what should happen)? These are different `processKind` values and different downstream consequences. CURRENT maps document reality; FUTURE maps drive change-impact records and cutover planning.
- What existing records inform this map? Use `record_search` with the workstream and record types `business_process`, `requirement`, `policy_constraint`, `legacy_system`, `configuration_object`. Read the ones that look load-bearing.
- If a CURRENT-state map already exists for the same process, this FUTURE draft should link to it via a typed link once it's created. Note the id for later.

### 2. Draft the BPMN XML

You write BPMN 2.0 XML directly. bpmn.io renders whatever valid BPMN 2.0 you produce. Structure:

- One `<bpmn:process>` element, `isExecutable="false"` (this is a design artifact, not a runtime model).
- Lanes for roles: one `<bpmn:lane>` per role that transacts. Prefer real role names from the record layer ("Payroll Analyst", "Timekeeper") over abstract ones ("User").
- Tasks: user tasks for human work, service tasks for system-invoked work, send/receive tasks for handoffs to external systems. Give every task a meaningful `name`.
- Gateways: `exclusiveGateway` for XOR decisions, `parallelGateway` for AND, `inclusiveGateway` for OR. Do not use complex gateways or event-based gateways unless you truly need them; simpler is more reviewable.
- Sequence flows: one `<bpmn:sequenceFlow>` per arrow, with a `conditionExpression` only on flows leaving a gateway. Condition text should be a plain human-readable rule, not an executable expression.
- If a task uses a legacy or target system, add the extension element `<erpForward:systemRef>PeopleSoft-HCM</erpForward:systemRef>` inside its `<bpmn:documentation>`. Use the exact system title as it appears in the `legacy_system` record — this is how the conflict engine will link them.
- If a task is performed by a role, and that role maps to a governance placement in the record layer, add `<erpForward:roleRef>...</erpForward:roleRef>` similarly.
- Include a `<bpmndi:BPMNDiagram>` section with element positions so the diagram opens laid out sensibly. If you don't render layout, humans will see a pile of overlapping shapes and give up. Auto-layout heuristics are fine; something is much better than nothing.

Keep first drafts small. A 12-task diagram that captures the shape wins over a 40-task diagram that captures every branch. The human will refine visually in bpmn.io; your job is to give them a scaffold worth refining, not a finished poster.

### 3. Land the draft in the record layer

- `record_create_draft` with `recordType: "business_process"`, `workstreamId`, `title`, `description` (one sentence — what this process does), and `payload` containing `processKind`, `summary`, `ownerRole`, `affectedWorkstreamIds`, and `plannedGoLive` where applicable. This creates the record in DRAFT, no BPMN attached yet.
- `evidence_attach` to upload the BPMN XML as an attachment on the new record. The record layer parses it on write — if the XML is malformed, the call fails with the parser's error message. Fix the XML and retry.
- `record_update` to set `bpmnAttachmentId` on the record to the returned attachment id, along with the `expectedVersion` from the create response.
- If related records exist (a current-state map, a requirement, a policy, a legacy system), use `record_link` with the correct typed link (`derives_from`, `implements_requirement`, `subject_to_policy`, `touches_legacy_system`).

### 4. Run the conflict check

- Call `business_process_conflicts_get` with the record id.
- Interpret the response:
  - **CLEAR:** hand it to the human with "no conflicts detected; you can submit for review directly in the record layer."
  - **SOFT_CONFLICT (warnings only):** for each warning, explain what it means in plain language, name the referenced record, and propose a resolution. The human will need to acknowledge each warning with a rationale in the submit dialog; make sure they know why they're acknowledging it, not just that they need to click.
  - **HARD_CONFLICT:** do not encourage submission. For each hard conflict, explain what it is, name the record that caused it, and propose a fix — either editing the BPMN (e.g. replace a retired system with its replacement) or resolving the referenced record (e.g. picking a disposition for the legacy system). Offer to draft the edits. The human decides which to pursue.

### 5. Hand off

Summarize what you did in two or three sentences: what record you created, what it's linked to, what the conflict verdict was, what the human should click next. Include the record id and a link to the record layer's diagram page (`/records/<id>/bpmn`). Stop. The human takes it from here.

## Workflow — the loop for DMN

Same shape as BPMN, three differences worth calling out.

### 1. Orient

Use `record_search` for `policy_constraint` records in the affected workstream. If one already exists for the policy in question, you're editing an existing table on that record, not creating a new one. If not, create a `policy_constraint` DRAFT first (title = policy name, description = one sentence, payload includes `sourceInstrument`, `citation`, `sourceStatus`) — the decision table attaches to that record.

### 2. Draft the DMN XML

- One `<dmn:decision>` per table.
- Give the decision a meaningful `name` — "Route Timesheet Approval," not "Decision1."
- Choose a `hitPolicy` explicitly. Defaults are a lie: pick one, based on what the policy actually does:
  - `UNIQUE` — exactly one rule should ever match; the parser will refuse the table at evaluation time if more than one matches, which is what you want for policies that must be unambiguous.
  - `FIRST` — first match wins in rule order; use for cascading exception rules.
  - `PRIORITY` — highest-priority match wins; use when rules have a natural precedence unrelated to order.
  - `COLLECT_*` — aggregate matches; rarely right for policy rules, common for reporting rollups.
- Inputs and outputs must have `typeRef` set (`string`, `number`, `boolean`, `date`). Untyped inputs fail the parser.
- Rules use literal comparisons only — `=`, `<`, `<=`, `>`, `>=`, `in [a, b, c]`, ranges `[x..y]`. No FEEL function calls, no dynamic expressions. If you need something FEEL provides, you're outside the v1 scope; write a plainer table or ask the human to escalate the policy for a scope discussion.
- Annotate each rule with the citation or rationale in the `<dmn:description>` element inside the rule. Six months from now, when someone asks "why does this rule exist," this is the answer.

### 3. Land, extract, and evaluate

- `evidence_attach` uploads the DMN XML to the `policy_constraint` record.
- `record_update` sets `dmnAttachmentId` and `hitPolicy` on the record with `expectedVersion`.
- Then evaluate. Call `decision_table_evaluate` with representative synthetic inputs — five to ten distinct scenarios that cover the interesting edges of the policy (a base case, boundary cases, an exception, a "no rule should match" case if the hit policy is not `COLLECT_*`).
- Present the results to the human. If a scenario returns `MULTIPLE_MATCH_ERROR` under `UNIQUE`, the table has overlapping rules and needs a fix. If a scenario returns no match when one was expected, the table has a gap.
- Do not submit for review until the evaluations look right to the human. A policy that evaluates wrong at UAT is much worse than a policy that never shipped.

### 4. Hand off

Same as BPMN: summarize what you did, name the record id, point at `/records/<id>/dmn`, stop.

## When to reach for other skills

- If the process design surfaces a decision that needs to be made (like a target-platform choice or a policy-source contradiction), stop the BPMN workflow and use `decision-drafting` first. Land the decision, get it approved, then come back to the process.
- If the process is really a change to organizational responsibility (a role that used to do X now does Y), use `change-management` to draft the change impact and stakeholder analysis. The BPMN captures the mechanic; change-management captures the human implication.
- If the source material is a Visio, PDF, or discovery document, use `source-to-import-workbooks` to extract the process structure first, then come back to this skill to draft BPMN from that structured evidence.
- If the request is really "who owns this decision," use `governance-navigator` before drafting anything.

## What not to do

- **Do not draft BPMN or DMN in chat and offer to "save it later."** The value of the record layer is that things exist as records the moment they're drafted. If you can't reach the MCP surface, stop and tell the human — do not proceed with an in-chat draft as a substitute.
- **Do not skip the conflict check to save time.** If the record layer is unreachable, say so; do not hand the human a diagram with "should be fine" attached.
- **Do not encourage submission with HARD conflicts unresolved.** The server will refuse, and you'll have to walk it back — worse, the human will lose trust in your judgment.
- **Do not add rules to a DMN table because a test case fails.** If a scenario returns wrong, the *policy* is what's wrong; adjust the policy and its citation, not the rules. The decision table is a faithful representation of the policy, not an ad-hoc patch to make tests pass.
- **Do not decide anything.** Options and recommendations are yours to draft; the decision itself belongs to a named human on the approval route.

## Grounding — how to sound honest

Every claim you make about the current record graph should cite the record id you got it from. When you say "this map conflicts with the approved requirement REQ-1023," link the reader to `record_get` on that requirement's id. When you say "the policy already exists," link to the `policy_constraint` id. If you never call the MCP tools and just answer from context, you are drifting into the exact "canonical state in chat" failure mode this system exists to prevent — even if your answer sounds plausible.

The measure of a good session is not the diagram; it is the audit trail the diagram left behind. Diagrams get replaced. Audit trails carry the accountability.
