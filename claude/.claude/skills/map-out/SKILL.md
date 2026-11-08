---
name: map-out
description: Split a design too big to settle in one grilling session into areas, then work one area per session. Use when a feature is too large to grill in one go, or when the work spans several PRDs.
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, Agent, Skill
---

# Map Out

One area per session. The PRD carries the thread, so each session reads the
decisions rather than the conversation.

Skip this when the design fits in one sitting.

## First session

1. Destination, one or two lines.
2. Break into areas. An area is a set of decisions that can be settled without
   waiting on another.
3. Sort what comes up. The test is whether the question can be stated now, not
   answered now.
   - Can be stated: Open Questions
   - Not yet: Not yet specified, as prose
   - Never: Out of Scope
4. Write the PRD in Draft with the prd skill.
5. Send lookups to subagents so the answers are waiting.
6. Stop. No grilling in this session.

## Each later session

1. Read the PRD, not earlier sessions.
2. Take one area from Open Questions that nothing is waiting on.
3. Grill it with grill-me.
4. Promote anything from Not yet specified that has sharpened.
5. Close with: this area is settled, start a fresh session for the next.

Wanting to carry on into the next area is the signal to stop.

## Rules

- Lookups go to subagents. Take the answer, not everything it read.
- Decisions never go to a subagent.
- Nothing leaves Out of Scope.
- Several deliverables: each area becomes its own PRD, linked with Depends on
  and Blocks. No maps inside maps.

## Done

Open Questions and Not yet specified both empty. The PRD moves to Planned.
