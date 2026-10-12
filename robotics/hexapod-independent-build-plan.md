# 18-Servo Hexapod — Independent Build Plan & Shopping List

> **Status: plan, not a build log.** This was written before ordering parts. Nothing in it has been built or tested yet, so every dimension, cost, print time and schedule below is an estimate to be checked against the real build.

A RookiDroid-free plan for an 18-DOF (3 joints × 6 legs) micro-servo hexapod, to be printed on an **Elegoo Centauri Carbon 2 Combo** (owned; enclosed CoreXY, 256 × 256 × 256 mm, CANVAS four-filament unit). Nothing here depends on a vendor's controller board, proprietary firmware, or a specific frame; every part is a commodity you can buy from any supplier, and the frame can come from any of three sources.

The plan is modular. Pick one **frame path** (Section 2) and one **controller path** (Section 4); the servos, power, hardware, and print settings are common to all combinations.

---

## 0. Decisions Up Front

| Decision | Recommendation | Why |
|---|---|---|
| **Servo tier** | **MG92B** (or equivalent 21 g metal-gear micro servo, ~3.5 kg·cm at 6 V) | Same footprint as MG90S so every MG90S-class frame fits, but roughly double the torque and far better gear/pot reliability. ~$1–2 more per servo. Standard-size 20 kg·cm servos (DS3218 class) would mean a robot 2–3× the size and weight, ~$220 in servos alone, a 10 A+ power system, and ~1.5 kg of PETG; that's a different project. Micro is the right tier for a first hexapod, the reaction-wheel work, and iterating on frames. |
| **Controller** | **Arduino Uno R4 WiFi** (owned) to start; **ESP32** as the upgrade path | The R4 already has WiFi/BLE via its onboard ESP32-S3 module, 256 KB flash, and 5 V logic that matches the PCA9685 boards. It's enough for IK + gaits. Move to a bare ESP32 later only if you want more RAM/speed for on-board IMU balance loops or a web UI. |
| **Frame** | See Section 2 — recommended default is **Path C (modular)** | Fastest route to a walking robot while still being *your* design. |
| **Firmware** | A custom IK + gait sketch (Section 5), not yet written | Vendor-independent and small (an estimated 300–400 lines). Phoenix is the open-source fallback. |

---

## 1. Shopping List (common to all paths)

### Owned
- Elegoo Centauri Carbon 2 Combo, 2× 1 kg PLA (Elegoo Rapid PLA, one black, one light color), 1× 1 kg PETG
- Arduino Uno R4 WiFi

### Servos

| Item | Qty | Approx cost | Notes |
|---|---|---|---|
| **MG92B micro servo, 180°** | 20 (18 + 2 spares) | ~$110–150 | Buy all from one seller in one order so they're the same batch. Verify "180°" in the listing; some MG92B are sold as 90°. |
| *Budget alternative:* MG90S metal-gear | 20 | ~$45–60 | Same footprint. Expect a few to fail within the first months; keep spares. |

### Control electronics

| Item | Qty | Approx cost | Notes |
|---|---|---|---|
| PCA9685 16-channel PWM driver | 2 | ~$14–20 | 18 servos need two boards; chain them over I²C at addresses `0x40` and `0x41` (solder one address jumper on the second board). |
| MPU6050 IMU (GY-521) | 1 | ~$3–5 | Optional now; needed for balance/posing later. Shares the I²C bus. |
| Dupont jumper wires, M–F and F–F | 1 pack | ~$6–8 | |
| Small breadboard or a proto shield for the Uno | 1 | ~$5–8 | Keeps the I²C fan-out and power splices tidy. |
| **If going ESP32 (Path 4B):** ESP32 dev board (30-pin, USB-C) | 1 | ~$8–10 | Plus a small logic-level note in Section 4. |

### Power

| Item | Qty | Approx cost | Notes |
|---|---|---|---|
| **UBEC / buck converter, 6 V output, 8 A continuous** | 1 | ~$12–20 | MG92B stall current is ~1.2 A each; a walking gait has 6–9 servos loaded at once. 8 A is the safe size. Do not power servos from the Uno. |
| **2S LiPo, 1500–2200 mAh, XT60 or JST** | 1–2 | ~$12–18 each | ~7.4 V nominal; lightest option. Alternative: 2× protected 18650 in a 2S holder. |
| 2S LiPo balance charger | 1 | ~$15–25 | Never charge unattended. |
| XT60 (or matching) connector pigtail + inline switch, 10 A | 1 | ~$5 | Main power cut-off on the body. |
| 1000 µF, 10 V electrolytic capacitor | 2 | ~$2 | One across each PCA9685 V+/GND; smooths servo current spikes so the Uno doesn't brown out. |

### Fasteners and bearings

Exact counts depend on the frame; buy an assortment and these bags:

| Item | Spec | Qty | Use |
|---|---|---|---|
| Screws | M2 × 6 mm, pan head (servo tabs) | 40 | Servo mounting |
| Screws | M2 × 8–12 mm assortment | 100+ | General assembly |
| Nuts | M2 hex | 150+ | |
| Screws | M3 × 8–16 mm assortment + nuts | 60 | Body plates, standoffs |
| Servo horn screws | Included with servos (M2 self-tapping) | — | Keep them; 18 needed |
| Bearings | **623-2RS (3 mm ID, 10 mm OD, 4 mm wide)** | 18 | Free-side joint pivots opposite each servo horn. Common, ~$8 for 20. |
| Bolts for bearings | M3 × 10–16 mm + nyloc nuts | 18 | Pivot axles |
| Heat-set inserts | M3 × 4 mm (optional) | 20 | Body plate joints that get disassembled often |
| Nylon standoffs | M3, 10–25 mm assortment | 1 kit | Stacking body plates and mounting boards |

Budget ~$30–45 total.

### Consumables and tools
IPA, glue stick (PETG release), flush cutters, deburring tool, 2 mm and 2.5 mm hex keys, small Phillips, digital calipers (~$15 — essential for Paths A and C), soldering iron + heat-shrink for the power harness, labeled bags.

### Estimated total (excluding the printer, filament and Uno, which are already owned)
- **MG92B + Uno R4 route: ~$220–290**
- **MG90S + Uno R4 route: ~$155–200**
- Add ~$10 for the ESP32 path.

---

## 2. Frame Paths

All three assume MG92B/MG90S-class servos (body ≈ 22.5–23 × 12–12.5 × 28.5 mm; ~32.5 mm across the mounting tabs; measure yours with calipers before designing or printing pockets).

### Path A — Design your own in OpenSCAD

The fully independent option. You get a frame sized exactly to your servos, hardware, and battery, and you understand every dimension when something breaks.

**Design parameters (starting point for a micro hexapod):**

| Element | Value | Notes |
|---|---|---|
| Body | Hexagonal or circular plate, **120–140 mm** across, 2 plates stacked on 20–25 mm standoffs | Battery, Uno, and both PCA9685 boards go between the plates. Coxa servos mount at the six vertices, horns pointing outward. |
| Coxa (hip) link | **25–35 mm** horn-to-pivot | Short; it only swings the leg fore/aft. |
| Femur (thigh) | **50–65 mm** | Servo body sits inside a two-sided bracket; horn one side, 623 bearing the other. |
| Tibia (shin) | **75–95 mm** | Longer than the femur gives a taller stance and clears obstacles. Foot at ~45° at rest. |
| Servo pocket clearance | **+0.2 to +0.3 mm** per side | Print a single pocket test coupon first and tune until the servo is a light press fit. |
| Bearing seat | 10.0 mm bore, 4.2 mm deep, with a 0.1–0.2 mm interference | Test-print this too. |
| Wall thickness | ≥ 2.4 mm (3 perimeters) on any load path | |
| Ride height at rest | 60–80 mm body-plate-to-floor | |

**Design rules that matter for strength:** every leg segment should print lying flat so layers run along its length; put the horn on one side and a bearing on the other so the servo output shaft never carries a bending load alone; avoid thin cantilevered servo tabs, and wrap the servo in a bracket instead.

**Workflow:** write one MG92B as a module with its horn → build one leg (coxa bracket, femur, tibia) from parametric modules → give each joint an angle parameter and sweep it to check the swing range → place the leg 6× around the body with a `for` loop and `rotate()` → export each unique part as STL or 3MF. Keep link lengths, clearances and hole sizes as named variables at the top of the file, so a test-coupon result becomes a one-number change. Only 4–6 unique parts exist; everything else is mirrored or repeated. Expect 2–3 design iterations; that's normal and is exactly why owning the printer pays off.

**Estimated effort:** 10–20 hours of CAD for a first frame, then ~22–32 h of printing.

### Path B — An existing open-source design

Zero CAD. Three proven, vendor-independent 18-servo micro designs, all free:

| Design | Where | Servos | Notes |
|---|---|---|---|
| **"Hexapod 18 dof micro servo" by Sardaukar** | Printables model 193381 | 18× MG90S-class | Uses 18× 623 bearings and Phoenix-derived code. All six legs are identical (no left/right parts) with rotation inverted in code, which simplifies printing. |
| **"3D printed Hexapod" by PCrnjak / Source Robotics** | github.com/PCrnjak/3D-printed-Hexapod (also MakerWorld) | 18× micro | Small 18-DOF design running lightly modified Phoenix code (KurtE), with build instructions on Instructables. Fully open source. |
| **Hexana by AranaCorp (MG90S version)** | Cults3D | 18× MG90S | Kit-style: 6 legs, 2 chassis plates, 4 spacers; designed for an Arduino Mega + 18-channel driver, easily swapped for Uno R4 + 2× PCA9685. |

**Pick by:** Sardaukar if you want the simplest print run (identical legs); PCrnjak if you want the most complete instructions and code; Hexana if you like a flat-plate chassis with lots of mounting real estate for the IMU and reaction wheel later.

**Before printing any of them:** open in Elegoo Slicer (or OrcaSlicer), confirm the servo pocket is ~23 × 12.5 mm (MG92B) and not sized for a different servo, and print one leg to test-fit. If the pocket is 0.5 mm off, that's an XY-compensation slicer setting, not a redesign.

**Estimated effort:** ~1 h to review and slice, then ~18–28 h printing.

### Path C — Modular: your own body + a proven leg (recommended default)

Take the leg assembly (coxa bracket, femur, tibia, foot) from a Path B design — the legs are the hard, load-bearing, iterated-on part — and design only the **body plates** yourself in OpenSCAD. The body is two flat plates: easy CAD, one afternoon, and it's where your choices actually differ from anyone else's (battery bay, Uno + two PCA9685 mounts, IMU location, a center hub for the reaction wheel).

**How:** open the design's coxa bracket STL in the slicer and measure its mounting-hole pattern with the measure tool (confirm with calipers on a printed bracket) → in OpenSCAD, draw a 120–140 mm hexagon → place six coxa mount patterns at the vertices with a loop → add cut-outs and standoff holes for your electronics → `import()` the bracket STL alongside the plate as a fit check → export top and bottom plates.

**Estimated effort:** 2–4 h CAD, then ~18–28 h printing. You end up with a frame that is yours where it matters and proven where it's risky.

---

## 3. Printing (all paths)

### Printer: Elegoo Centauri Carbon 2 Combo (owned)

Relevant traits for this build: enclosed chamber (stable PETG, quiet), 256 × 256 × 256 mm bed, up to 500 mm/s with ~32 mm³/s flow, hardened 350 °C nozzle, fully automatic calibration, and the CANVAS unit for up to four filaments in one job.

**Slicer:** Elegoo Slicer (an OrcaSlicer fork, ships with the Centauri Carbon 2 profile) or OrcaSlicer with the Centauri Carbon profile. Everything below applies to either.

### Bed fit — 256 × 256 × 256 mm
Every micro-hexapod part fits with room to spare. The largest is the body plate (≤ 140 mm across); the longest leg part is ≤ ~95 mm. The bed is large enough to batch a full leg set (6× coxa + 6× tibia, say) on one plate, which is what the time estimates below assume. If you design your own body plate, keep it ≤ 200 mm so it still fits with a brim.

### Settings

| | Elegoo Rapid PLA | PETG |
|---|---|---|
| Layer | 0.2 mm | 0.2 mm |
| Perimeters | 3 | 4 |
| Infill | 25% | 30% gyroid |
| Nozzle | 210–225 °C | 240–250 °C |
| Bed | 55–60 °C | 75–80 °C |
| Part fan | 100% | 40–60% (the enclosed chamber keeps ambient warm, so PETG tolerates this much fan) |
| Chamber / door | **Door open or top lid off** — PLA softens if the chamber creeps above ~35 °C | Door closed |
| Speed | Profile defaults (~200–300 mm/s walls, faster infill) | Profile defaults (~120–200 mm/s) |
| Bed prep | IPA | IPA + glue stick (PETG bonds too well to bare PEI) |

Use the printer's stock material profiles as the starting point; the numbers above are what to check and where to nudge. Run the built-in flow and PA calibration once per new spool.

### Material by part

| Part type | Material | Why |
|---|---|---|
| Body plates, battery tray, covers | **PLA** | Static, stiff, fast |
| Coxa brackets / servo mounts | **PETG** | Take the leg's reaction torque every step |
| Femur, tibia, all joint brackets | **PETG** | Repeated flex, drops, servo stalls |
| Feet | **PETG** (or TPU tips if you have it) | Impact; add rubber bumpers for grip on hard floors |
| Test coupons, first prototypes | **PLA** | Cheap iterations |
| Later: arm gearboxes, high-load brackets | ASA or PA-CF nylon | Possible on this printer (enclosure + hardened nozzle); not needed for the hexapod |

Filament: ~120–180 g PLA, ~250–350 g PETG. The two PLA + one PETG spools on hand cover the whole build with margin.

**Using CANVAS for supports.** With PETG loaded in one CANVAS slot and PLA in another, set PLA as the support-interface material for PETG parts. PLA and PETG don't bond, so supports under servo pockets and overhangs snap off cleanly and leave a smooth surface. Set this per-part in the slicer (support → interface filament). It adds purge waste and a few minutes per color change, so use it only on parts that actually need supports.

### Estimated print times

These are estimates from typical part sizes, not measured prints. "Each, alone" is one part on the bed; the group totals assume parts batched by type on the 256 mm bed.

| Part type | Typical qty | Each, alone | Batched group total |
|---|---|---|---|
| Body plate | 2 | 1–2 h | 2.5–4 h |
| Coxa bracket | 6 | 15–25 min | 1.5–2 h |
| Femur bracket (2 halves) | 12 | 12–20 min | 2–3 h |
| Tibia | 6 | 20–30 min | 1.5–2.5 h |
| Foot / tip | 6 | 10–20 min | 1–2 h |
| Small joint pieces, spacers, servo caps | 12–30 | 5–12 min | 1.5–3 h |
| Electronics mounts, battery tray | 2–4 | 15–30 min | 1–1.5 h |
| **Total** | **~50–90 parts** | | **~18–28 h**, ~5–6 plates |

Path A adds one or two extra rounds of test coupons and revised parts; budget +3–5 h. A full frame should be about a weekend of printing.

### Print order
1. **Calibration check** (printer's own routine, ~20 min), then a 20 mm PLA cube to confirm dimensions.
2. **Test plate** (PETG, ~1 h): one servo pocket coupon, one bearing-seat coupon, one coxa bracket. Test-fit a servo, a 623 bearing, and an M3 bolt. Adjust XY compensation/flow until fits are right.
3. **One complete leg** (PETG, ~1.5 h). Assemble it with a real servo; check the swing range and that nothing binds.
4. **Body plates** (PLA, door open) — one plate, ~3 h.
5. **Remaining 5 legs**, batched by part type, PETG — two or three plates.
6. Feet, mounts, covers.

---

## 4. Controller Paths and Wiring

### Path 4A — Arduino Uno R4 WiFi (owned)

Everything is 5 V logic; no level shifting.

```
Uno R4 SDA / SCL  →  PCA9685 #1 (0x40)  →  PCA9685 #2 (0x41)  →  MPU6050 (0x68)
Uno R4 5V / GND   →  PCA9685 VCC (logic) on both boards, MPU6050 VCC
UBEC 6 V output   →  PCA9685 V+ screw terminals on both boards (servo power)
2S LiPo → switch  →  UBEC input
                     UBEC 5 V?  no — power the Uno from its own USB or VIN
ALL GROUNDS COMMON: Uno, both PCA9685, UBEC, IMU, battery negative
```

- Servo channel plan: board 1 channels 0–8 = left legs (coxa, femur, tibia × 3); board 2 channels 0–8 = right legs. Channels 9–15 spare.
- Put a 1000 µF capacitor across V+/GND on each PCA9685.
- Power the Uno from the UBEC's 6 V into **VIN** (the R4's regulator accepts 6–24 V) or from a separate 5 V rail; either way, keep the Uno's 5 V pin off the servo rail.
- Wireless control: the R4's built-in WiFi lets a phone or laptop send UDP commands directly to the Uno, no extra module needed.

### Path 4B — Generic ESP32

Same topology, with two changes:
- ESP32 is 3.3 V logic. PCA9685 boards accept 3.3 V on SDA/SCL fine (VCC can be 3.3 V or 5 V); MPU6050 boards have an onboard regulator and work at 3.3 V. No level shifter needed if VCC on the PCA9685 is fed 3.3 V.
- Power the ESP32 from the UBEC's output into **VIN/5V** only if you set the UBEC to 5 V, or add a small 5 V regulator; ESP32 boards don't tolerate 6 V on the 5 V pin.

Default I²C pins: GPIO 21 (SDA), GPIO 22 (SCL).

### Both paths — power safety
- Fuse the battery lead (10 A blade fuse holder, ~$3).
- Check polarity twice before first power-on.
- Hold the robot up on a box for the first power-on; a bad servo offset can swing a leg hard.
- Kill power with the switch, never by holding a leg.

---

## 5. Firmware (vendor-independent)

### Recommended: a custom sketch
Planned structure for the Uno R4 (or ESP32; only the WiFi calls change):

1. **Servo layer:** `Adafruit_PWMServoDriver` × 2; a table mapping `(leg, joint) → (board, channel, min_pulse, max_pulse, offset, direction)`.
2. **Calibration mode:** on serial command, set all 18 servos to 90° and let you adjust per-servo offsets with `+`/`-` over serial; store offsets in EEPROM (the R4 has emulated EEPROM). This replaces any vendor web UI.
3. **Inverse kinematics:** per-leg 3-DOF IK (coxa yaw from atan2, femur/tibia from the law of cosines) given your coxa/femur/tibia lengths from Section 2.
4. **Gait engine:** tripod gait first (legs 1-4-5 vs 2-3-6), then ripple. Parametrize stride length, step height, cycle time.
5. **Commands:** serial and UDP: `standby`, `walk <deg>`, `turn <±>`, `height <mm>`, `rotate <x y z>`.
6. **Later:** MPU6050 complementary filter → body-level correction; reaction wheel channel.

An estimated 300–400 lines. To be written and tested one layer at a time, with a serial test for each layer before the next is added.

### Fallback: Phoenix
KurtE's Arduino Phoenix code is the classic open-source hexapod stack (IK, multiple gaits, body rotation) and is what the Sardaukar and PCrnjak designs run. It targets an SSC-32 or direct servo pins by default; adapting it to two PCA9685 boards is a contained change in the servo-driver file. Use it if you'd rather not write IK.

---

## 6. Assembly Order (all paths)

1. Deburr parts; clear support scars from servo pockets and bearing seats.
2. **Center every servo at 90°** using the calibration sketch *before* fitting horns. Fit horns at 90° with the leg segment in its neutral pose (coxa perpendicular to body, femur horizontal, tibia 90° to femur). Leave horn screws loose.
3. Build one leg: coxa bracket → femur (servo in, bearing opposite) → tibia → foot. Check smooth swing.
4. Repeat for six legs; mark left/right if the design is mirrored.
5. Mount electronics between the body plates: battery low and central, PCA9685 boards either side, Uno on top plate, IMU at the body center.
6. Attach legs at the six vertices, route servo leads inward, label each lead with leg/joint.
7. Wire per Section 4; capacitors on; fuse in; polarity check.
8. Power on (robot held up), run calibration, tighten horn screws, save offsets.
9. First gait test on a smooth floor with power switch within reach.

---

## 7. Estimated Timeline

| Phase | Path A | Path B | Path C |
|---|---|---|---|
| Frame design | 10–20 h | 0 | 2–4 h |
| Printing (machine time) | 24–36 h | 18–28 h | 18–28 h |
| Cleanup + hardware sorting | 2–3 h | 2–3 h | 2–3 h |
| Assembly | 4–6 h | 4–6 h | 4–6 h |
| Wiring | 2–3 h | 2–3 h | 2–3 h |
| Firmware (own sketch) | 6–10 h | 6–10 h | 6–10 h |
| Calibration + first walk | 1–2 h | 1–2 h | 1–2 h |

---

## 8. Checklist Before Ordering

- [ ] 20× MG92B 180°, single order
- [ ] 2× PCA9685, 1× MPU6050
- [ ] UBEC 6 V / 8 A, 2S LiPo + charger, switch, fuse, XT60 pigtail, 2× 1000 µF caps
- [ ] M2 and M3 assortments, 150+ M2 nuts, 20× 623-2RS bearings, M3 nyloc nuts, standoff kit
- [ ] Digital calipers
- [ ] Glue stick, IPA
- [ ] (Path B) chosen design downloaded and reviewed in Elegoo Slicer
- [ ] (Path A/C) one servo measured with calipers and modeled in OpenSCAD
