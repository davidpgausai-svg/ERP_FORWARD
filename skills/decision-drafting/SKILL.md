---
name: decision-drafting
description: Draft ERP program decision records — the question, options, recommendation, and approval routing. Use this whenever the user needs to decide something, asks for options or a recommendation, says "we need to pick/choose/settle", mentions a design decision or trade-off, or when a conversation reveals an unmade decision that is blocking work. Also use it to write up decisions already made verbally so they become records.
---

# Decision Drafting

The peer-institution lesson behind this skill: after go-live, nobody could tell whether a behavior was vendor-standard or a local choice, and every problem became a finger-pointing match. The cure is cheap — every consequential choice gets a decision record with options, rationale, and a named approver, written when the decision happens, not reconstructed later.

## When a decision is hiding in plain sight

Conversations constantly contain unmade decisions ("we'll probably keep Phenom", "someone should pick the cutover weekend"). When you spot one blocking real work, surface it: "That's a decision worth recording — want me to draft it with options?" Decisions already made verbally deserve records too; offer to write them up before the rationale evaporates.

## Structure

Use this exact shape:

# Decision: [the question, phrased as a question]
## Context — why this must be decided, and by when
## Options
(2–3 realistic options; for each: description, pros, cons, cost/effort,
impact on payroll/union/compliance/timeline where relevant)
## Recommendation — which option and the honest why
## Standard vs custom — does this deviate from vendor-delivered behavior?
   (If yes: record the rationale here. This line is the finger-pointing vaccine.)
## Decision maker and approvers — who has the authority; route accordingly
## Consequences of deciding late

Fewer, better options beat option sprawl: two real options and a recommendation move faster than five hedges. If the user's framing has only one option, that's not a decision record — it's an announcement; say so and either find the real alternative or write it as a decision already made.

## Landing the output

Per `../../references/output-conventions.md`: create a decision record (DRAFT) via MCP when connected — schema.get first, link related requirements/RAID items/config objects, cite sources — and route to the named approver via submit-for-review once the user confirms. Never mark a decision approved yourself; the approval is the human's signature, and the system enforces that for good reason. Unconnected: save as markdown in the decisions folder using the same structure.
