"""The south bank family: the river's far side in R6, south of the bridge below Aiwyk. Tall dark
poplars, white poplars, the hedge bushes that grow under them, a medieval army's tent with its
racks and banners, and the small finds of river and forest floor: a beaver's stump, a fungus log,
shed antlers, a ring of stones round an old carved post. Trees are built like the woodland family's,
of a limbed trunk and lumps of leaf; canvas and iron come from the village's palette. Each asset is
a small script in tools/blender/assets/ that calls make(<slug>). Colours are sRGB. The kinds and
shapes are placeholders until the author says otherwise (docs/world/regions/R6/art.md).
"""
import math
import random

import kit
import shoreside
import woodland


def palette():
    """The shore's palette and what the south bank adds."""
    p = shoreside.palette()
    p.update(woodland.palette())
    m = kit.material
    p.update({
        "poplar_bark": m("PoplarBark", (0.33, 0.29, 0.23), roughness=1.0),
        "poplar_leaf": m("PoplarLeaf", (0.26, 0.40, 0.17), roughness=0.85),
        "poplar_leaf_dark": m("PoplarLeafDark", (0.19, 0.32, 0.15), roughness=0.85),
        "poplar_leaf_light": m("PoplarLeafLight", (0.36, 0.49, 0.20), roughness=0.85),
        "white_bark": m("WhitePoplarBark", (0.76, 0.75, 0.68), roughness=0.95),
        "white_mark": m("WhitePoplarMark", (0.25, 0.23, 0.20), roughness=1.0),
        "silver_leaf": m("SilverLeaf", (0.60, 0.68, 0.53), roughness=0.75),
        "silver_leaf_pale": m("SilverLeafPale", (0.74, 0.79, 0.68), roughness=0.75),
        "silver_leaf_dark": m("SilverLeafDark", (0.40, 0.50, 0.33), roughness=0.8),
        "canvas": m("TentCanvas", (0.74, 0.68, 0.53), roughness=1.0),
        "canvas_dirty": m("TentCanvasDirty", (0.60, 0.54, 0.41), roughness=1.0),
        "war_red": m("WarRed", (0.50, 0.15, 0.12), roughness=0.95),
        "war_red_dark": m("WarRedDark", (0.36, 0.11, 0.10), roughness=0.95),
        "hazel_leaf": m("HazelLeaf", (0.33, 0.47, 0.19), roughness=0.85),
        "rose_leaf": m("RoseLeaf", (0.24, 0.39, 0.18), roughness=0.85),
        "rose_petal": m("RosePetal", (0.91, 0.62, 0.68), roughness=0.8),
        "fungus": m("BracketFungus", (0.70, 0.48, 0.24), roughness=0.8),
        "fungus_pale": m("BracketFungusPale", (0.86, 0.77, 0.58), roughness=0.8),
        "antler": m("Antler", (0.72, 0.65, 0.50), roughness=0.8),
        "foxglove": m("Foxglove", (0.72, 0.34, 0.62), roughness=0.8),
    })
    return p


# ---- trees


def _column(model, p, rng, height, wide, base, tones):
    """A tall poplar's narrow crown: lumps stacked up the trunk, widest a third of the way up and
    drawing to a point."""
    z = base
    while z < height:
        t = (z - base) / (height - base)
        reach = wide * (min(t / 0.3, 1.0) ** 0.6) * (1.0 - max(t - 0.3, 0.0) / 0.7) ** 0.8 + 0.18
        for k in range(3):
            a = rng.uniform(0, math.tau)
            d = reach * rng.uniform(0.15, 0.55)
            woodland._leaves(model, rng, (math.cos(a) * d, math.sin(a) * d, z + rng.uniform(-0.3, 0.3)), max(reach * rng.uniform(0.62, 0.85), 0.32), rng.choice(tones), flat=1.3, subdivisions=1, roughness=0.12)
        z += 1.05


def tall_poplar_a():
    """A Lombardy poplar, about 19 m: a straight furrowed trunk and a tight dark column of leaf."""
    p = palette()
    rng = random.Random(501)
    model = kit.Model("TallPoplarA")
    woodland._limb(model, [(0, 0, 0), (0.03, 0.02, 3.0), (0.06, 0.02, 9.0), (0.02, 0.05, 17.0)], [0.34, 0.25, 0.16, 0.04], p["poplar_bark"], segments=7)
    for k in range(5):
        a = k * 1.26
        model.cylinder((0, 0, 0.5), (math.cos(a) * 0.62, math.sin(a) * 0.62, -0.02 + 0.03), 0.13, 0.04, p["poplar_bark"], segments=4)
    _column(model, p, rng, 18.6, 1.75, 2.6, (p["poplar_leaf"], p["poplar_leaf"], p["poplar_leaf_dark"], p["poplar_leaf_light"]))
    model.finish()
    kit.collision_cylinder("TallPoplarA", (0, 0, 0), (0, 0, 3.0), 0.34)


def tall_poplar_b():
    """A younger, slimmer poplar, about 14 m, leaning a little, its leaves lighter and its crown
    thin enough to show the trunk low down."""
    p = palette()
    rng = random.Random(502)
    model = kit.Model("TallPoplarB")
    woodland._limb(model, [(0, 0, 0), (0.1, 0.03, 3.0), (0.26, 0.06, 8.0), (0.42, 0.1, 13.0)], [0.22, 0.16, 0.1, 0.03], p["poplar_bark"], segments=6)
    for k in range(13):
        z = 2.6 + k * 0.86
        reach = 1.1 * (1.0 - k / 15)
        a = k * 2.4
        lean = z * 0.03
        woodland._leaves(model, rng, (math.cos(a) * reach * 0.42 + lean, math.sin(a) * reach * 0.42, z), max(reach * 0.72, 0.3), rng.choice((p["poplar_leaf"], p["poplar_leaf_light"], p["poplar_leaf_light"])), flat=1.3, subdivisions=1, roughness=0.12)
    model.finish()
    kit.collision_cylinder("TallPoplarB", (0, 0, 0), (0.1, 0, 3.0), 0.22)


def _white_trunk(model, p, rng, points, radii, marks):
    woodland._limb(model, points, radii, p["white_bark"], segments=7)
    for k in range(marks):
        n = rng.randrange(len(points) - 1)
        t = rng.random()
        a, b = points[n], points[n + 1]
        centre = [a[i] + (b[i] - a[i]) * t for i in range(3)]
        # None so low that it dips under the model's foot.
        centre[2] = max(centre[2], 0.7)
        wide = (radii[n] + (radii[n + 1] - radii[n]) * t) * 1.06
        angle = rng.uniform(0, math.tau)
        # The diamond scars white poplars carry, where they shed low branches.
        model.sphere((centre[0] + math.cos(angle) * wide * 0.8, centre[1] + math.sin(angle) * wide * 0.8, centre[2]), wide * 0.42, p["white_mark"], scale=(0.75, 0.75, 1.15), segments=4, rings=2)


def _silver_crown(model, p, rng, clusters, reach, base, top, radius):
    tones = (p["silver_leaf"], p["silver_leaf"], p["silver_leaf_pale"], p["silver_leaf_dark"])
    for k in range(clusters):
        t = k / max(clusters - 1, 1)
        z = base + (top - base) * t
        d = reach * (1.0 - abs(t - 0.4) * 1.25) * rng.uniform(0.55, 1.0)
        a = k * 2.4 + rng.uniform(-0.4, 0.4)
        woodland._leaves(model, rng, (math.cos(a) * d, math.sin(a) * d, z), radius * rng.uniform(0.8, 1.15), rng.choice(tones), flat=0.82, subdivisions=1, roughness=0.14)


def white_poplar_a():
    """A white poplar, about 15 m: a pale trunk scarred with dark diamonds, forking high, under a
    broad crown of leaves silver beneath."""
    p = palette()
    rng = random.Random(503)
    model = kit.Model("WhitePoplarA")
    _white_trunk(model, p, rng, [(0, 0, 0), (0.05, 0, 3.0), (0.14, 0.05, 6.5)], [0.42, 0.3, 0.2], 18)
    for a, out, z in ((0.4, 2.6, 11.0), (2.5, 2.3, 10.6), (4.4, 2.4, 11.6)):
        model.cylinder((0.14, 0.05, 6.3), (math.cos(a) * out, math.sin(a) * out, z), 0.17, 0.05, p["white_bark"], segments=5)
    _silver_crown(model, p, rng, 22, 3.6, 7.5, 14.6, 1.75)
    model.finish()
    kit.collision_cylinder("WhitePoplarA", (0, 0, 0), (0, 0, 3.0), 0.42)


def white_poplar_b():
    """A younger white poplar, about 11 m, straighter and paler, its crown narrower and higher."""
    p = palette()
    rng = random.Random(504)
    model = kit.Model("WhitePoplarB")
    _white_trunk(model, p, rng, [(0, 0, 0), (-0.06, 0.03, 3.0), (-0.1, 0.1, 8.5)], [0.26, 0.19, 0.08], 14)
    _silver_crown(model, p, rng, 15, 2.2, 4.8, 10.8, 1.3)
    model.finish()
    kit.collision_cylinder("WhitePoplarB", (0, 0, 0), (0, 0, 3.0), 0.26)


# ---- bushes and plants


def _thicket(model, rng, lumps, reach, high, tones):
    for k in range(lumps):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.0, reach)
        z = high * rng.uniform(0.35, 1.0) * (1.0 - d / reach * 0.5)
        model.rock((math.cos(a) * d, math.sin(a) * d, z), rng.uniform(0.32, 0.48), rng.choice(tones), rng, scale=(1.15, 1.05, 0.85), subdivisions=1, roughness=0.24)


def hazel_bush():
    """A hazel: many straight rods from one stool and soft light leaf, about 2.8 m tall."""
    p = palette()
    rng = random.Random(510)
    model = kit.Model("HazelBush")
    for k in range(9):
        a = rng.uniform(0, math.tau)
        out = rng.uniform(0.4, 1.0)
        model.cylinder((math.cos(a) * 0.14, math.sin(a) * 0.14, 0), (math.cos(a) * out, math.sin(a) * out, rng.uniform(1.8, 2.6)), 0.04, 0.012, p["bark"], segments=3)
    _thicket(model, rng, 12, 1.05, 2.5, (p["hazel_leaf"], p["hazel_leaf"], p["leaf_light"], p["leaf_mid"]))
    model.finish()


def dog_rose():
    """A dog rose: a low mound of dark leaf and arching stems, scattered with pale pink flowers and
    a few red hips. About 2 m across."""
    p = palette()
    rng = random.Random(511)
    model = kit.Model("DogRose")
    _thicket(model, rng, 8, 0.72, 0.85, (p["rose_leaf"], p["rose_leaf"], p["leaf_mid"]))
    for k in range(16):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.3, 0.98)
        z = rng.uniform(0.4, 1.15) * (1.2 - d * 0.6)
        model.sphere((math.cos(a) * d, math.sin(a) * d, z), 0.07, p["rose_petal"], scale=(1.0, 1.0, 0.4), segments=5, rings=2)
        if k % 3 == 0:
            model.sphere((math.cos(a + 0.5) * d, math.sin(a + 0.5) * d, z * 0.9), 0.032, p["petal_red"], segments=4, rings=2)
    model.finish()


def cow_parsley():
    """A stand of cow parsley: thin hollow stems and flat white heads, as high as a hip."""
    p = palette()
    rng = random.Random(512)
    model = kit.Model("CowParsley")
    for k in range(5):
        x, y = rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3)
        tall = rng.uniform(0.8, 1.1)
        model.cylinder((x, y, 0), (x, y, tall), 0.009, 0.006, p["leaf_light"], segments=3, caps=False)
        model.sphere((x, y, tall), 0.13, p["petal_white"], scale=(1.0, 1.0, 0.2), segments=6, rings=2)
        model.blade((x, y, 0.0), rng.uniform(0, math.tau), 0.4, 0.14, 1.0, p["leaf_mid"], segments=2)
    model.finish()


def foxglove():
    """Foxgloves on the wood's edge: tall spires hung with purple bells over a rosette of leaves."""
    p = palette()
    rng = random.Random(513)
    model = kit.Model("Foxglove")
    for k in range(3):
        x, y = rng.uniform(-0.2, 0.2), rng.uniform(-0.2, 0.2)
        tall = rng.uniform(0.95, 1.3)
        model.cylinder((x, y, 0), (x, y, tall), 0.012, 0.005, p["leaf_mid"], segments=3, caps=False)
        for n in range(8):
            z = tall * (0.45 + n * 0.07)
            a = n * 2.4
            size = 0.05 * (1.0 - n * 0.07)
            model.sphere((x + math.cos(a) * 0.045, y + math.sin(a) * 0.045, z), size, p["foxglove"], scale=(0.8, 0.8, 1.3), segments=4, rings=2)
        for n in range(4):
            model.blade((x, y, 0.0), rng.uniform(0, math.tau), 0.32, 0.11, 1.1, p["leaf_deep"], segments=2)
    model.finish()


def berry_patch():
    """Bilberries: a low mat of small leaves on the forest floor, thick with dark fruit."""
    p = palette()
    rng = random.Random(514)
    model = kit.Model("BerryPatch")
    for k in range(7):
        model.rock((rng.uniform(-0.42, 0.42), rng.uniform(-0.42, 0.42), 0.04), rng.uniform(0.15, 0.24), rng.choice((p["leaf_deep"], p["leaf_mid"])), rng, scale=(1.2, 1.1, 0.55), roughness=0.16)
    for k in range(14):
        model.sphere((rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), rng.uniform(0.1, 0.17)), 0.024, p["berry"], segments=4, rings=2)
    model.finish()


# ---- the tent and its camp


def military_tent():
    """A medieval army's pavilion: a round wall of weathered canvas, a conical roof on a stout pole
    with a red crown and red seams, a scalloped red valance, its door flaps tied back on the dark, guy ropes to pegs and a
    pennant on top. About 7 m across and 5.5 m tall. Reads from -Y."""
    p = palette()
    rng = random.Random(520)
    model = kit.Model("MilitaryTent")
    radius, wall, peak = 3.1, 1.75, 4.6
    segments = 20
    door = 1  # Panels either side of -Y left open.
    # Dark inside, seen through the door, with a floor, a pallet and the pole.
    model.cylinder((0, 0, 0.0), (0, 0, 0.03), radius - 0.05, radius - 0.05, p["floor"], segments=segments)
    model.cylinder((0, 0, 0.03), (0, 0, peak + 0.5), 0.075, 0.055, p["log_dark"], segments=6)
    model.box((1.2, 0.9, 0.17), (1.6, 0.8, 0.3), p["hay_old"], rotation_z=0.5)
    model.box((-1.3, 0.7, 0.35), (0.7, 0.7, 0.7), p["plank_dark"], rotation_z=0.3)
    start = -math.pi / 2
    for k in range(segments):
        a0 = start + math.tau * k / segments
        a1 = start + math.tau * (k + 1) / segments
        p0, p1 = (math.cos(a0), math.sin(a0)), (math.cos(a1), math.sin(a1))
        tone = rng.choice((p["canvas"], p["canvas"], p["canvas_dirty"]))
        # The roof runs unbroken, a red crown over the canvas; the wall stops at the door.
        crown = 0.74
        q0, q1 = (p0[0] * radius * (1 - crown), p0[1] * radius * (1 - crown)), (p1[0] * radius * (1 - crown), p1[1] * radius * (1 - crown))
        high = wall + (peak - wall) * crown
        shoreside._skin(model, tone, (p0[0] * radius, p0[1] * radius, wall), (p1[0] * radius, p1[1] * radius, wall), (q1[0], q1[1], high), (q0[0], q0[1], high), 0.03, (0.0, 0.0, 0.0))
        shoreside._skin(model, p["war_red"], (q0[0], q0[1], high), (q1[0], q1[1], high), (0.0, 0.0, peak), (0.0, 0.0, peak), 0.03, (0.0, 0.0, 0.0))
        if k % 5 == 0:
            model.cylinder((p0[0] * radius * 1.01, p0[1] * radius * 1.01, wall + 0.02), (q0[0], q0[1], high + 0.02), 0.03, 0.03, p["war_red_dark"], segments=3)
        if k >= door and k < segments - door:
            lean = 1.03
            shoreside._skin(model, tone, (p0[0] * radius * lean, p0[1] * radius * lean, 0.0), (p1[0] * radius * lean, p1[1] * radius * lean, 0.0), (p1[0] * radius, p1[1] * radius, wall), (p0[0] * radius, p0[1] * radius, wall), 0.03, (0.0, 0.0, wall / 2))
        # The valance, a tongue hanging at each panel's eave.
        mid = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
        out = radius + 0.05
        shoreside._skin(model, p["war_red"] if k % 2 else p["war_red_dark"], (p0[0] * out, p0[1] * out, wall + 0.03), (p1[0] * out, p1[1] * out, wall + 0.03), (mid[0] * out + 0.001, mid[1] * out, wall - 0.36), (mid[0] * out, mid[1] * out, wall - 0.36), 0.015, (0.0, 0.0, wall))
    # The door's flaps tied back to either side, and the posts holding it.
    for side in (-1, 1):
        a = start + side * math.tau * door / segments
        at = (math.cos(a) * radius, math.sin(a) * radius)
        model.cylinder((at[0], at[1], 0), (at[0], at[1], wall), 0.04, 0.035, p["log_dark"], segments=5)
        shoreside._skin(model, p["canvas_dirty"], (at[0], at[1], wall - 0.05), (at[0] + side * 0.42, at[1] - 0.24, wall * 0.55), (at[0] + side * 0.34, at[1] - 0.2, 0.05), (at[0], at[1], 0.05), 0.02, (at[0], at[1] + 1.0, wall / 2))
    # The ball, the staff and the pennant at the top.
    model.sphere((0, 0, peak + 0.02), 0.13, p["iron"], segments=6, rings=4)
    model.slab([(0.03, -0.012, peak + 0.5), (0.95, -0.012, peak + 0.42), (0.95, 0.012, peak + 0.42), (0.03, 0.012, peak + 0.5)], 0.1, p["war_red"])
    model.slab([(0.03, -0.012, peak + 0.4), (0.7, -0.012, peak + 0.3), (0.7, 0.012, peak + 0.3), (0.03, 0.012, peak + 0.4)], 0.1, p["war_red_dark"])
    # Guy ropes from the eave to pegs in the ground.
    for k in range(10):
        a = start + math.tau * (k + 0.5) / 10
        if abs(math.sin(a) + 1.0) < 0.08:
            continue
        eave = (math.cos(a) * radius, math.sin(a) * radius, wall)
        peg = (math.cos(a) * (radius + 1.25), math.sin(a) * (radius + 1.25), 0.2)
        model.cylinder(eave, peg, 0.009, 0.009, p["rope"], segments=3, caps=False)
        model.cylinder((peg[0], peg[1], 0.0), (peg[0] * 1.01, peg[1] * 1.01, 0.28), 0.03, 0.02, p["bark"], segments=4)
    # Mud on the skirts.
    for k in range(7):
        a = start + rng.uniform(0.4, math.tau - 0.4)
        model.rock((math.cos(a) * (radius + 0.04), math.sin(a) * (radius + 0.04), 0.06), rng.uniform(0.15, 0.25), p["silt"], rng, scale=(1.6, 0.5, 0.5), roughness=0.14)
    model.finish()
    for k in range(8):
        a = start + math.tau * (k + 1) / 9
        kit.collision_cylinder(f"MilitaryTent{k}", (math.cos(a) * (radius - 0.2), math.sin(a) * (radius - 0.2), 0), (math.cos(a) * (radius - 0.2), math.sin(a) * (radius - 0.2), wall), 0.7, segments=6)
    kit.collision_cylinder("MilitaryTentPole", (0, 0, 0), (0, 0, peak), 0.1, segments=6)


def weapon_rack():
    """A rack of spears leaning on a rail, round shields painted red and pale hung along it, and an
    axe stuck in its post. About 3 m long. Reads from -Y."""
    p = palette()
    rng = random.Random(521)
    model = kit.Model("WeaponRack")
    half = 1.45
    for x in (-half, half):
        model.cylinder((x, 0, 0), (x, 0, 1.55), 0.06, 0.05, p["log_dark"], segments=5)
        model.cylinder((x, 0.55, 0), (x, 0, 1.2), 0.04, 0.035, p["bark"], segments=4)
    model.cylinder((-half - 0.08, 0, 1.45), (half + 0.08, 0, 1.45), 0.04, 0.04, p["log"], segments=5)
    model.cylinder((-half - 0.08, 0, 0.3), (half + 0.08, 0, 0.3), 0.03, 0.03, p["log"], segments=4)
    for k in range(6):
        x = -1.2 + k * 0.42 + rng.uniform(-0.03, 0.03)
        # Leaning on the rail from behind, so the shields hang in front of them.
        foot = (x, 0.4, 0.0)
        tip = (x + rng.uniform(-0.05, 0.05), -0.3, 2.55)
        model.cylinder(foot, tip, 0.017, 0.014, p["wood_drift"], segments=4)
        model.cylinder(tip, (tip[0], tip[1] - 0.04, tip[2] + 0.3), 0.034, 0.003, p["steel"], segments=4)
    for x, tone, boss in ((-0.8, "war_red", "iron"), (0.8, "canvas", "iron")):
        model.cylinder((x, -0.08, 0.95), (x, -0.13, 0.95), 0.42, 0.42, p[tone], segments=12)
        model.cylinder((x, -0.13, 0.95), (x, -0.16, 0.95), 0.44, 0.44, p["log_dark"], segments=12, caps=False)
        model.sphere((x, -0.16, 0.95), 0.08, p[boss], scale=(1, 0.6, 1), segments=6, rings=3)
    model.box((half, -0.08, 1.05), (0.2, 0.03, 0.15), p["steel"])
    model.cylinder((half + 0.05, -0.08, 1.05), (half + 0.55, -0.12, 0.55), 0.016, 0.014, p["wood_drift"], segments=4)
    model.finish()
    kit.collision_box("WeaponRack", (0, 0, 0.75), (3.0, 0.5, 1.5))


def war_banner():
    """A tall war banner on a cross-staff, long tails of red with a pale stripe, its foot in a heap
    of stones. About 5 m tall. Reads from -Y."""
    p = palette()
    rng = random.Random(522)
    model = kit.Model("WarBanner")
    model.cylinder((0, 0, 0), (0, 0, 4.9), 0.06, 0.04, p["log_dark"], segments=6)
    model.cylinder((-0.8, 0, 4.3), (0.8, 0, 4.3), 0.03, 0.03, p["log"], segments=4)
    model.cylinder((0, 0, 4.9), (0, 0, 5.2), 0.045, 0.002, p["steel"], segments=4)
    for k in range(4):
        x0, x1 = -0.75 + k * 0.375, -0.75 + (k + 1) * 0.375 - 0.015
        tone = p["canvas"] if k == 1 else p["war_red"]
        bottom = 2.25 - abs(k - 1.5) * 0.28
        points = [4.28, 3.3, bottom]
        for n, (top, low) in enumerate(zip(points, points[1:])):
            y0, y1 = n * 0.06, (n + 1) * 0.06
            shoreside._skin(model, tone, (x0, y0, top), (x1, y0, top), (x1, y1, low), (x0, y1, low), 0.012, (0.0, 1.0, 3.0))
    for k in range(9):
        a = k * math.tau / 9
        model.rock((math.cos(a) * 0.32, math.sin(a) * 0.3, 0.12), rng.uniform(0.14, 0.22), rng.choice((p["stone_mid"], p["stone_dark"], p["stone_light"])), rng, scale=(1.2, 1.0, 0.8))
    model.finish()
    kit.collision_cylinder("WarBanner", (0, 0, 0), (0, 0, 2.0), 0.3, segments=6)


# ---- found on the ground


def gnawed_stump():
    """A beaver's work: a stump chewed to a point, the fallen top still beside it, and pale chips."""
    p = palette()
    rng = random.Random(530)
    model = kit.Model("GnawedStump")
    model.cylinder((0, 0, 0), (0, 0, 0.36), 0.3, 0.25, p["poplar_bark"], segments=8)
    model.cylinder((0, 0, 0.36), (0.02, 0.01, 0.8), 0.24, 0.015, p["fungus_pale"], segments=8)
    model.cylinder((0.3, 0.1, 0.2), (2.6, 1.1, 0.14), 0.22, 0.13, p["poplar_bark"], segments=7)
    model.cylinder((0.3, 0.1, 0.2), (0.05, 0.0, 0.26), 0.22, 0.02, p["fungus_pale"], segments=7)
    for k in range(3):
        a = rng.uniform(-0.8, 1.4)
        q = (1.4 + k * 0.5, 0.65 + k * 0.2, 0.2)
        model.cylinder(q, (q[0] + math.cos(a) * 0.7, q[1] + math.sin(a) * 0.7, 0.5), 0.035, 0.012, p["poplar_bark"], segments=3)
    for k in range(18):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.3, 0.9)
        model.box((math.cos(a) * d, math.sin(a) * d, 0.015), (rng.uniform(0.05, 0.13), 0.04, 0.02), p["fungus_pale"], rotation_z=rng.uniform(0, 3.1))
    model.finish()
    kit.collision_cylinder("GnawedStump", (0, 0, 0), (0, 0, 0.7), 0.3, segments=7)


def bracket_log():
    """An old log going back to the ground, moss along its back and shelves of bracket fungus on its
    side. About 3.4 m long."""
    p = palette()
    rng = random.Random(531)
    model = kit.Model("BracketLog")
    model.cylinder((-1.7, 0, 0.24), (1.7, 0.1, 0.2), 0.29, 0.23, p["log_dark"], segments=8)
    for x in (-1.72, 1.71):
        model.cylinder((x, 0.0 if x < 0 else 0.1, 0.24 if x < 0 else 0.2), (x * 1.005, 0.0 if x < 0 else 0.1, 0.24 if x < 0 else 0.2), 0.2, 0.2, p["plank"], segments=8)
    for k in range(6):
        model.rock((-1.3 + k * 0.5 + rng.uniform(-0.1, 0.1), 0.03, 0.44), 0.26, p["moss"], rng, scale=(1.4, 0.8, 0.3), roughness=0.12)
    for k in range(9):
        x = rng.uniform(-1.4, 1.4)
        z = rng.uniform(0.14, 0.36)
        wide = rng.uniform(0.09, 0.17)
        tone = p["fungus"] if k % 3 else p["fungus_pale"]
        model.sphere((x, -0.28, z), wide, tone, scale=(1.15, 0.72, 0.26), segments=7, rings=3)
    model.finish()
    kit.collision_box("BracketLog", (0, 0.05, 0.25), (3.4, 0.55, 0.5))


def shed_antlers():
    """A stag's shed antlers lying in the grass, worn pale and a little gnawed. About 1 m across."""
    p = palette()
    model = kit.Model("ShedAntlers")
    for side, shift in ((-1, 0.0), (1, 0.12)):
        points = [(side * 0.05, shift, 0.06), (side * 0.28, shift + 0.08, 0.1), (side * 0.48, shift + 0.25, 0.09), (side * 0.56, shift + 0.5, 0.13)]
        for a, b in zip(points, points[1:]):
            model.cylinder(a, b, 0.032, 0.025, p["antler"], segments=5)
        for q, tip in ((points[1], (side * 0.42, shift - 0.1, 0.24)), (points[2], (side * 0.7, shift + 0.16, 0.26)), (points[3], (side * 0.72, shift + 0.62, 0.3))):
            model.cylinder(q, tip, 0.022, 0.004, p["antler"], segments=4)
        model.sphere(points[0], 0.05, p["antler"], segments=5, rings=3)
    model.box((0, 0, 0.01), (0.04, 0.04, 0.02), p["antler"])
    model.finish()


def stone_ring():
    """A low ring of stones, old and half sunk, with moss on them and grass growing up inside. About
    5 m across."""
    p = palette()
    rng = random.Random(533)
    model = kit.Model("StoneRing")
    count = 11
    for k in range(count):
        a = k * math.tau / count + rng.uniform(-0.05, 0.05)
        at = (math.cos(a) * 2.35, math.sin(a) * 2.35, 0.1)
        r = rng.uniform(0.26, 0.42)
        model.rock(at, r, rng.choice((p["stone_mid"], p["stone_dark"], p["stone_light"])), rng, scale=(1.05, 0.9, 1.15), roughness=0.14)
        if k % 2:
            model.rock((at[0], at[1], 0.1 + r * 1.0), r * 0.6, p["moss"], rng, scale=(1.2, 1.0, 0.3), roughness=0.12)
    model.finish()


def forest_idol():
    """An old carved post of the people who raised the church: a face under a brow, a ring below,
    tar long gone grey, leaning, moss on its shoulder. About 2.6 m tall. Faces -Y."""
    p = palette()
    rng = random.Random(534)
    model = kit.Model("ForestIdol")
    lean = 0.03
    model.cylinder((0, 0, 0), (0.08, 0, 2.5), 0.27, 0.2, p["sea_wood_dark"], segments=8)
    y = -0.23
    for z, wide in ((2.0, 0.17), (1.85, 0.12)):
        model.box((0.06, y, z), (wide * 2, 0.06, 0.05), p["sea_wood"])
    model.box((0.06, y - 0.03, 1.7), (0.05, 0.08, 0.27), p["sea_wood"])
    for side in (-1, 1):
        model.sphere((0.06 + side * 0.09, y - 0.03, 1.83), 0.042, p["shadow"], segments=5, rings=3)
    model.box((0.06, y, 1.5), (0.24, 0.05, 0.035), p["shadow"])
    segments = 12
    for k in range(segments):
        a0, a1 = math.tau * k / segments, math.tau * (k + 1) / segments
        model.cylinder((0.04 + math.cos(a0) * 0.13, y - 0.02, 0.95 + math.sin(a0) * 0.13), (0.04 + math.cos(a1) * 0.13, y - 0.02, 0.95 + math.sin(a1) * 0.13), 0.014, 0.014, p["rune"], segments=3, caps=False)
    for z in (0.4, 0.62):
        model.cylinder((lean, 0, z), (lean, 0, z + 0.05), 0.285, 0.285, p["sea_wood"], segments=8, caps=False)
    model.rock((0.1, 0.1, 2.45), 0.24, p["moss"], rng, scale=(1.2, 1.0, 0.45), roughness=0.14)
    model.rock((0.2, 0.08, 0.2), 0.26, p["moss"], rng, scale=(1.0, 1.0, 0.7), roughness=0.14)
    model.finish()
    kit.collision_cylinder("ForestIdol", (0, 0, 0), (0, 0, 2.5), 0.28, segments=7)


BUILDERS = {fn.__name__: fn for fn in (
    tall_poplar_a, tall_poplar_b, white_poplar_a, white_poplar_b, hazel_bush, dog_rose, cow_parsley,
    foxglove, berry_patch, military_tent, weapon_rack, war_banner, gnawed_stump, bracket_log,
    shed_antlers, stone_ring, forest_idol,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
