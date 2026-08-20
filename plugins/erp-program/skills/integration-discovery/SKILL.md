---
name: integration-discovery
description: Discover and catalog PeopleSoft integrations from Pack 2 and Pack 4 extracts — Integration Broker nodes/messages, file feeds, journal sources, scheduled interface processes — and draft the interface inventory for the new ERP. Use this whenever the user mentions integrations, interfaces, feeds, APIs, Integration Broker, connected systems, "what talks to PeopleSoft", or asks what will break when PeopleSoft is retired.
---

# Integration Discovery

The question behind this skill is brutal and specific: **what breaks the day PeopleSoft turns off?** Every undiscovered integration is a system that fails silently at cutover. Discovery must therefore be multi-source and paranoid — no single extract shows everything.

Read `../../references/extract-library-guide.md` first.

## The four evidence sources (use all of them)

1. **Integration Broker (P2)**: PSNODEDEFN is the connected-systems list — every node is a system that talks to PeopleSoft. Messages/service operations show what they exchange; P4 IB traffic aggregates show which are alive and at what volume.
2. **Batch feeds (P2 + P4)**: scheduled processes whose names/descriptions smell like interfaces (EXTRACT, EXPORT, IMPORT, FEED, INBOUND/OUTBOUND, vendor names). P4 run frequency tells you cadence: nightly = operational dependency; monthly = reporting or compliance.
3. **Journal sources (FSCM P3)**: PS_JRNL_SOURCE_TBL is finance gold — every feeder system posting to the GL has a source code. Cross-check each against the node list; a journal source with no matching node is a file-based feed to hunt down.
4. **The absence list**: known enterprise systems (ask the user: clinical systems, LMS, badge, credentialing, timekeeping, bank, benefits vendors, state/federal reporting) that DON'T appear in the evidence — each is either genuinely disconnected or integrated through a path the extracts can't see (manual upload, shadow SFTP). The absence list is an interview agenda, not a conclusion.

## Draft the interface inventory

One row per interface: name (business language), counterpart system, direction, mechanism (IB/file/manual), data domain, observed frequency and volume (P4), evidence (which source(s) above), liveness, criticality guess (operational daily vs periodic reporting), disposition draft (REBUILD_TO_TARGET, RETIRE_WITH_SOURCE, REPLACE_WITH_VENDOR_STANDARD, INTERIM_BRIDGE_NEEDED — flag interfaces needing a bridge if pillars go live at different times), confidence.

Interfaces appearing in only one evidence source get LOW confidence by default — corroboration is the game. The EmplID master-person-index consumers deserve explicit callout: anything consuming EmplID is on the highest-risk list per the program's crosswalk rules.

## Landing the output

Per `../../references/output-conventions.md`: inventory CSV + executive summary (headline: total interfaces, live count, criticality mix, absence list). DRAFT integration_interface records via MCP when connected. End with unknowns and the interview agenda.
