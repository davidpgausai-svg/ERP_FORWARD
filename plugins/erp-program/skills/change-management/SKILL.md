---
name: change-management
description: Run ERP FORWARD change management work — change impacts, stakeholder analysis, communications and campaigns, readiness surveys, the Change Network, and training needs analysis and curriculum. Use this whenever the user mentions change management, change impacts, current state vs future state, stakeholders or audiences, communication plans, campaigns, readiness or adoption, resistance, Change Champions, Super Users, readiness workshops, training curriculum, TNA, job aids, train-the-trainer, hypercare, or ADKAR. Also use it when design-session notes, decision documents, meeting transcripts, or survey results are shared and the real question is how people will be affected and what they need to hear, learn, or do — even if the words "change management" are never said.
---

# Change Management (ERP FORWARD)

Change management on this program is not a communications function. It is the discipline of turning design decisions into a role-based account of what a person's Tuesday will look like after go-live, and then making sure that person hears it, believes it, and can do it. Everything below serves that.

Two structural facts shape every output. First, this is two implementations on overlapping clocks: **ERA** (pre-award grants administration, go-live Fall 2028) and **ERP** (Finance, SCM, HCM, coordinated go-live July 2029). Never write "go-live" unqualified — always say which one. Second, the audience spans four academic campuses and a seven-hospital, fifty-plus-clinic health system. The same change lands differently on a research administrator, a nurse manager, and a central AP clerk, and a deliverable that ignores that distinction will be politely ignored in return.

Read `references/um-change-strategy.md` for the UM-specific parameters: population figures, the Change Network tiers and selection criteria, the MUHC communication cascade, exact field lists for each inventory, and the campaign taxonomy. Read it before producing any inventory row, plan entry, or curriculum line — those field lists are the schema the program's Smartsheet trackers expect, and inventing a field creates rework at import.

## Pick the job

Match what the user brought you to one of these. If two apply, do the upstream one first and say so — impacts feed communications and training, never the reverse.

| What the user brought | Job | Section |
|---|---|---|
| Design notes, transcript, decision record, "what changes for people" | Change impact capture | Below |
| "Who is affected", audience lists, WIIFM, resistance | Stakeholder analysis | Below |
| "We need to tell people", announcement, campaign, plan entry | Communications | Below |
| Survey results, "are we ready", adoption risk, sentiment | Readiness measurement | Below |
| Champions, Super Users, workshops, local rollout | Change Network | `references/um-change-strategy.md` |
| Courses, curriculum, TNA, job aids, trainers | Training | Below |
| Post go-live, hypercare, sustainment, ongoing training | Stabilization | `references/um-change-strategy.md` |

## Change impact capture

A change impact is the practical difference between current state and future state for a named group of people. It is not a project update and not a feature description. "Requisition approvals move to a mobile-capable workflow" is a feature; "department approvers will approve requisitions on their phone and will no longer receive the Tuesday paper batch" is an impact.

Capture these eight fields, no more and no fewer, because this is the inventory schema:

Change Title · Change Description · Current State · Future State · Impacted Stakeholders · Change Level · Perception of the Change (optional) · Change Management Intervention(s)

Working from a transcript or decision document is the normal case, and it is the reason a change person does not have to sit in every design session. Extract candidate impacts, then be honest about what you are handing over: these are **drafts for SME validation**, not confirmed impacts. Mark each one's confidence and cite the source document and date per `../../references/output-conventions.md`. An impact whose current state you inferred rather than heard is a question for the validation session, so write it as one.

Two failure modes worth naming. Impacts written at system level ("PeopleSoft is being replaced") are useless — push every one down to a role and a task until it names something a specific person stops or starts doing. And a change level assigned without a stated reason is noise; say why it is high, medium, or low in the same breath.

Validated impacts are the input to communications sequencing, engagement priority, and the training needs analysis. When you finish an impact set, say which of those three it should feed and what it implies for them.

## Stakeholder analysis

Stakeholder work already exists from the Readiness Phase. Refine it, do not restart it — ask what has been done before producing a new segmentation, and build on the existing Stakeholder Analysis rather than beside it.

For each group capture: role and process and technology impact, the benefits they will actually feel, their likely concerns, preferred channels, and the answer to "what's in it for me" written in their language rather than the program's. The WIIFM is the part that determines adoption, and it is the part most often written as a platitude. If the honest answer for a group is that this change costs them time and gives them nothing personally, say that plainly and treat it as a resistance risk requiring leadership air cover, not a messaging problem.

Segment by how work is actually performed, not by org chart. Academic units, central administrative functions, and clinical environments experience the same change differently, and clinical staff have coverage constraints that make some interventions impossible regardless of how well designed they are.

## Communications

Every planned communication carries these ten fields:

Communication Title · Description · Topics · Audience · Delivery Vehicle · Frequency · Delivery Date · Content Owner · Sender · Review Checkpoints

Prefer existing channels over new ones. People do not check a project website; they read the newsletter they already read and attend the meeting they already attend. Inventory the real vehicles first, then place the message into one.

Organize messages into campaigns rather than one-offs — What's Changing, Training, Cutover and Go-Live, plus others as they are defined. A message that does not belong to a campaign usually means the audience or the purpose has not been thought through, so ask rather than filing it.

For MUHC, route through the leadership cascade rather than mass email: Health Executive Leadership, then the monthly Directors meeting, then the monthly All-Leader meeting, then manager team huddles. Content written for that cascade must be usable by a manager who has ninety seconds in a huddle and no project context. That is a different artifact from an email, and drafting one when the other is needed is the most common miss here.

When drafting actual message content, follow the program's writing conventions: plain language, lead with what the reader must do and by when, black text, no divider bars. Nothing goes out without human review and approval — draft, never send, and say so.

## Readiness measurement

Survey fatigue is real and the program's credibility depends on asking sparingly and acting visibly. Before proposing a survey, ask what was already asked and when. If the answer is recent, propose using existing channels — Change Network feedback, leadership input — instead.

Two distinct instruments serve different questions. The Plan-phase **organizational readiness assessment** measures leadership alignment, communication clarity, credibility of prior change efforts, and stakeholder involvement; it is the baseline everything later is compared against. **End-user readiness assessments** at checkpoints (phase completion, Change Network launch, testing kick-off) measure confidence, knowledge gaps, saturation, and resistance by population.

When analyzing results, produce a readout that leads with the three things leadership must act on, names the populations at adoption risk, and proposes specific interventions with owners. Compare to the prior cycle whenever one exists — the trend is more informative than the absolute score, and a flat score after an intervention is itself a finding. Do not average away a small population with a bad result; a single school or hospital unit in trouble is the point of the exercise.

Never report free-text themes without indicating how many responses sit behind each one, and never present a sampled or partial-response result as if it covered everyone.

## Training

Two sequential artifacts, in this order. The **Training Needs Analysis** captures functionality and topics requiring training, the audiences needing each, and delivery methods. It is not courses. The **curriculum** turns that into the actual content inventory, carrying: Functional Area · Process Area · Course Title · Description · Topics · Delivery Method (ILT, eLearning, Job Aid) · Duration · Course Owner · Course SME · Security Roles.

The Security Roles column is the one that gets skipped and the one that hurts most later — training assignment and system access are the same list, and disconnecting them produces users with access and no training on day one.

Curriculum must be validated by functional SMEs before any content is built. If a user asks for course content before curriculum sign-off, say what that risks rather than just complying.

Delivery is a train-the-trainer model: UM and MUHC staff deliver instructor-led training to their peers, with functional SMEs in the room as the expert who answers detail questions rather than as the lead trainer. Match modality to constraint — blended and self-paced for faculty schedules and clinical coverage, live sessions where hands-on practice genuinely requires it. Two environments exist and should be named correctly: the **Training System** for development, delivery, and in-class exercises, and the **Sandbox** for self-directed practice in defined windows. Training data is realistic but personal data is masked.

## Landing the output

Per `../../references/output-conventions.md`. Change impacts, communications, and curriculum lines are inventory rows destined for the program's Smartsheet trackers, so produce them as CSV with exactly the field names above, in that order, so they import without rework. Narrative deliverables (survey readouts, strategy sections, leadership briefs) are markdown. When the record layer is connected, call `schema_get` first and write as DRAFT.

Nothing here is approved by you. Change impacts require SME validation, communications require content owner and sender approval, curriculum requires SME sign-off. Hand over drafts and name who has to bless them.

Close every deliverable with what you could not determine and why. On this program the unknowns list becomes the agenda for the next SME session, which makes it the most immediately useful part of the output.

---

## Self-Improvement

At the end of every run, before ending:
1. Did any step fail or need a workaround?
2. Did the user correct or reject anything meaningful?
3. Did you discover something a future run might need?

Only propose a change if it meaningfully improves the skill. Surface it as a
proposed edit for human approval - never edit the installed copy. Approved
changes go back to this repo via PR.
