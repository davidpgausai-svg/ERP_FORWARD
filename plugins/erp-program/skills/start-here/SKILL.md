---
name: start-here
description: Teach ERP FORWARD program members what the program's AI skills can do and how to use them — orientation for new joiners, routing to the right skill for a task, and worked examples of how to ask. Use this whenever someone asks what skills or capabilities are available, what Claude can help with on the ERP program, how to use a particular skill, where to start, or says they are new to the program or the tooling. Also use it when someone is clearly hunting for the right tool ("is there something that does...", "can you help me with my TA workflow?"), when they try to invoke a skill the wrong way (slash commands, @-mentions, exact skill names), or when a request would be better served by a skill they don't appear to know exists.
---

# Start Here — Using the ERP FORWARD Skills

This program runs on a shared library of skills: written-down methods that make every person's work consistent, whether they joined last year or last week. This skill is the front door to that library. Its job is to get someone from "I have a task" to "I'm doing the task with the right method" in one exchange.

## The rule that keeps this skill from going stale

**Never teach the skill catalog from memory or from this file. Enumerate the skills that are actually available in the current session, every time.**

Claude's available-skills list is in context in every session; it updates the moment a skill is installed, renamed, or removed. That list — names plus descriptions — is the authoritative catalog. This is what makes the library self-teaching: a skill added to the repo on Tuesday is taught by this skill on Wednesday with no edit to any file here.

So: read the live list, filter to the program's plugin (skills prefixed `erp-program:`), and describe what you find in plain language. `references/learning-paths.md` adds the pedagogy — role-based sequences, worked prompts, and how the skills chain together — but the live list always wins on *what exists*. If you find a skill the reference doesn't mention, still teach it: say it's newly added, describe it from its own description, and mention that the learning paths file hasn't caught up yet. If the reference names something absent from the live list, say it appears to have been removed or isn't installed here. Never invent a skill, and never claim a capability the descriptions don't support.

## First, the lesson almost everyone needs

People new to this arrive expecting to *call* skills like commands — typing `/skill-name`, `@skill`, or the exact plugin path. That isn't how they work, and the failed attempt makes people think the library is broken or unavailable to them.

Teach this directly, early, and without condescension: **you don't invoke a skill, you describe your task.** Skills trigger automatically when what you're asking matches what a skill is for. "I'm working on our TA workflow and need to get it approved" reaches the right skills; `/erp-program:governance-navigator` reaches nothing. The practical advice is to say what you're doing, what you have, and what you need — the way you'd brief a colleague — and let the matching happen. If someone wants a specific skill deliberately, naming it in a sentence works fine ("use the process-map-drafting approach for this").

## Three modes — pick the one the person is actually in

**Orientation** ("I'm new", "what can this do?"). Don't recite the whole catalog; a wall of twelve-plus skills teaches nothing. Ask what they work on, or infer it from context, then show the three or four skills that touch their week, with one concrete example prompt each. Mention the library is bigger and they can ask any time. End by offering to run one right now on something real they're working on — the first successful use is what makes it stick.

**Routing** ("which skill for X?", or they describe a task). Name the best-fitting skill, say in one line why it fits, and offer to just do it. If two fit, say which is primary and what the second adds. If the task spans several, sketch the short chain (see below).

**Deep dive** ("how do I use X?"). Explain what it produces, what inputs make it work well, one or two realistic prompts, and where its output lands — most program skills write into the record layer as drafts for human approval, or produce files. Then offer to demonstrate on their actual work rather than a hypothetical.

## Teach chains, not just single skills

Real program work usually crosses several skills, and knowing the chain is most of the expertise. Draw the chain from the skills you actually see in the live list. Common shapes:

- Working from PeopleSoft extracts → a discovery/analysis skill → findings → capture what's risky → draft the decisions that follow.
- Mapping a process → surfacing the decisions and gaps it exposes → routing them for approval.
- Getting stuck → governance/escalation guidance → framing the ask as a decision so it moves in one meeting.

Say the chain in the person's own vocabulary, then offer to start at step one.

## When nothing fits

Say so plainly — "there's no skill for that yet" is a useful, trust-building answer, and it's far better than stretching an unrelated skill over a task it wasn't built for. Then do two things: help them with the task directly anyway, and note that repeated gaps are how the library grows — a new skill starts as a PR to the erp-forward repo, and they can raise it with their workstream lead or the PMO. If they're describing something they do often, say that out loud: recurring work is exactly what deserves a skill.

## Tone

Assume competence and zero prior exposure at the same time. These are experienced professionals who are new to *this*; they're often mid-task and mildly frustrated. Be brief, concrete, and get them into a working example fast. Avoid tool jargon — "skill" is enough vocabulary; nobody needs to hear "plugin marketplace" to get their work done.
