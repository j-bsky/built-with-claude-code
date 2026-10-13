# Workflow transcript of one session briefing another

This is the full transcript that the excerpt in the workflow write-up is taken from. It is verbatim except for three file paths, where my home folder and project folder are replaced with `<repo>` and `<project>`, and long lines are wrapped for legibility.

---
```
  pick a name like "Claude" -- and i'll /rename you

⏺ Otto — short, easy to say, easy to type.
Run /rename otto and I'll answer to it.
✻ Churned for 3s

❯ /rename Otto
⎿ Session renamed to: Otto
※ recap: You wanted a shorter session name that's easier to refer to. I suggested "Otto";
next step is for you to run /rename otto, or tell me a different name you'd prefer. (disable
recaps in /config)

@ Wren❯ Hello Otto — I'm Wren, working the same repo (<repo>). The owner has assigned you
ITEM 4 of an approved 5-item plan. Plan file:
~/.claude/plans/can-you-build-up-sparkling-floyd.md — read it in full; below is the part
that's yours plus the rules the owner set for how we work.

= OWNER'S COORDINATION RULES =
1. DO NOT PING the two oldest peer sessions — m5-level-tab-revival and
  elestruct-codebase-review. Both are at or near their context limits and a message burns
  what little they have.
2. DO pull context from them by READING THEIR TRANSCRIPTS ON DISK. These are inert files;
  reading one neither wakes nor costs the session: ~/.claude/projects/<project>/*.jsonl —
  one JSON object per line, filter type == "user" for the owner's own words, grep for your
  topic. This is how I recovered a requirement after the planning peer hit limits; their
  M5/M6 design rationale is all still in there.
3. You and I confer directly via SendMessage as needed. We're the two live sessions.
4. Claim files before editing — see the overlap warning at the bottom.

= ITEM 4: PROTOTYPE COLOUR VIEWER = A view toggle in the Level tab that flattens every
placement's faces to solid colours so you can read form and orientation without textures.
SEMANTICS (owner's own words, don't re-derive them): "each surface face would be simplified
down to a different color, with the colors facing in a consistent direction if not
explicitly rotated or flipped." That means colour by WORLD-SPACE FACE NORMAL — every
module's +X faces get the same colour, so a wall that should face +X but is flipped shows
the -X colour and the error is visible at a glance. That IS the feature; don't colour by
material slot or per-triangle.

DESIGN CONSTRAINTS (most of these are scar tissue, please honour them):
* Follow app/level/level_animation_preview.gd exactly as your template — I wrote it earlier
  today and it's the established shape for a Level-tab view toggle. Pure view concern: NO
  document write, NO undo step, NO session dirty. There are tests pinning all three; write
  the equivalents.
* Apply as material_override on each MeshInstance3D. NEVER write a surface material.
  Toggling off is material_override = null, which restores the real look exactly. GUARD:
  only set when the override is currently null; warn rather than clobber if one ever already
  exists.
* THE TRAP, learned the hard way in §4.16: resources under a placement are SHARED and
  CACHED. Every placement of the same module hands back the same mesh/material instance, and
  the Rig tab's document may hold them too — so a write to a surface material leaks into
  every other holder and a later save makes it permanent on disk. My analogous near-miss was
  writing loop_mode onto a shared Animation. Write a test asserting the underlying resource
  is unmutated; it should go red if someone "simplifies" the override away.
* ONE shared ShaderMaterial for the whole level. This works precisely BECAUSE world-normal
  colour needs no per-instance parameters — say so in the file so nobody "fixes" it into a
  material per placement.
* Scope to COMMITTED placements only (children of workspace.geometry_root()), not the
  placement ghost — a ghost override would fight the ghost tint.
* Re-apply on the workspace's changed signal so newly placed / redone placements pick up the
  colours without re-toggling. See how level_main_screen.gd calls
  animation_preview.refresh(...) at the end of _on_workspace_changed.
* Test the MECHANICS (override applied to every mesh, removed cleanly, no document/undo
  effect), not pixels. Shaders cannot compile headless — the gate is windowed anyway.

FILES: new app/level/level_prototype_colors.gd + a .gdshader, tests in tests/app/, toolbar
toggle in app/level/level_main_screen.gd. GATE (windowed only, -c mandatory, and it MUST be
Godot 4.7 — /Applications/Godot.app is 4.6.2 and cannot parse this
project): GODOT="/Applications/Godot 4.7.app/Contents/MacOS/Godot" cd <repo> "$GODOT" --path
. --display-driver macos --rendering-driver metal -s addons/gdUnit4/bin/GdUnitCmdTool.gd -c
-a  addons/sdf_shader_studio/tests -a addons/noiseforge/tests -a addons/elestruct/tests -a
addons/structura/tests -a tests rm -rf reports 
 Baseline: 2335 cases / 132 suites / 0 failures / 1 known skip / 0 orphans. A new class_name
needs a --headless --import pass before tests see it. Bump MIN_UI_FILES in
tests/app/test_app_shell.gd for your new app/ file.

TWO HOUSE RULES: (a) mutation discipline — every regression test proven RED against the
reinstated defect, and grep that the mutation actually applied before believing the red run;
if a mutation turns out unobservable, say so on the test rather than claiming a proof. (b)
NEVER commit or push — the owner commits himself.

WATCH THE SUITE COUNT, not just the failure count: a GDScript parse error makes gdUnit print
"No test cases found, abort test run!" and EXIT 0, so a broken suite reads as green when run
alone. Cost me a confusing ten minutes earlier.

= FILE OVERLAP — please read before you touch anything = I'm starting ITEM 1 (selection +
delete for placed placements) right now, and I will be editing
 app/level/level_main_screen.gd: a toolbar Delete button, a selection member, and an
addition to _on_workspace_changed. Your toggle lands in the same two regions (toolbar build
+ _on_workspace_changed).
Proposal so we don't collide: I take level_main_screen.gd first and will message you the
moment my edits to it are in and gated. Until then, build level_prototype_colors.gd, the
shader, and its test suite standalone against a synthetic root — my
tests/app/test_level_animation_preview.gd constructs its own Node3D tree and never needs the
screen; copy that approach. Then wire the toolbar last, after my green. If you'd rather have
the file first, say so and I'll sequence around you instead.

Ping me with questions — I've been in this code all day and can save you the archaeology.

⏺ I've been renamed Otto, and a peer session (Wren) just handed me ITEM 4 of an approved
plan. That's consistent with this repo's state, so I'll plan it — with one conflict to flag
up front: your global CLAUDE.md says do not run processes, and the task's verification gate
is a Godot test run. I'll plan around that (you run the gate, I read results).

Let me explore first.
Listed 1 directory (ctrl+o to expand)
⏺ 2 background agents launched (↓ to manage) ├ Explore level animation preview pattern
 └ Explore shaders and level toolbar
```
