# Migration Spec — NoiseForge + SDF Shader Studio + BridgeFlow → Rust + wgpu + Rust-audio

**Status:** Design / research-validated draft v2
**Scope:** Port the graph-codegen / SDF / noise / bake capability of three existing Godot GDScript addons out of Godot entirely, onto a Rust + wgpu core with a Rust-native audio engine, as the graphics-and-bridge foundation for the DAW project (see *DAW + Audio/Visual Signal Bridge* spec).
**Author context:** 15+ yrs audio; 7+ yrs graphics/3D; game-dev + Python/Lua scripting; non-professional in systems C++/Rust. AI-assisted refactoring + a Rust/RT-safety-competent reviewer.
**Changes from v1:** framework line resolved (Rust-audio, not JUCE — §5.1); no-FFI consequence recorded; RT-safety burden and FAUST option added; testing strategy expanded with gdUnit4-transfer findings (§10).

---

## 0. What this migration is and is not

**Is:** lifting *algorithms and codegen models* — the graph→shader compiler, the SDF field evaluator, the 4D noise library, the bake-to-texture/mesh pipeline, the determinism/fingerprint discipline, and the 1D↔2D/3D bridge concept — out of Godot and re-authoring them on a stack chosen for real-time-safety and a modern GPU API.

**Is not:** morphing Godot's editor or GDScript VM into anything. Both are dropped. This follows the DAW spec's own extraction rule: extract *leaf algorithms*, get *architectural layers* (threading, buffer ownership, host, GPU abstraction) from the framework (Rust ecosystem + wgpu + Rust-audio), never extract the architectural layers.

**License note:** Godot is MIT. The three addons are the author's own work. No GPL contamination risk from this source. The Rust-audio choice (§5.1) keeps the whole stack permissive-native — the one licensing tension the DAW spec flagged (JUCE's dual-license ceiling) is removed, not managed. All *newly pulled* permissive dependencies still go through the DAW spec's license gate + manifest + `THIRD_PARTY_NOTICES` workflow.

---

## 1. Research findings that shaped this spec (validated July 2026)

Two gating questions were checked against current sources rather than assumed.

### 1.1 Shader language: author WGSL, do NOT feed existing GLSL through naga

- naga's **GLSL frontend is not viable for the compute path.** Confirmed unsupported: compute-stage layout qualifiers, `shared` variables in compute shaders, and several image/storage qualifiers — including via the GLSL→SPIR-V→naga route, where shaders that spirv-cross handles fine fail in naga with "unsupported storage class" / "Not implemented: variable qualifier." Maintainer position amounts to "it supports a lot; file an issue when it doesn't" — unacceptable as a product shader pipeline's foundation.
- naga's **WGSL frontend is the first-class, best-maintained path** (full backend parity to SPIR-V / MSL / GLSL / HLSL). Authoring WGSL puts the project on the road naga is built to pave.
- **Decision:** the codegen emitter targets **WGSL**. The existing GLSL was only ever dual-valid as *text* in Godot-shading-language + GLSL; that trick solved a Godot-only problem and is dropped, not ported. There is **no OpenGL dependency** in the current stack to carry forward (Godot's `RenderingDevice` compute path is Vulkan/D3D12/Metal via SPIR-V), so the DAW spec's "OpenGL deprecated" risk does not apply to this migration.

### 1.2 Audio timing: naga is irrelevant to it; readback is the gate

- naga runs **at shader-compile / hot-reload time**, on the CPU, never in the audio callback. Its speed has no bearing on audio buffering.
- The real audio-rate gate is **GPU→CPU readback latency**: async readback inherently costs ~1–2 frames (even a trivial shader rarely returns same-frame); the PCIe transfer is orders of magnitude slower than on-GPU bandwidth. Mitigation is structural and already in the DAW spec: reduce on the GPU to a tiny feature set, read back KB not MB, keep data GPU-resident, only read the final result.
- **Consequence for sequencing:** control-rate bridge is latency-forgiving (fine on this stack); audio-rate bridge stays gated behind an explicit readback-latency spike. Unchanged from the DAW spec — the research confirms rather than revises it.

---

## 2. What survives, what is rewritten, what is dropped

| Component (current) | Fate | Target form |
|---|---|---|
| Graph data model (`NFGraph`, SDF graph, connections, seeds) | **Rewrite** | Rust structs/enums; `serde` for save/load |
| Codegen orchestration (dedup, helper ordering, fingerprint, `inline_params`, wrapping/§5.3 collision logic from BridgeFlow) | **Rewrite (port logic, keep design)** | Rust; language-agnostic core, WGSL emitter |
| Shader library: SDF primitives, combiners, transforms, raymarcher; noise functions (Perlin/OpenSimplex/Value/White/Cellular/Oscillator), fractals, domain warp | **Re-author once in WGSL** | WGSL source templates; the bounded leaf work |
| CPU evaluators (`NFEvaluator`, `NFNoiseCPU`, `SDFEvaluator`), samplers, marching-cubes mesher | **Rewrite** | Rust; better here than GDScript (types, threads, no GC) |
| Determinism: integer xxHash-shaped hash (CPU/GPU identical), CPU/GPU parity discipline (≤1e-5) | **Rewrite (re-implement spec)** | Rust + WGSL, identical hash both sides |
| Bake pipeline (field→texture/mesh, sidecars, staleness md5) | **Rewrite** | Rust; wgpu compute + CPU fallback |
| BridgeFlow hub / adapter / consumer contract | **Rewrite (collapse)** | Plain Rust modules/traits; no dynamic-load gating needed (§6) |
| Test suites (gdUnit4, ~all logic) | **Re-express (asset, not port)** | `cargo test` in `graph-core`; assertions transcribe directly (§10) |
| Dual-GLSL (OpenGL + Godot-SL) text validity | **Drop** | One target: WGSL→naga→SPIR-V/MSL/DXIL |
| GDScript VM, ScriptServer, `Variant`/`Object`/`ClassDB` | **Drop** | Rust's own type system |
| Editor: `EditorPlugin`, `GraphEdit`, inspector, Ableton-style timeline, undo/redo, file dialogs | **Drop (rebuild later, separately)** | Out of scope here; see §7 |
| `RenderingDevice`, Godot shader compiler, Godot core | **Drop** | wgpu + naga |
| Godot `Image`/`Texture`/`ArrayMesh`/EXR-PNG codecs | **Replace** | `image` crate (PNG), `exr` crate (OpenEXR), custom mesh structs / `gltf` crate |
| `AnimationPlayer`/`Animation` export target | **Drop / re-home** | Automation becomes DAW-native; §5 |
| Audio host (was open: JUCE vs Rust-audio) | **Resolved → Rust-audio** | cpal (device I/O) + fundsp / hand-written DSP / FAUST-compiled (§5.1) |

---

## 3. Target architecture

```
                     ┌─────────────────────────────────────────┐
                     │              host (Rust)                 │
                     │  owns event loop, threads, wgpu device   │
                     │  one workspace, one language, no FFI     │
                     └───────┬───────────────────────┬──────────┘
                             │                        │
                   ┌─────────▼─────────┐    ┌─────────▼──────────┐
                   │   graph core      │    │   gpu runtime      │
                   │  (no wgpu, no gpu)│    │  wgpu + naga       │
                   │  data model       │    │  pipeline cache    │
                   │  codegen → WGSL   │───▶│  compute dispatch  │
                   │  fingerprint/dedup│    │  bake, reduction   │
                   │  CPU evaluators   │    │  async readback    │
                   │  ALL-LOGIC TESTS  │    │  (GPU-gated tests) │
                   └─────────┬─────────┘    └─────────┬──────────┘
                             │                        │
                             └───────────┬────────────┘
                                         │  1D↔2D/3D bridge
                                ┌────────▼─────────┐
                                │  signal bridge   │  (DAW spec §6)
                                │  reduction map   │
                                │  lock-free SPSC  │  ← Rust↔Rust, no FFI
                                └────────┬─────────┘
                                         │
                                ┌────────▼─────────┐
                                │  audio engine    │  cpal + DSP
                                │  (Rust-native)   │  RT-safe callback
                                └──────────────────┘
```

**Crate layout (workspace):**

```
crates/
├── graph-core/        # no wgpu dep. data model, codegen, fingerprint, CPU eval, hash
│   ├── model/         # NFGraph/SDFGraph equivalents, nodes, connections
│   ├── codegen/       # graph → WGSL; dedup, helper ordering, wrapping, inline_params
│   ├── wgsl/          # the re-authored shader library (SDF prims, noise, raymarch)
│   ├── eval/          # CPU evaluators + samplers + mesher
│   └── hash/          # integer xxHash-shaped, bit-identical to the WGSL version
├── gpu-runtime/       # wgpu device, pipeline cache, compute dispatch, bake, readback
├── bridge/            # 1D↔2D/3D reduction + mapping strategies + lock-free crossing
├── audio/             # cpal stream, RT-safe callback, DSP graph (fundsp / FAUST-compiled)
├── host/              # binary: event loop, thread topology, wires the above together
└── xtask/             # golden regen, preset conversion, provenance tooling
```

`graph-core` has **no GPU dependency** — it emits WGSL text and evaluates on CPU. This is the headless-testable heart (mirrors the addons' "headless-safe core" discipline), the reference the GPU path is tested against, and the crate where essentially the entire ported test suite lives (§10).

---

## 4. Shader codegen — the load-bearing port

This is the one design that must survive intact (BridgeFlow §13's "the one decision that must survive any cut"). Re-implemented in Rust, emitting WGSL.

### 4.1 Preserved invariants
- **Deterministic function names** from (graph identity, dims): stable, dedupable, golden-testable.
- **Per-helper granularity + dedup:** each helper emitted once even when multiple graphs share it (BridgeFlow §5.3). Insertion-ordered, skip-if-present, deps-first.
- **`inline_params = true`** wrapping: a wrapped graph emits zero uniforms, so composed graphs never collide in the uniform namespace.
- **Namespace separation:** noise helpers `nf_*`, SDF helpers `sd_*`/`op_*`, bridge-wrapped `bf_*`. An automated test asserts the prefix invariant so drift fails loudly (ported directly).

### 4.2 WGSL-specific changes vs the old GLSL emitter
- Type syntax: `vec3` → `vec3<f32>`, explicit `f32`/`i32`/`u32`.
- Function decls, `let`/`var` distinction, no implicit conversions (WGSL is stricter — this catches latent bugs).
- Texture sampling: `textureSample`/`textureLoad` + explicit bind-group/binding decorations, not GLSL `sampler2D` + `texture()`.
- Compute entry points: `@compute @workgroup_size(...)`, `@group/@binding` — authored directly (the exact area naga's GLSL frontend could not handle, now sidestepped).
- No preprocessor; helper composition happens in the Rust emitter, not via `#include`.

### 4.3 One-target simplification
The old dual-language discipline is deleted. There is a single emission target (WGSL), so the "valid in two surface languages" constraint that shaped some helper phrasing is lifted — helpers can use the clearest WGSL form.

---

## 5. The bridge and audio — re-homed, not ported literally

The addons' automation lived in Godot's timeline and exported a Godot `Animation`. That target is gone. Instead:

- The **1D↔2D/3D conversion** becomes the DAW's first-class bridge primitive (DAW spec §6), consuming the graph core's GPU field output through the reduction→readback→mapping pipeline.
- **Control-rate first** (DAW spec Phase 2): field → GPU reduction → async readback (KB) → 2D→1D mapping (Hilbert default, raster baseline, swappable) → slew → modulation matrix. Latency-forgiving; this stack handles it.
- **Automation "bake"** (BridgeFlow §7's bake-keys-not-live-modulate decision) maps cleanly onto writing DAW automation lanes offline — same principle, DAW-native target instead of `Animation.tres`.
- **Audio-rate** (DAW spec Phase 3) stays gated behind the readback spike (§1.2, §8).

The thread crossing is built **lock-free (SPSC ring / double-buffered atomic snapshot) from the start**, per the DAW spec, so the control-rate implementation is reused for audio-rate without re-architecting.

### 5.1 Framework line: Rust-audio (resolved)

The DAW spec left JUCE-vs-Rust-audio open. **Resolved: Rust-audio** — cpal for device I/O, fundsp and/or hand-written DSP and/or FAUST-compiled DSP for the signal graph. Consequences:

- **No FFI anywhere in the hot path.** Graph core, GPU runtime, bridge, and audio engine are one language in one workspace. The bridge's lock-free crossing is Rust↔Rust between two threads in one process — no `extern "C"`, no marshalling, no buffer-convention mismatch, no cross-language ownership handoff. This is the single biggest structural payoff of the choice and it simplifies §5's crossing design outright.
- **Permissive-native, no license ceiling.** cpal (Apache-2.0/MIT) and fundsp (MIT/Apache) satisfy the DAW spec's absolute permissive requirement. The JUCE "commercial license as a when-not-if" tension is removed entirely.
- **RT-safety burden shifts onto us — this is the real cost.** JUCE would have supplied a battle-tested audio host (thread priorities, callback lifecycle, buffer management) as architecture we don't write. cpal gives the device stream and the callback; the discipline *inside* the callback is ours to enforce. The audio-thread rules are absolute: preallocate all buffers up front; no `malloc`/`Box`/`Vec`-growth/`Mutex`/`String`/`panic!`/file-I/O on the callback path; cross threads only via the lock-free primitive. Rust assists (no GC, no hidden allocations, `#[no_std]`-able hot paths, allocation-flagging lint crates) but does not prevent `Vec::push` from allocating — that remains the reviewer's explicit, narrow mandate (§10).
- **FAUST is worth real evaluation, not a default.** FAUST compiles high-level DSP descriptions to permissively-usable code and integrates cleanly with a Rust-audio host — a large shortcut for a sound designer over hand-writing filters/oscillators/resamplers in Rust, and RT-safe by construction of its generated code. Evaluate it for the DSP-authoring layer specifically; fundsp or hand-written remain fallbacks. This is the one audio-side component to assess deliberately rather than assume.

---

## 6. What gets simpler in Rust

- **BridgeFlow's entire dynamic-loading gymnastics dissolve.** The no-`class_name` / load-by-path / probe-on-disk gating existed only to let a GDScript plugin parse when a sibling addon was absent. In one Rust workspace, absence/presence is a compile-time feature flag or a module boundary. Keep the *conceptual* provider/consumer seam (it's good design and leaves room for future providers), drop the machinery.
- **CPU/GPU float parity gets cleaner.** The GDScript-float64-vs-shader-float32 gap that forced the ≤1e-5 tolerance is now Rust-f32-vs-WGSL-f32 on the hot path — tighter and more predictable. Keep a tolerance test regardless (driver math differences remain).
- **Threading becomes real.** NoiseForge's "one sampler per thread, stateless" becomes ordinary `Send`/`Sync` Rust with real thread pools, not `Thread.new()` + discipline-by-convention. The audio/visual thread crossing is native, not FFI (§5.1).
- **Determinism hazard removed at the source.** The addons deliberately avoided `fract(sin(dot()))` hashing because it diverges across GPU vendors and CPU/GPU. Re-implement the same integer hash in Rust + WGSL; assert byte-identical output in a cross-check test.

---

## 7. Explicitly out of scope (this migration)

- **Authoring UI.** No node-graph editor, no timeline, no inspector. The migration delivers a *headless, programmatic* graph → GPU/CPU capability plus the bridge and audio engine. Any editor is a later, separate effort (and should not be a carved-down Godot editor — that path was evaluated and rejected).
- **Live audio-rate modulation** until the readback spike passes.
- **New node types** beyond what the three addons already define.
- **DAW audio-production and graphical-production features** — this spec is the bridge-and-graphics-and-audio-engine foundation they build on, not those features themselves.

---

## 8. The one spike that must run before committing (do this first)

Per the DAW spec's "single measurement that validates or invalidates the audio-rate half": build the ugliest possible end-to-end path and **measure GPU→CPU readback latency on target hardware in wgpu.**

- Minimal WGSL compute shader writes a tiny buffer.
- `map_async` + poll; timestamp the round trip; run it under a simulated audio-buffer cadence.
- Record: median + worst-case latency, frames-of-delay, jitter.
- **Gate:** control-rate proceeds regardless (it's forgiving). Audio-rate (texture-as-oscillator) proceeds only if the number is tolerable; otherwise audio-rate conversion moves to CPU (DAW spec §7's likely split) while GPU stays control-rate.

This spike needs **none** of the migration below it — do it before porting anything, so a bad number reshapes the plan cheaply.

---

## 9. Phased plan (each phase ends verifiable; headless where possible)

**Phase 0 — Readback spike (§8).** → *verify:* a latency number exists, with a documented audio-rate go/no-go threshold. No other code depends on this passing, but it informs Phase 6+.

**Phase 1 — Workspace skeleton + graph-core data model.** Port `NFGraph`/SDF graph structs, connections, seeds; `serde` round-trip. → *verify:* headless load/save of a converted preset is lossless; no wgpu dependency in `graph-core`; `cargo test -p graph-core` runs with no device.

**Phase 2 — Determinism core.** Integer hash in Rust + a WGSL twin. → *verify:* Rust hash and a GPU-run WGSL hash agree bit-for-bit at N random inputs; `fract(sin)` explicitly not used. *(Implementation note: this verify clause needs a device, so `gpu-runtime` and the `gpu-tests` feature are created here — earlier than §3's Phase 5 slot — as a minimal compute harness that Phase 5 grows into.)*

**Phase 3 — CPU evaluators + samplers.** Port noise + SDF CPU eval, marching-cubes mesher. → *verify:* known-value invariants (exact zero at lattice points, 4D-slice identity — NoiseForge's own test philosophy) hold; a committed golden bake reproduces. This is where the bulk of the ported logic suite lands (§10).

**Phase 4 — WGSL shader library + codegen emitter.** Re-author SDF prims/combiners/raymarcher + noise/fractal/warp in WGSL; port dedup/ordering/wrapping/`inline_params`. → *verify:* wrapped-function golden matches (via `insta`); each shared helper defined exactly once (regex count = 1); `nf_`/`sd_`/`op_` prefix invariant holds; WGSL compiles through naga (GPU-gated tier).

**Phase 5 — GPU runtime + parity.** wgpu device, pipeline cache, compute dispatch, bake, async readback. → *verify (needs real device, behind `gpu-tests` feature):* GPU bake vs CPU eval agree within tolerance at random voxels; a compute shader with a composed graph compiles and reports the expected bindings.

**Phase 6 — Bake pipeline + staleness.** Field→texture (`image`/`exr`) + mesh; md5 sidecars. → *verify:* reload matches GPU/CPU data; fingerprint mismatch flips stale.

**Phase 7 — Bridge (control-rate) + audio engine skeleton.** Reduction pass, mapping strategies (Hilbert + raster), slew, lock-free SPSC crossing, modulation-matrix sink; cpal stream + RT-safe callback consuming the crossing. → *verify:* end-to-end field→control values reach the audio thread; mapping strategies swappable; crossing and callback are alloc/lock-free (reviewer-confirmed).

**Phase 8 — Audio-rate (gated on Phase 0).** Only if the spike allowed it. Texture-as-oscillator source; reuse the Phase 7 crossing. → *verify:* sample-accurate path meets the latency budget the spike established, or is documented as CPU-routed.

Phases 6 and 7 are independent after Phase 5 and can parallelize.

---

## 10. Testing & RT-safety discipline

The current gdUnit4 suite is **mostly-to-entirely logic** — which makes it a portable asset, not an anchor.

- **The test cases transfer; the harness does not.** Assertions (exact zero at lattice points, 4D-slice identity, backend agreement within tolerance, dedup count = 1, `nf_` prefix invariant, byte-identical golden output) are mathematical/structural and transcribe near-mechanically into Rust `#[test]` functions. gdUnit4 itself is thrown away and replaced by `cargo test` (built in) + `rstest` (parameterized cases) + `insta` (golden/snapshot).
- **The safe-to-run-autonomously tier is the whole logic suite.** Because coverage is all logic, it lives entirely in the GPU-free `graph-core` crate; `cargo test` runs all of it — fast, deterministic, sandboxed, no device. This is *better* than the Godot situation, where even headless runs boot a full engine runtime. The safe tier is a hard crate boundary, not a runtime convention.
- **GPU tests are feature-gated, not runtime-skipped.** Device-dependent parity/compile tests sit behind `#[cfg(feature = "gpu-tests")]`, so default `cargo test` is the safe set and `cargo test --features gpu-tests` opts into the device tier. This is the clean analog of gdUnit4's "self-skip where there's no rendering device."
- **Test the emitted string, not the compile, in the fast tier.** As BridgeFlow already established (headless shader-compile assertions are invalid against a dummy device), assert on the *emitted WGSL text* structurally (golden/regex, in `graph-core`, fully headless) and reserve *actual naga/wgpu compilation* for the GPU-gated suite. This discipline was never Godot-specific; it's fundamental to GPU testing and transfers directly.
- **RT-safety review target (narrow, explicit):** the reviewer checks the audio callback and the thread-crossing consumer for *any* allocation / lock / blocking / `String` / `panic!` on the hot path — not "good Rust" in general. With Rust-audio (§5.1) this mandate is load-bearing: there is no JUCE host absorbing these mistakes. Rust helps but does not prevent `Vec` growth or `Mutex` use; those are the review's job.
- **Manifest + `THIRD_PARTY_NOTICES`:** every newly pulled permissive crate (image, exr, gltf, cpal, fundsp, hash, noise refs, and any FAUST-generated code) recorded with version/commit + license + attribution, transitive tree checked, before it's relied on.
- **AI-assisted work stays leaf-level:** shader functions, math kernels, DSP leaf algorithms, format glue. Architectural layers (wgpu device management, cpal stream lifecycle, thread topology, buffer ownership) come from the ecosystem and are hand-owned and reviewed — per the DAW spec's realistic assessment of where AI refactoring is strong vs risky, and to contain the comprehension gap on the code that matters most at 2am.

---

## 11. Risks

| Risk | Mitigation |
|---|---|
| WGSL re-authoring introduces subtle math divergence from the old GLSL | Phase 2/3 parity tests + committed goldens catch drift; port function-by-function against known-value invariants |
| Readback latency kills audio-rate | Phase 0 spike measures it *first*; audio-rate gated; CPU fallback path pre-planned |
| naga rejects some WGSL construct | WGSL is naga's first-class frontend; stay within core WGSL; validate each shader through naga in Phase 4/5 CI |
| RT-safety regressions on the audio thread (no JUCE host to absorb them) | narrow reviewer mandate; lock-free-from-start crossing; no alloc/lock hot-path rule; allocation-flagging lints |
| Rust-audio ecosystem thinner than JUCE (more built from scratch) | lean on fundsp + evaluate FAUST for DSP authoring; extract permissive leaf DSP; framework-level host stays minimal by design |
| Comprehension gap (AI-written code the author understands least) | AI limited to leaf algorithms; architectural + audio-host layers hand-owned; goldens document intended behavior |
| Scope creep back toward rebuilding an editor | editor explicitly out of scope; headless/programmatic deliverable; UI is a separate later effort |
| Float determinism across GPU vendors | integer hash (not `fract(sin)`) re-implemented identically both sides; cross-vendor parity test |

---

## 12. The honest 50% version

If effort must be cut: **Phases 0–5 + 7 (control-rate) only.** That delivers the validated core — deterministic graph→WGSL codegen, CPU/GPU parity, GPU compute + bake, the control-rate bridge that proves the novel primitive, and a minimal Rust-audio sink — without the mesh/texture staleness polish (Phase 6 trimmed to in-memory only) and without audio-rate (Phase 8, gated anyway). The non-negotiable survivor is §4's codegen design (deterministic names, per-helper dedup, `inline_params`, WGSL target) — it's what keeps every downstream path working from one emission, exactly as it was the non-negotiable in the addons' own architecture. The Rust-audio framework line (§5.1) is settled and survives any cut: it's what keeps the entire pipeline FFI-free and permissive end to end.
