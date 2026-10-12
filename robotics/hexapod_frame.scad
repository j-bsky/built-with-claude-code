// hexapod_frame.scad  —  18-servo micro hexapod (MG92B / MG90S class)
// Units: mm.  Print "coupon" first, tune clr / seat_d / horn_* until the
// servo is a light press fit and the 623 bearing seats with light pressure.
//
// part options: assembly, leg, top_plate, bottom_plate, coxa_bracket,
//               femur, tibia, foot, coupon
part = "assembly";
$fn = 48;

/* ---------- Servo (MG92B ~= MG90S). MEASURE YOURS WITH CALIPERS ---------- */
sv_l         = 22.8;   // body length
sv_w         = 12.2;   // body width
sv_tab_z     = 16.0;   // body bottom to underside of mounting tabs
sv_tab_t     = 2.5;    // tab thickness
sv_top       = 4.3;    // tab top face to top of gear housing
sv_hole_sp   = 28.0;   // tab hole spacing (centre to centre)
sv_hole_d    = 1.7;    // pilot for M2 self-tap
sv_shaft_off = 6.1;    // shaft axis from the near end of the body
clr          = 0.25;   // pocket clearance per side

/* ---------- Round horn ---------- */
horn_d      = 21;      // outer diameter
horn_t      = 1.6;
horn_bc     = 14;      // bolt circle of the horn holes
horn_n      = 4;
horn_hole_d = 2.2;     // M2 clearance

/* ---------- 623 bearing (3 x 10 x 4) ---------- */
seat_d     = 9.9;      // 0.1 interference
seat_depth = 4.2;
pin_d      = 2.8;      // M3 self-taps into the plate, slips through bearing bore

/* ---------- Structure ---------- */
wall       = 2.4;
fp_t       = 3;        // fork plate / arm thickness
coxa_len   = 30;       // coxa axis to femur axis
femur_len  = 58;       // femur axis to tibia axis
tibia_len  = 85;       // tibia axis to foot socket end
body_r     = 60;       // coxa axis radius (body ~130 mm across flats)
corner_r   = 11;       // plate corner arc, centred on each coxa axis
standoff_r = 48;
bp_t       = 5;        // bottom plate
standoff_h = 25;
tp_t       = 3;        // top plate

/* ---------- Derived (do not edit) ---------- */
sv_cen      = sv_l/2 - sv_shaft_off;              // body centre vs shaft, along +x
cell_half_l = sv_hole_sp/2 + 3.5;
cell_c      = (sv_tab_z + clr + 1 + seat_depth)/2; // horn-side half thickness
fh          = horn_d/2 + wall;                     // link half height (z)
cell_ym     = fh;                                  // bearing-side half thickness
horn_y0     = cell_c + sv_tab_t + sv_top + 0.3;    // inner face of horn-side plate
bear_y1     = -cell_ym - 0.5;                      // inner face of bearing-side plate
tp_z        = bp_t + standoff_h;                   // top plate underside
arm_top_z0  = tp_z + tp_t + sv_tab_t + sv_top + 0.3;
arm_bot_z1  = -0.5;
z_cell      = ((arm_top_z0 + fp_t) + (arm_bot_z1 - fp_t))/2;
x_web       = coxa_len + sv_cen - cell_half_l - 3;

/* =====================================================================
   Servo cell: a block holding one servo. Shaft axis = local Y.
   +Y face: servo drops in, tabs rest on the face, M2 screws.
   -Y face: 623 bearing seat, coaxial with the shaft.
   ===================================================================== */
module servo_cell() {
    difference() {
        translate([sv_cen - cell_half_l, -cell_ym, -fh])
            cube([2*cell_half_l, cell_ym + cell_c, 2*fh]);
        // body pocket, open at +Y
        translate([-sv_shaft_off - clr, cell_c - sv_tab_z - clr, -sv_w/2 - clr])
            cube([sv_l + 2*clr, sv_tab_z + clr + 1, sv_w + 2*clr]);
        // tab screw pilots
        for (s = [-1, 1])
            translate([sv_cen + s*sv_hole_sp/2, cell_c - 6, 0])
                rotate([-90, 0, 0]) cylinder(d = sv_hole_d, h = 7);
        // bearing seat and pin through-hole
        translate([0, -cell_ym - 1, 0]) rotate([-90, 0, 0]) cylinder(d = seat_d, h = seat_depth + 1);
        translate([0, -cell_ym - 1, 0]) rotate([-90, 0, 0]) cylinder(d = 4, h = cell_ym + cell_c + 2);
    }
}

module horn_recess() { cylinder(d = horn_d + 0.4, h = horn_t + 0.2); }
module horn_holes(len) {
    cylinder(d = 4, h = len);                          // driver access to horn screw
    for (i = [0 : horn_n - 1])
        rotate(i*360/horn_n) translate([horn_bc/2, 0, 0]) cylinder(d = horn_hole_d, h = len);
}

/* =====================================================================
   Fork: two plates wrapping a servo cell (horn one side, bearing pin the
   other), joined by a web at x_end. Pivot axis = local Y at origin.
   ===================================================================== */
module fork_profile(x_end) {
    hull() { circle(r = fh); translate([x_end - 1, -fh]) square([1, 2*fh]); }
}
module fork(x_end) {
    difference() {
        union() {
            translate([0, horn_y0 + fp_t, 0]) rotate([90, 0, 0]) linear_extrude(fp_t) fork_profile(x_end);
            translate([0, bear_y1, 0])        rotate([90, 0, 0]) linear_extrude(fp_t) fork_profile(x_end);
            translate([x_end - 3, bear_y1 - fp_t, -fh])
                cube([3, (horn_y0 + fp_t) - (bear_y1 - fp_t), 2*fh]);
        }
        translate([0, horn_y0 - 0.01, 0]) rotate([-90, 0, 0]) { horn_recess(); horn_holes(fp_t + 1); }
        translate([0, bear_y1 - fp_t - 1, 0]) rotate([-90, 0, 0]) cylinder(d = pin_d, h = fp_t + 2);
    }
}

/* ---------- Coxa bracket: U around the body edge + femur servo cell ---------- */
module arm_profile(x_end) {
    hull() { circle(r = fh); translate([x_end - 1, -fh]) square([1, fh + cell_c]); }
}
module coxa_bracket() {
    difference() {
        union() {
            translate([0, 0, arm_top_z0])        linear_extrude(fp_t) arm_profile(x_web + 3);
            translate([0, 0, arm_bot_z1 - fp_t]) linear_extrude(fp_t) arm_profile(x_web + 3);
            translate([x_web, -fh, arm_bot_z1 - fp_t])
                cube([3, fh + cell_c, (arm_top_z0 + fp_t) - (arm_bot_z1 - fp_t)]);
            translate([coxa_len, 0, z_cell]) servo_cell();
        }
        translate([0, 0, arm_top_z0 - 0.01]) { horn_recess(); horn_holes(fp_t + 1); }
        translate([0, 0, arm_bot_z1 - fp_t - 1]) cylinder(d = pin_d, h = fp_t + 2);
    }
}

/* ---------- Femur: fork around the coxa cell + tibia servo cell ---------- */
module femur() {
    fork(femur_len + sv_cen - cell_half_l);
    translate([femur_len, 0, 0]) servo_cell();
}

/* ---------- Tibia: fork around the femur cell + tapered beam + foot socket ---------- */
module tibia() {
    difference() {
        union() {
            fork(31);
            hull() {
                translate([28, -6, -fh]) cube([3, 12, 2*fh]);
                translate([tibia_len - 3, -5.5, -5.5]) cube([3, 11, 11]);
            }
        }
        translate([tibia_len - 12, -3.1, -3.1]) cube([13, 6.2, 6.2]);   // square socket
        translate([tibia_len - 6, 0, -7]) cylinder(d = pin_d, h = 14);  // M3 cross bolt
    }
}

/* ---------- Foot: square key + 8 mm peg for a rubber cap ---------- */
module foot() {
    difference() {
        union() {
            translate([0, -3, -3]) cube([12, 6, 6]);
            translate([12, 0, 0]) rotate([0, 90, 0]) cylinder(d = 11, h = 2);
            translate([14, 0, 0]) rotate([0, 90, 0]) cylinder(d = 8, h = 10);
        }
        translate([6, 0, -5]) cylinder(d = 3.2, h = 10);
    }
}

/* ---------- Body plates ---------- */
module plate_outline() {
    hull() for (i = [0:5]) rotate(60*i) translate([body_r, 0]) circle(r = corner_r);
}
module common_holes(t) {
    for (i = [0:5]) rotate([0, 0, 30 + 60*i]) translate([standoff_r, 0, -1]) cylinder(d = 3.2, h = t + 2);
    for (x = [-20:20:20], y = [-20:20:20]) translate([x, y, -1]) cylinder(d = 3.2, h = t + 2);
    translate([-12.5, -34, -1]) cube([25, 8, t + 2]);   // wiring slot
}
module top_plate() {
    difference() {
        linear_extrude(tp_t) plate_outline();
        for (i = [0:5]) rotate([0, 0, 60*i]) translate([body_r, 0, 0]) {
            // coxa servo window: shaft on the axis, body pointing inward
            translate([-(sv_l - sv_shaft_off) - clr, -sv_w/2 - clr, -1])
                cube([sv_l + 2*clr, sv_w + 2*clr, tp_t + 2]);
            for (s = [-1, 1])
                translate([-sv_cen + s*sv_hole_sp/2, 0, -1]) cylinder(d = sv_hole_d, h = tp_t + 2);
        }
        common_holes(tp_t);
    }
}
module bottom_plate() {
    difference() {
        linear_extrude(bp_t) plate_outline();
        for (i = [0:5]) rotate([0, 0, 60*i]) translate([body_r, 0, -1]) {
            cylinder(d = seat_d, h = seat_depth + 1);   // bearing seat from underside
            cylinder(d = 4, h = bp_t + 2);
        }
        common_holes(bp_t);
    }
}

/* ---------- Assembly ---------- */
module leg(fem_a = 15, tib_a = -80) {
    coxa_bracket();
    translate([coxa_len, 0, z_cell]) rotate([0, -fem_a, 0]) {
        femur();
        translate([femur_len, 0, 0]) rotate([0, -tib_a, 0]) {
            tibia();
            translate([tibia_len - 12, 0, 0]) foot();
        }
    }
}
module assembly() {
    color("gray") bottom_plate();
    color("gray") translate([0, 0, tp_z]) top_plate();
    color("gold") for (i = [0:5]) rotate([0, 0, 30 + 60*i])
        translate([standoff_r, 0, bp_t]) cylinder(d = 5, h = standoff_h);
    for (i = [0:5]) rotate([0, 0, 60*i]) translate([body_r, 0, 0]) leg();
}

/* ---------- Part selector (print orientations built in) ---------- */
if      (part == "assembly")     assembly();
else if (part == "leg")          leg();
else if (part == "top_plate")    top_plate();
else if (part == "bottom_plate") bottom_plate();
else if (part == "coxa_bracket") translate([0, 0, fh]) rotate([90, 0, 0]) coxa_bracket();
else if (part == "femur")        translate([0, 0, fh]) femur();
else if (part == "tibia")        translate([0, 0, fh]) tibia();
else if (part == "foot")         translate([0, 0, 24]) rotate([0, 90, 0]) foot();
else if (part == "coupon")       translate([0, 0, fh]) servo_cell();
