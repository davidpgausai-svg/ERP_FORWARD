---
name: operating-model-setup
description: Run the Target Operating Model (TOM, "Op Model") setup interview in Keystone (ERP Forward). Capture what leadership decided, one question at a time, and draft each agreed answer for the Program Director or a Super Admin to sign. Program principles first (where the work happens, the same-or-different rule, shared services, sequencing), then each pillar (functions and delivery, roles, real differences, open decisions, after go-live). Use this whenever someone says "Start Operating Model setup" or "Set up the Procure-to-Pay operating model", pastes a prompt from the Operating Model page, shares an implementation partner deck (such as a Huron PowerPoint), steering notes or a transcript about the operating model, org structure, roles, service delivery or shared services, or asks about the TOM, Op Model, role types, or centralizing versus distributing work. Requires the ERP Forward connector.
---

# Operating Model Setup

Executives decide the operating model. This skill gets their decisions into ERP Forward, so process lanes, Roles & Access, testing and training all work from the same roles. Nobody fills in a spreadsheet: you read what leadership decided, propose each answer, and draft what the person agrees to. The Program Director or a Super Admin signs.

The people in this conversation are program leadership: the Program Director, PMO, workstream and pillar leads, or a Super Admin. They are busy and are not organization-design specialists. Hold the context for them: one question at a time, plain words, a proposed answer to react to, and nothing left only in chat.

## Start every run the same way

1. Call `operating_model_setup_get`. It returns the four program principles, then each governed pillar's five questions, each with the question, why it matters, what signing changes, the product's starting point, common answers, any draft or signed answer, and a state: `NOT_STARTED`, `DRAFTED` (waiting for a signature), `SIGNED`, or `REVISING` (signed, with a revised draft waiting). `next` is the question to work on.
2. Tell the person where things stand in two lines: how many principles are signed, which pillars are under way, and what is next.
3. Start at `next`, unless they named a pillar or a question. Principles come first: if a pillar is requested while principles are unsigned, say so once, then do what they asked.

If `operating_model_setup_answer` refuses with 403, the person isn't program leadership. Say who drafts answers and stop drafting; you can still read and explain.

## Read what leadership decided first

The best source is what the executives decided, not a fresh opinion. When the person shares a deck (the implementation partner's PowerPoint), a PDF, steering notes or a transcript:

- **Read all of it before asking anything.** Work out which slides answer which setup question.
- **Propose each answer from the source and cite it**: "Slide 7 says AP moves to a system-office shared service center." Put the citation in `source`, for example `Huron Operating Model deck, 12 Nov, slides 6-8`.
- **Say what the source doesn't settle.** If a slide is marked draft or for discussion, or the deck is silent on a question, say so plainly and offer the starting point and common answers instead. Never present your own guess as a leadership decision.
- **Keep the deck's words** where they are precise. Translate jargon only to make it clearer.

Decks arrive as decisions are finalized, so a run can be partial: draft what is decided, leave the rest undecided, and pick it up when the next deck lands.

## Each question, one at a time

- **Ask the question** in the tool's words, with the pillar named.
- **Explain why it matters** in one or two sentences from `whyItMatters`.
- **Propose an answer**: from the source if there is one, otherwise the starting point, with the common answers as alternatives.
- **Let them decide.** Read the agreed answer back as one or two clear sentences, then call `operating_model_setup_answer` with the `key`, the `pillar` (pillar questions only), the `answer`, `optionsConsidered` (one per line), `impact` (what it means for the build) and `source`.
- **Say what happens next:** "That's a draft. The Program Director or a Super Admin signs it on the Operating Model page; until then it's a proposal." Then move on.

Never call `operating_model_setup_answer` with an answer the person didn't agree to. If they want to think, leave the question undecided and move on. If a question is `SIGNED` and they want to change it, draft the revision the same way; the signed answer stays in force until the revision is signed. If it's `DRAFTED`, calling the tool again updates the same draft.

## The program principles

- **Where the work happens:** the continuum from trained department staff doing their own transactions in the ERP to generalists requesting from consolidated teams who do every transaction. Most land in between, and differently by function.
- **Same or different:** what justifies keeping a difference between institutions (for example a health system, the academic side and other campuses), and how a difference is handled. Different doesn't have to mean a separate team: a process variation, a different way to request, or a different service level comes first.
- **Shared services:** default, optional or retired, and whether requests start in the ERP or in an email inbox.
- **Sequencing:** what changes before go-live (often reporting lines only), at go-live, and after.

Use the signed principles when you propose pillar answers, and point out when a pillar answer departs from one.

## The pillar questions

- **Functions and delivery:** the functional org chart: functions and where each sits (department, campus, system office), by institution. Not positions, not people.
- **Roles:** role types, never people. Name each role the way process lanes should read. For each, give `deliveryModel` (SELF_SERVICE, DEPARTMENTAL, CENTRAL, SHARED_SERVICE_CENTER, REGIONAL_CENTER, EMBEDDED_POD, TIERED, PENDING_DECISION), and when known `location`, `systemTouch` (DOES_THE_WORK, APPROVES, REQUESTS, VIEWS_ONLY) and `responsibilities`. Call `operating_model_get` for the pillar to see the lanes in its approved processes: propose roles that cover them, and list a lane's other names in `laneNames`. Add `enterpriseRole` only when Roles & Access already names it. Pass the full list every time; it replaces the previous draft list.
- **Real differences:** what is really different between institutions in this pillar, not just historically different, and how each is handled under the same-or-different principle.
- **Open decisions:** what is still undecided, who decides it, and by when. Offer to draft each as a Decision record (the `decision-drafting` skill), and ask first.
- **After go-live:** the owner, who approves configuration changes, two or three KPIs and data stewards, in `runOwnership`.

## What signing does

- **Roles:** creates the pillar's operating model if it has none, and creates or updates its TOM roles as drafts. Roles already in review or approved are left unchanged and reported. Roles missing from the signed list are never deleted; the Operating Model page flags them.
- **After go-live:** fills in the operating model's owner, change approver, KPIs and data stewards.
- Every other answer is recorded as a signed decision.

## What you cannot do, and say so plainly

- You cannot sign, withdraw or submit these answers. Only the Program Director or a Super Admin, signed in to Keystone directly, signs. That signature is the approval; there is no review route.
- Don't create these answers with `record_create_draft` or edit them with `record_update`. Use only `operating_model_setup_answer`.
- Don't create `operating_model` or `tom_role` records yourself; signing the Roles answer does that.
- Never describe a DRAFT answer as decided, and never put a person's name in a role.

If the person is the Program Director or a Super Admin, still don't treat their "yes" in chat as a signature. Point them to **Operating Model → Setup → Sign**.
