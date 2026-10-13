# built-with-claude-code
Projects I built with Claude Code as a non-engineer, with demos, workflow write-ups, and session excerpts.

<img width="640" height="360" alt="portal-bigger-inside" src="https://github.com/user-attachments/assets/191ff265-1ab4-4221-884e-ef34c231a723" />

Circling a shed, then entering a non-Euclidean hall.

<img width="640" height="360" alt="entering-the-chapel" src="https://github.com/user-attachments/assets/21e4bab2-9db2-4f2a-b2b2-9d091a941e3f" />

The Chapel seen through the portal from the dark hub, then stepping in.



## About

My name is John and I’m a musician with a bachelor’s degree in Business and Marketing, and I studied literature and languages at the Sorbonne. I’m fluent in English and French, understand Russian natively though I don’t speak it well, and I get by in Spanish. I am not an engineer by background, but I began learning software development 2 years ago, and have spent the past year working on a number of projects by directing & managing a number of Claude Code sessions that run in parallel. The source for my projects is private because I currently plan to sell the software, apps, and games. Access to the source/zip snapshots is available to reviewers upon request.

---

## How I work

- [Workflow write-up](workflow/workflow-write-up.md): spec first, parallel sessions, and how I verify AI-written code.
- [Session transcript](workflow/session-briefing-transcript.md): one session briefing another, uncut.
- [Engine purity test](code-samples/test_engine_purity.gd): a test from elestruct that fails if engine code ever depends on the editor.

---

## Projects

### Kaleidophone: 
a music/color/non-Euclidean (seamless portals; rooms bigger inside than out) exploration game where pitch maps deterministically to color.

Status: Godot 4, milestones M0-M4 complete, two zones playable, ~600 tests

<img width="560" height="316" alt="6-shell-bench-colour-a" src="https://github.com/user-attachments/assets/efcfa21e-1b39-47d4-b422-6c74d4ad072d" />

Shell bench moving through teal, purple, magenta, and blue.

<img width="560" height="316" alt="7-shell-bench-colour-b" src="https://github.com/user-attachments/assets/3dfd142e-78c7-4731-8b30-64d84d3be428" />

Shell bench moving through gold, green, and orange.

---

### Elestruct: 
an all-in-one procedural authoring suite. SDF-based 3D modeling and noise authoring using graph nodes, that can be rigged, animated, and placed into a level/world editor, with export options available at each stage.

Status: Godot 4, ten milestones complete, 2,300+ tests, with an [engine purity test sample uploaded here](code-samples/test_engine_purity.gd) 

<img width="1440" height="900" alt="Blank project file" src="https://github.com/user-attachments/assets/6462a2a9-a94a-4291-8312-ea00f9de8e76" />

Blank Elestruct project file.

<img width="1440" height="900" alt="Preview and node options" src="https://github.com/user-attachments/assets/c5269458-ade3-4a78-9620-d27d435e2266" />

Preview on the right and selected-node options on the bottom.

<img width="1440" height="900" alt="Showcase of node options on right-click" src="https://github.com/user-attachments/assets/f190ce27-a0b3-4b12-9fdc-f3b92ed8d6aa" />

Showcase of options to remove, disconnect connections, disconnect output, extract from chain, and available nodes to replace the selected node with.

<img width="1440" height="900" alt="Replacing combining node chained to output" src="https://github.com/user-attachments/assets/c7196f91-7059-4563-9682-6d366161aaad" />

Replacing smooth union with smooth subtraction.

<img width="1440" height="900" alt="Noise tab" src="https://github.com/user-attachments/assets/7d1093d5-d12e-4d1e-b309-2e3b238e6c3a" />
Noise generation tab.

<img width="1440" height="900" alt="Structura tab" src="https://github.com/user-attachments/assets/4baf446e-70d2-47d3-b831-8279433409a4" />

Structura tab, where elements built with SDF and textured with Noise are combined using splines and grammars among other procedural generation algorithms to create larger, usable assets & asset packs.

<img width="1440" height="900" alt="Level tab" src="https://github.com/user-attachments/assets/c4e29e4c-0bcd-4d0e-af13-5b9c99ebd86a" />

Level tab, where the assets from Structura are then added to a level/world builder, with granular control, editing, and placement capabilities to build a finished level/region/world out using the Elestruct suite from start to finish.

---

### Mazony: 
a Rust and wgpu re-authoring of two Godot procedural-graphics addons (that also served as the foundations for Elestruct) plus an audio/visual signal bridge, intended as the graphics foundation for a planned DAW where the payoff is “texture-as-oscillator”

Status: Rust and wgpu, all migration phases complete plus the studio UI

Screen recording showing the audio/visual signal bridge in action, with sound.

https://github.com/user-attachments/assets/1a9b5197-fbe2-43dd-b425-f549463f1ea5


---

### ShortCircuit: 
a deck-building roguelike where every hand is a real circuit on a simulated breadboard so as to function as a game that also teaches the player real electronics/circuitry

Status: Godot 4, early prototype

Screen recording showing the board layout and other mechanics/functionality.

https://github.com/user-attachments/assets/6e793362-a7ac-4af1-b669-b5bbbd56c793


---

### Robotics & Learning: 
A project to learn robotics & engineering with Claude's assistance, a [plan for building a hexapod](robotics/hexapod-independent-build-plan.md), along with an [OpenSCAD file](robotics/hexapod_frame.scad) generated by Claude which has been checked and corrected, in [robotics](robotics/). A [robotics core guide](learning/Robotics_Core_Guide.pdf) and [robotics formula drill book](learning/Robotics_Formula_Drill_Book.pdf) as learning materials created by Claude to follow along with and learn the fundamentals of robotics, while making the math & physics behind robotics readily available to practice.

Status: Plan stage, nothing built yet.
