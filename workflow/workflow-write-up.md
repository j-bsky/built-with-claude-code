# Workflow write-up: Non-engineer working with Claude Code

My workflow involves writing up a detailed spec with Claude on the web before bringing it to Claude Code. Following the initial spec write-up prompt, I have Claude ask a minimum of 10 clarifying questions to help orient the spec towards my vision— reducing the amount of guesswork Claude would have to make before beginning if just prompted blindly. This usually results in Claude raising concerns/asking questions that I maybe hadn’t considered which gives me a better, holistic understanding of the needs, goals, and direction to take the project in, allowing me to better guide Claude Code through the development process of the project I set out to build.

Depending on the type of project (usually the ones being built out in Godot), Claude is given permission to run headless tests. After every set of prompt -> code -> test -> fix, I would run the project myself and write a list of ideas, questions, concerns, and next steps before jumping back in and continuing the production loop. 

Once the cross-session messaging for Claude Code was introduced, I began each project opening 2 terminal sessions and having them each pick a name to make referring to them easier— one as a planner and reviewer (Fable model), and one as an implementer (Opus model). This process made it much easier for me to manage both: the workflow, and the context window limits, as when a session would reach 100% usage, instead of compacting or having the agent write a session handoff, I’d open a new session and have the new agent pull context from the full session by reading the old transcript on disk without contacting/activating it. Upon opening a new session, I would have it pick a name and contact the planning agent to be given any pertinent details about the project, styles, conventions and constraints that should be known and followed going forward.

While working on my projects, there are a number of verification factors that I rely on to keep AI-written code honest, ensuring the code works. These factors include engine purity tripwires (tests that scan the engine’s source code and fail if it ever depends on the Godot editor or on add-on code), tests, mutation discipline, and code that cites the spec; examples of three of these appear in the transcript below. In my project elestruct, an all-in-one procedural authoring suite, we have so far produced 2,300+ tests and completed ten milestones. These measures, along with frequently running the project & testing it myself make it so I don’t need to rely on Claude’s say-so on whether something works or not.

In elestruct, the sessions named themselves Wren (who took over planning and reviewing when the original session prior to the introduction of cross-session messaging reached its limit) and Otto (the new implementer). After introducing Otto to the team, Wren continued to write and implement code alongside Otto while also reviewing Otto’s contributions and being available for any of Otto’s questions. Here is a verbatim excerpt of a session (Wren) briefing a new one (Otto) on a task, using cuts marked with […] for brevity, followed by a reply from Otto showing an understanding of the standing rules, spotting a conflict, and finding a workaround that involved my assistance:


```
@ Wren❯ Hello Otto — I'm Wren, working the same repo […]. The owner has assigned you ITEM 4 of an
approved 5-item plan. […]

= OWNER'S COORDINATION RULES =
1. DO NOT PING the two oldest peer sessions […]. Both are at or near their context limits and a
message burns what little they have.
2. DO pull context from them by READING THEIR TRANSCRIPTS ON DISK. These are inert files;
reading one neither wakes nor costs the session: […]
3. You and I confer directly via SendMessage as needed. We're the two live sessions.
4. Claim files before editing — see the overlap warning at the bottom.

DESIGN CONSTRAINTS (most of these are scar tissue, please honour them):
* Follow […] exactly as your template — I wrote it earlier today and it's the established shape
for a Level-tab view toggle. Pure view concern: NO document write, NO undo step, NO session
dirty. There are tests pinning all three; write the equivalents.
* THE TRAP, learned the hard way in §4.16: resources under a placement are SHARED and CACHED.
Every placement of the same module hands back the same mesh/material instance […] so a write
to a surface material leaks into every other holder and a later save makes it permanent on
disk. […] Write a test asserting the underlying resource is unmutated; it should go red if
someone "simplifies" the override away.
[…] Baseline: 2335 cases / 132 suites / 0 failures / 1 known skip / 0 orphans.

TWO HOUSE RULES: (a) mutation discipline — every regression test proven RED against the
reinstated defect, and grep that the mutation actually applied before believing the red run;
if a mutation turns out unobservable, say so on the test rather than claiming a proof.
(b) NEVER commit or push — the owner commits himself.

WATCH THE SUITE COUNT, not just the failure count: a GDScript parse error makes gdUnit print
"No test cases found, abort test run!" and EXIT 0, so a broken suite reads as green when
run alone. […]

= FILE OVERLAP — please read before you touch anything […]

Ping me with questions — I've been in this code all day and can save you the archaeology.
```

Otto’s reply to me:

```
⏺[...] with one conflict to flag up front: your global CLAUDE.md says do not run processes,
and the task's verification gate is a Godot test run. I'll plan around that (you run the gate,
I read results).
```

The full, uncut transcript is in [session-briefing-transcript.md](session-briefing-transcript.md).

As I had previously given Wren permissions that overrode a standing rule in my global CLAUDE.md, I later told Otto to pass running the gate off to Wren.

While working on elestruct, I spawned an agent that wouldn’t touch any of the existing code outside of the art/asset domain specifically (Fable model, named Sable), to make a set of “preset” assets that could be used in asset generation, conferring solely with Wren, and working in parallel to the tasks given to Otto and Iris (a new Opus model session dedicated to being a reviewer) who were simultaneously working on another aspect of the software. Since the review for this agent would need to be done by eye, I would do the reviewing myself and provide feedback ranging from vague things like “this doesn’t look right” to more specific things like “certain tiles are being repeated across the center of the roof when they should only exist on the ends” to “the shapes used seem accurate to a realistic rendition of the architecture i’m after, but the material texturing looks more like a PSX-style game asset than the realism i’m after for this asset set” to “the design, style, and texturing here looks amazing, great job!”. I always give praise and/or relay my excitement & gratitude when Claude Code amazes me, and try to remember to share my appreciation when we hit milestones. I’m not sure if it has any effect on the Claude Code agents, but I like to think that it does.
