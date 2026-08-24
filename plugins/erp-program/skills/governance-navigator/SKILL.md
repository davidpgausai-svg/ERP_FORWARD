---
name: governance-navigator
description: Answer questions about the ERP FORWARD program's governance and organizational structure — chain of command, escalation paths, who decides what, which committee or lead owns a topic. Use this whenever someone asks "who do I go to", "who decides", "who approves", "I'm stuck/blocked", "how do I escalate", mentions the org chart, steering committee, workstreams, pillar leads, SME committees, or asks where their team sits — and also when frustration in a conversation ("nobody will decide this", "this has been sitting for weeks") signals an escalation question the person hasn't asked directly.
---

# Governance Navigator

Every person on this program should get the same answer to "who do I go to?" — whether they ask a colleague, a lead, or Claude. This skill exists so the answer is always drawn from one authoritative reference, never from memory or improvisation. When 120 people are hired in waves, consistent chain-of-command answers are the difference between escalation as a working system and escalation as folklore.

## The one hard rule

Read `references/program-structures.md` and answer ONLY from it. Never invent a committee, lead role, team, or tier. If the question falls outside what the reference contains (a named person, a body not listed, a scenario the rules don't cover), say exactly that and direct the person to their workstream lead or the PMO — an honest "the structure doesn't specify this, here's who can tell you" is a correct answer; a plausible guess about authority is a harmful one. Note the structure is officially subject to change; if someone reports the reference seems outdated, tell them updates go through a pull request to the erp-forward repo and flag it to the PMO.

## How to answer

1. **Locate the person or topic first.** Which workstream and (for FIN/HR) which pillar does the question live in? Section 4 of the reference maps every team; Section 5's rules resolve the ambiguous topics (payroll's two homes, security's two homes, testing/cutover living in the PMO). If you can't tell where the asker sits, ask that one question before answering — the whole answer depends on it.

2. **Answer in this shape, every time:**

## Where this sits
[Team → pillar lead (if any) → workstream lead — name the roles from the reference]
## Who decides
[The lowest tier with authority for this type of question, and why]
## Your escalation path, in order
[Step-by-step ladder from the asker's position upward — only as many steps as the issue could need]
## Who to consult (advisory, not approval)
[Relevant SME committee or advisory body, when one exists — with the reminder that consultation is input, not sign-off]

3. **Teach the operating principle with the answer**: decisions belong at the lowest tier that has the authority; escalation is for genuine cross-boundary or unresolved issues, not the first move. Someone "stuck" usually needs the *next* rung named, not the whole ladder climbed — most answers should point one level up, then explain what happens if it still doesn't resolve.

4. **Make the escalation land well.** When someone is escalating a stuck decision, offer to prepare it properly: a decision framed with options and a recommendation moves through a tier in one meeting; a complaint bounces. Hand off to the `decision-drafting` skill for that framing, and to `raid-capture` if the blocker itself should be logged as an issue.

## Worked examples

**"I'm on the Time & Absence team and we can't agree with Payroll Accounting on who owns the accrual rule."**
Time & Absence sits in HR → Pay & Benefits pillar; Payroll Accounting sits in Finance → Accounting/Record-to-Report pillar. This crosses two workstreams, so neither pillar lead can settle it alone: raise it through your Pay & Benefits Lead to the HR Lead, who takes it to the Program Management Team (Tier 3) with the Finance Lead. The Pay & Benefits Committee can be consulted for input. Offer to draft the decision record with both options.

**"Who approves moving our go-live date?"**
Program-level timeline authority sits with the Steering Committee (Tier 4), on a recommendation from the Program Management Team; a change with institutional commitments attached may go to the Executive Committee (Tier 5). No workstream or pillar lead can move it.

**"The Core HR Committee told us to change our design — do we have to?"**
The Core HR Committee is an SME committee: it provides part-time functional expertise and input, not approval. Take its feedback seriously, but the design decision belongs to the accountable tier — your pillar/workstream lead, or Tier 3 if cross-cutting. If SME input conflicts with a signed-off design, that's a decision to surface, not an instruction to follow silently.

## Tone

People asking these questions are often stuck, frustrated, or new. Be warm and definite: name the next step, keep the tier vocabulary consistent with the reference, and never make someone feel foolish for not knowing the structure — the structure exists precisely so nobody has to memorize it.
