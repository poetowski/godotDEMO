"""The wildwood family: R8's old forest between the orchard and the western cliff, its rocks
and floor, and the half abandoned camp in R2 and R3. It shares the woodland family's bark and
greens, a shade darker, so the forest reads as deeper than the farm's trees. Each asset is a
small script in tools/blender/assets/ that calls make(<slug>). Colours are sRGB. The kinds and
shapes are placeholders until the author says otherwise (docs/world/regions/R8/art.md).
"""
import math
import random

import kit
import woodland
from woodland import _leaves, _limb, _out, _roots


def palette():
    """The woodland palette and the forest's and camp's own materials."""
    p = woodland.palette()
    m = kit.material
    p.update({
        "spruce_dark": m("SpruceDark", (0.08, 0.20, 0.15), roughness=0.9),
        "spruce_mid": m("SpruceMid", (0.11, 0.26, 0.17), roughness=0.9),
        "spruce_light": m("SpruceLight", (0.17, 0.33, 0.20), roughness=0.9),
        "hornbeam_dark": m("HornbeamDark", (0.16, 0.30, 0.13), roughness=0.85),
        "hornbeam_mid": m("HornbeamMid", (0.22, 0.38, 0.15), roughness=0.85),
        "ash_mid": m("AshMid", (0.29, 0.43, 0.18), roughness=0.85),
        "ash_light": m("AshLight", (0.38, 0.50, 0.21), roughness=0.85),
        "dark_bark": m("DarkBark", (0.24, 0.20, 0.16), roughness=1.0),
        "dead_wood": m("DeadWood", (0.47, 0.43, 0.37), roughness=1.0),
        "rock_dark": m("RockDark", (0.31, 0.32, 0.32), roughness=0.95),
        "bracken": m("Bracken", (0.26, 0.42, 0.17), roughness=0.85),
        "bracken_old": m("BrackenOld", (0.52, 0.38, 0.18), roughness=0.9),
        "litter_a": m("LitterA", (0.42, 0.30, 0.16), roughness=1.0),
        "litter_b": m("LitterB", (0.54, 0.40, 0.19), roughness=1.0),
        "mushroom": m("Mushroom", (0.82, 0.72, 0.56), roughness=0.8),
        "mushroom_cap": m("MushroomCap", (0.56, 0.27, 0.15), roughness=0.7),
        "canvas": m("Canvas", (0.62, 0.56, 0.42), roughness=1.0),
        "canvas_dark": m("CanvasDark", (0.42, 0.36, 0.27), roughness=1.0),
        "canvas_patch": m("CanvasPatch", (0.45, 0.33, 0.25), roughness=1.0),
        "hide": m("Hide", (0.46, 0.34, 0.23), roughness=1.0),
        "plank": m("Plank", (0.46, 0.35, 0.23), roughness=0.95),
        "plank_old": m("PlankOld", (0.38, 0.32, 0.26), roughness=1.0),
        "iron": m("Iron", (0.20, 0.20, 0.21), roughness=0.65, metallic=0.5),
        "rope": m("Rope", (0.60, 0.51, 0.34), roughness=1.0),
        "char": m("Char", (0.07, 0.06, 0.06), roughness=1.0),
        "ash_grey": m("AshGrey", (0.47, 0.46, 0.44), roughness=1.0),
        "ember": m("Ember", (0.95, 0.36, 0.09), roughness=0.8, emission=(1.0, 0.36, 0.08), emission_strength=2.2),
    })
    return p


# ---- trees


def _spruce(name, seed, height, width, tiers, drop, tones, foot=0.42):
    """A spruce: a straight dark trunk under close tiers that droop at their rims."""
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    _roots(model, rng, foot, foot * 2.8, 5, p["dark_bark"])
    _limb(model, [(0, 0, 0), (0.03, -0.02, height * 0.45), (0, 0, height)], [foot, foot * 0.55, 0.02], p["dark_bark"], segments=7)
    z = drop
    step = (height - drop) / tiers
    for k in range(tiers):
        t = k / (tiers - 1)
        wide = width * (1.0 - t) ** 0.9 + 0.32
        tone = p[tones[min(int(t * len(tones)), len(tones) - 1)]]
        off = (rng.uniform(-0.1, 0.1), rng.uniform(-0.1, 0.1))
        model.cylinder((off[0], off[1], z), (off[0] * 0.2, off[1] * 0.2, z + step * 1.9), wide, wide * 0.1, tone, segments=8)
        for n in range(3):
            angle = rng.uniform(0, math.tau)
            model.cylinder(_out(angle, wide * 0.5, z + 0.25), _out(angle, wide * 1.18, z - 0.3), wide * 0.2, 0.03, tone, segments=4)
        z += step
    model.finish()
    kit.collision_cylinder(name, (0, 0, 0), (0, 0, 5.0), foot + 0.02)


def forest_spruce_a():
    """A spruce of the forest's body, about 15 m."""
    _spruce("ForestSpruceA", 101, 15.0, 2.7, 9, 1.8, ("spruce_dark", "spruce_mid", "spruce_light"))


def forest_spruce_b():
    """A giant among the spruces, about 22 m, bare a long way up."""
    _spruce("ForestSpruceB", 102, 22.0, 3.6, 11, 4.2, ("spruce_dark", "spruce_dark", "spruce_mid", "spruce_light"), foot=0.58)


def young_fir():
    """A young fir of the understorey, about 4.5 m, green down to the ground."""
    _spruce("YoungFir", 103, 4.5, 1.25, 5, 0.3, ("spruce_mid", "spruce_light"), foot=0.09)


def forest_hornbeam():
    """A hornbeam, about 13 m: a fluted grey trunk and a dark, close dome."""
    p = palette()
    rng = random.Random(104)
    model = kit.Model("ForestHornbeam")
    _roots(model, rng, 0.42, 1.2, 6, p["grey_bark"])
    fork = 3.8
    _limb(model, [(0, 0, 0), (0.08, 0.04, 2.0), (0.02, -0.05, fork)], [0.44, 0.34, 0.3], p["grey_bark"], segments=7)
    for k in range(4):
        angle = math.tau * k / 4 + rng.uniform(-0.35, 0.35)
        tip = _out(angle, rng.uniform(1.7, 2.7), fork + rng.uniform(3.0, 4.4))
        _limb(model, [(0.02, -0.05, fork - 0.3), tip], [0.2, 0.06], p["grey_bark"], segments=5)
        _leaves(model, rng, tip, rng.uniform(2.1, 2.7), p["hornbeam_dark"], subdivisions=1)
    _leaves(model, rng, (0, 0, 10.1), 3.5, p["hornbeam_mid"], flat=0.8, subdivisions=2)
    for k in range(5):
        angle = rng.uniform(0, math.tau)
        _leaves(model, rng, _out(angle, rng.uniform(1.6, 3.1), rng.uniform(9.5, 11.1)), rng.uniform(1.0, 1.6), p["hornbeam_mid" if k % 2 else "hornbeam_dark"], subdivisions=1)
    model.finish()
    kit.collision_cylinder("ForestHornbeam", (0, 0, 0), (0, 0, 3.8), 0.42)


def forest_ash():
    """A tall ash, about 19 m: a long clean trunk reaching for the light, its crown high up
    in loose separate clouds."""
    p = palette()
    rng = random.Random(105)
    model = kit.Model("ForestAsh")
    _roots(model, rng, 0.46, 1.25, 6, p["grey_bark"])
    fork = 10.0
    _limb(model, [(0, 0, 0), (-0.12, 0.08, 4.5), (0.1, -0.05, fork)], [0.48, 0.34, 0.24], p["grey_bark"], segments=7)
    for k in range(5):
        angle = math.tau * k / 5 + rng.uniform(-0.3, 0.3)
        tip = _out(angle, rng.uniform(1.6, 3.5), fork + rng.uniform(3.4, 6.3))
        _limb(model, [(0.1, -0.05, fork - 0.4), tip], [0.15, 0.04], p["grey_bark"], segments=4)
        _leaves(model, rng, tip, rng.uniform(1.8, 2.6), p["ash_mid" if k % 2 else "ash_light"], flat=0.68, subdivisions=1)
    _leaves(model, rng, (0.1, 0, fork + 5.8), 2.6, p["ash_light"], flat=0.72, subdivisions=1)
    model.finish()
    kit.collision_cylinder("ForestAsh", (0, 0, 0), (0, 0, 5.0), 0.44)


def dead_pine():
    """A dead pine, about 11 m: silver wood, the top snapped off, a few stubs left."""
    p = palette()
    rng = random.Random(106)
    model = kit.Model("DeadPine")
    _roots(model, rng, 0.34, 1.0, 5, p["dead_wood"])
    _limb(model, [(0, 0, 0), (0.12, 0.06, 5.0), (0.3, 0.02, 10.9)], [0.36, 0.25, 0.1], p["dead_wood"], segments=6)
    for k in range(7):
        z = rng.uniform(3.4, 9.6)
        angle = rng.uniform(0, math.tau)
        at = z / 11.0 * 0.28
        reach = rng.uniform(0.5, 1.8)
        model.cylinder((at, 0, z), (at + math.cos(angle) * reach, math.sin(angle) * reach, z + rng.uniform(-0.3, 0.5)), 0.07, 0.015, p["dead_wood"], segments=4)
    model.finish()
    kit.collision_cylinder("DeadPine", (0, 0, 0), (0, 0, 5.0), 0.36)


def fallen_trunk():
    """A long trunk lying on the forest floor, about 8 m, rotting and mossy, a shelf of
    root plate at one end."""
    p = palette()
    rng = random.Random(107)
    model = kit.Model("FallenTrunk")
    a, b, c = (-3.9, 0, 0.38), (0.0, 0.12, 0.34), (4.0, -0.1, 0.2)
    _limb(model, [a, b, c], [0.42, 0.36, 0.2], p["dark_bark"], segments=8)
    for k in range(8):
        angle = math.tau * k / 8
        model.cylinder((-3.85, 0, 0.42), (-4.2, math.cos(angle) * 1.05, 0.42 + math.sin(angle) * 0.4 + 0.4), 0.14, 0.03, p["dark_bark"], segments=4)
    for x, y, r in ((-2.6, 0.03, 0.45), (-0.7, 0.1, 0.5), (1.5, 0.0, 0.38), (3.0, -0.05, 0.25)):
        model.rock((x, y, 0.42 + r * 0.25), r, p["moss"], rng, scale=(1.6, 0.8, 0.42))
    model.finish()
    kit.collision_slab("FallenTrunk", (-3.9, 0.0, 0.0), (4.0, 0.0, 0.0), 0.72, 0.72)


# ---- rocks


def _forest_rock(name, seed, radius, squash, moss):
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    height = radius * squash
    model.rock((0, 0, height * 0.42), radius, p["rock_dark"], rng, scale=(1.0, 0.82, squash), subdivisions=2, roughness=0.26)
    model.rock((radius * 0.52, radius * 0.25, height * 0.2), radius * 0.46, p["stone_mid"], rng, scale=(1.0, 0.8, 0.72), subdivisions=1)
    for k in range(moss):
        angle = rng.uniform(0, math.tau)
        model.rock(_out(angle, radius * rng.uniform(0.1, 0.48), height * rng.uniform(0.92, 1.18)), radius * rng.uniform(0.35, 0.52), p["moss"], rng, scale=(1.0, 0.85, 0.3), subdivisions=1)
    model.finish()
    kit.collision_cylinder(name, (0, 0, 0), (0, 0, height * 1.2), radius * 0.86, segments=8)


def forest_rock_a():
    """A dark mossy rock, chest high."""
    _forest_rock("ForestRockA", 111, 1.15, 0.72, 3)


def forest_rock_b():
    """A low wide rock, moss over its top."""
    _forest_rock("ForestRockB", 112, 1.7, 0.42, 4)


def forest_crag():
    """A broken crag of the cliff's rock pushing through the forest floor, about 4 m tall,
    in leaning slabs."""
    p = palette()
    rng = random.Random(113)
    model = kit.Model("ForestCrag")
    for x, y, r, z, s, tone in (
        (0.0, 0.0, 2.1, 1.7, (0.9, 0.7, 1.15), "rock_dark"),
        (1.5, 0.4, 1.5, 1.0, (0.8, 0.8, 0.95), "stone_dark"),
        (-1.4, -0.3, 1.45, 0.75, (1.0, 0.75, 0.82), "rock_dark"),
        (0.4, -1.2, 1.1, 0.45, (1.2, 0.7, 0.62), "stone_mid"),
    ):
        model.rock((x, y, z), r, p[tone], rng, scale=s, subdivisions=2, roughness=0.28)
    for x, y, z, r in ((-0.3, 0.2, 3.5, 0.72), (-1.5, -0.3, 1.8, 0.75), (1.5, 0.4, 2.2, 0.58)):
        model.rock((x, y, z), r, p["moss"], rng, scale=(1.0, 0.85, 0.28), subdivisions=1)
    model.finish()
    kit.collision_cylinder("ForestCrag", (0, 0, 0), (0, 0, 3.6), 2.0, segments=8)


# ---- the forest's floor


def bracken():
    """A knee-high clump of bracken, some of it gone brown."""
    p = palette()
    rng = random.Random(121)
    model = kit.Model("Bracken")
    for k in range(9):
        angle = math.tau * k / 9 + rng.uniform(-0.2, 0.2)
        tone = p["bracken_old"] if rng.random() < 0.2 else p["bracken"]
        model.frond((math.cos(angle) * 0.05, math.sin(angle) * 0.05, 0.0), angle, rng.uniform(0.55, 0.85), tone, leaflets=5)
    model.finish()


def leaf_litter():
    """A drift of fallen leaves, lying flat."""
    p = palette()
    rng = random.Random(122)
    model = kit.Model("LeafLitter")
    for k in range(26):
        angle = rng.uniform(0, math.tau)
        at = _out(angle, 0.75 * math.sqrt(rng.random()), 0.02)
        tone = p[rng.choice(("litter_a", "litter_b", "leaf_dry"))]
        model.petal(at, rng.uniform(0, math.tau), rng.uniform(0.08, 0.15), rng.uniform(0.05, 0.08), 0.02, tone)
    model.finish()


def forest_mushrooms():
    """A small troop of brown-capped mushrooms."""
    p = palette()
    rng = random.Random(123)
    model = kit.Model("ForestMushrooms")
    for k in range(5):
        x, y = rng.uniform(-0.16, 0.16), rng.uniform(-0.16, 0.16)
        tall = rng.uniform(0.07, 0.15)
        model.cylinder((x, y, 0), (x, y, tall), 0.018, 0.012, p["mushroom"], segments=5)
        model.sphere((x, y, tall), rng.uniform(0.035, 0.055), p["mushroom_cap"], scale=(1.0, 1.0, 0.55), segments=6, rings=3)
    model.finish()


def fallen_twigs():
    """A scatter of dead twigs."""
    p = palette()
    rng = random.Random(124)
    model = kit.Model("FallenTwigs")
    for k in range(6):
        at = (rng.uniform(-0.4, 0.4), rng.uniform(-0.4, 0.4), 0.025)
        angle = rng.uniform(0, math.tau)
        reach = rng.uniform(0.2, 0.42)
        model.cylinder(at, (at[0] + math.cos(angle) * reach, at[1] + math.sin(angle) * reach, 0.015), 0.018, 0.007, p["dead_wood" if k % 2 else "dark_bark"], segments=4)
    model.finish()


# ---- the camp


def _stones_round(model, p, rng, radius, count, size):
    for k in range(count):
        angle = math.tau * k / count + rng.uniform(-0.09, 0.09)
        model.rock(_out(angle, radius, size * 0.45), size * rng.uniform(0.82, 1.15), p[rng.choice(("stone_mid", "stone_dark", "rock_dark"))], rng, scale=(1.0, 0.85, 0.68))


def campfire():
    """A campfire left to burn down: a ring of stones, a bed of ash, charred logs fallen in
    on each other and embers still alive under them. About 1.3 m across."""
    p = palette()
    rng = random.Random(131)
    model = kit.Model("Campfire")
    _stones_round(model, p, rng, 0.6, 11, 0.13)
    model.lathe([(0.56, 0.0), (0.48, 0.05), (0.2, 0.085), (0.0, 0.09)], p["ash_grey"], segments=12)
    for k in range(7):
        at = _out(rng.uniform(0, math.tau), rng.uniform(0.05, 0.3), 0.1)
        model.rock(at, rng.uniform(0.035, 0.07), p["ember"], rng, scale=(1.0, 1.0, 0.6))
    for angle, lift, burnt in ((0.3, 0.32, "char"), (2.2, 0.28, "char"), (4.3, 0.25, "dark_bark")):
        far = _out(angle, 0.52, 0.09)
        model.cylinder(far, _out(angle + math.pi, 0.1, lift), 0.06, 0.035, p[burnt], segments=6)
    # A log that rolled out and never caught.
    model.cylinder((0.62, -0.42, 0.08), (0.28, -0.74, 0.07), 0.055, 0.05, p["dark_bark"], segments=6)
    model.finish()


def _guy(model, p, a, b):
    model.cylinder(a, b, 0.008, 0.008, p["rope"], segments=4, caps=False)


def camp_tent():
    """A canvas ridge tent that's been standing a long time, about 2 m long and 1.5 m tall:
    faded, patched, and sagging along the ridge."""
    p = palette()
    rng = random.Random(132)
    model = kit.Model("CampTent")
    half = 1.15
    wide = 1.05
    top = 1.45
    sag = 0.1
    # Front and back poles, the ridge between them.
    model.cylinder((0, -half, 0), (0, -half, top + 0.1), 0.035, 0.03, p["wood_wet"], segments=5)
    model.cylinder((0, half, 0), (0, half, top + 0.1), 0.035, 0.03, p["wood_wet"], segments=5)
    model.cylinder((0, -half, top + 0.03), (0, 0, top - sag + 0.03), 0.022, 0.022, p["wood_wet"], segments=4)
    model.cylinder((0, 0, top - sag + 0.03), (0, half, top + 0.03), 0.022, 0.022, p["wood_wet"], segments=4)
    for side in (-1, 1):
        for a, b, z_a, z_b in ((-half, 0.0, top, top - sag), (0.0, half, top - sag, top)):
            tone = p["canvas"] if side < 0 else p["canvas_dark"]
            model.slab([(0, a, z_a), (0, b, z_b), (side * wide, b, 0.03), (side * wide, a, 0.03)], 0.012, tone)
    # Patches, on the slope.
    for side, y, t, w in ((-1, 0.45, 0.45, 0.28), (1, -0.5, 0.55, 0.22), (-1, -0.6, 0.72, 0.17)):
        x0, x1 = side * wide * (t - w * 0.5), side * wide * (t + w * 0.5)
        z0, z1 = (top - sag * 0.5) * (1 - t + w * 0.5) + 0.03, (top - sag * 0.5) * (1 - t - w * 0.5) + 0.03
        model.slab([(x0, y - w, z0 + 0.018), (x0, y + w, z0 + 0.018), (x1, y + w, z1 + 0.018), (x1, y - w, z1 + 0.018)], 0.008, p["canvas_patch"])
    # The back's closed; the front's flaps are tied open.
    model.slab([(-0.02, half, top), (0.02, half, top), (wide, half, 0.03), (-wide, half, 0.03)], 0.012, p["canvas_dark"])
    for side in (-1, 1):
        model.slab([(0, -half, top), (side * 0.2, -half - 0.02, top * 0.72), (side * wide, -half, 0.03), (side * 0.62, -half - 0.02, 0.03)], 0.012, p["canvas"])
    for side in (-1, 1):
        for y in (-0.8, 0.8):
            model.cylinder((side * (wide + 0.08), y, 0.2), (side * (wide + 0.1), y, 0.0), 0.016, 0.01, p["wood_wet"], segments=4)
    _guy(model, p, (0, -half, top + 0.06), (0, -half - 0.75, 0.0))
    _guy(model, p, (0, half, top + 0.06), (0, half + 0.75, 0.0))
    model.rock((-wide * 0.86, 0.2, 0.06), 0.14, p["moss"], rng, scale=(1.4, 1.0, 0.25))
    model.finish()
    kit.collision_box("CampTent", (0, 0, 0.55), (1.7, 2.3, 1.1))


def camp_tent_torn():
    """A tent that's come down: one pole still standing, the other snapped, its canvas
    slumped and ripped, weathering into the ground."""
    p = palette()
    rng = random.Random(133)
    model = kit.Model("CampTentTorn")
    half = 1.15
    wide = 1.1
    model.cylinder((0, half, 0), (0.06, half, 1.32), 0.035, 0.03, p["wood_wet"], segments=5)
    model.cylinder((0, -half, 0), (0.02, -half, 0.42), 0.035, 0.035, p["wood_wet"], segments=5)
    model.cylinder((0.02, -half, 0.4), (0.62, -half - 0.72, 0.03), 0.03, 0.026, p["wood_wet"], segments=5)
    model.cylinder((0.06, half, 1.28), (-0.04, -half * 0.7, 0.34), 0.022, 0.02, p["wood_wet"], segments=4)
    # The canvas hangs from the one pole down to the ground in uneven strips.
    strips = 6
    for k in range(strips):
        y0 = -half + 2.3 * k / strips
        y1 = -half + 2.3 * (k + 1) / strips
        z0 = 0.38 + 0.95 * max(0.0, (y0 + half) / 2.3) ** 1.5
        z1 = 0.38 + 0.95 * max(0.0, (y1 + half) / 2.3) ** 1.5
        for side in (-1, 1):
            if side > 0 and k == 2:
                continue  # The rip.
            reach = wide * rng.uniform(0.8, 1.08)
            tone = p["canvas_dark"] if (k + side) % 3 else p["canvas"]
            model.slab([(0.02, y0, z0), (0.02, y1, z1), (side * reach, y1, 0.03), (side * reach * 0.94, y0, 0.03)], 0.012, tone)
    model.rock((0.75, 0.4, 0.06), 0.2, p["moss"], rng, scale=(1.4, 1.0, 0.22))
    model.rock((-0.7, -0.6, 0.06), 0.24, p["litter_a"], rng, scale=(1.4, 1.0, 0.16))
    model.finish()
    kit.collision_box("CampTentTorn", (0, 0.1, 0.32), (1.7, 2.3, 0.64))


def log_seat():
    """A split log laid by the fire to sit on, about 1.7 m, worn on top."""
    p = palette()
    rng = random.Random(134)
    model = kit.Model("LogSeat")
    model.cylinder((-0.85, 0, 0.21), (0.85, 0.03, 0.2), 0.21, 0.19, p["dark_bark"], segments=8)
    model.box((0, 0.015, 0.385), (1.66, 0.26, 0.05), p["wood_drift"])
    for x in (-0.55, 0.55):
        model.box((x, 0.0, 0.06), (0.16, 0.62, 0.12), p["wood_wet"])
    model.rock((-0.7, -0.12, 0.25), 0.1, p["moss"], rng, scale=(1.0, 1.0, 0.5))
    model.finish()
    kit.collision_box("LogSeat", (0, 0, 0.21), (1.7, 0.42, 0.42))


def cook_tripod():
    """Three poles lashed over the fire, with a blackened pot on a chain; about 1.5 m."""
    p = palette()
    model = kit.Model("CookTripod")
    top = (0, 0, 1.42)
    for k in range(3):
        angle = math.tau * k / 3 + 0.4
        model.cylinder(_out(angle, 0.82, 0.0), _out(angle + math.pi, 0.07, 1.54), 0.024, 0.018, p["wood_wet"], segments=5)
    model.cylinder((0, 0, 1.4), (0, 0, 1.47), 0.05, 0.05, p["rope"], segments=7)
    model.cylinder(top, (0, 0, 0.74), 0.007, 0.007, p["iron"], segments=4)
    model.lathe([(0.0, 0.46), (0.11, 0.47), (0.17, 0.55), (0.17, 0.66), (0.13, 0.74), (0.145, 0.76)], p["iron"], segments=11)
    model.finish()


def camp_crates():
    """Crates left behind: two stacked and one stove in, the boards grey."""
    p = palette()
    rng = random.Random(136)
    model = kit.Model("CampCrates")

    def crate(x, y, z, size, turn, tone):
        model.box((x, y, z + size * 0.5), (size, size, size), p[tone], rotation_z=turn)
        for lift in (0.08, 0.92):
            model.box((x, y, z + size * lift), (size + 0.025, size + 0.025, 0.05), p["plank_old"], rotation_z=turn)

    crate(-0.15, 0.0, 0.0, 0.62, 0.15, "plank")
    crate(-0.1, 0.03, 0.62, 0.46, -0.3, "plank_old")
    # The broken one: walls leaning open, nothing inside.
    x = 0.68
    y = -0.25
    model.box((x, y, 0.03), (0.56, 0.56, 0.05), p["plank_old"], rotation_z=0.4)
    for k in range(4):
        angle = 0.4 + k * math.pi / 2
        lean = rng.uniform(0.0, 0.2)
        cx, cy = x + math.cos(angle) * (0.28 + lean * 0.5), y + math.sin(angle) * (0.28 + lean * 0.5)
        if k == 1:
            model.box((cx + 0.2, cy + 0.2, 0.03), (0.54, 0.42, 0.04), p["plank_old"], rotation_z=angle + 1.57)
            continue
        model.box((cx, cy, 0.04 + (0.36 - lean * 0.4) * 0.5), (0.04, 0.54, 0.36 - lean * 0.4), p["plank"], rotation_z=angle)
    model.finish()
    kit.collision_box("CampCrates", (-0.13, 0.0, 0.54), (0.7, 0.7, 1.08))


def camp_barrel():
    """An old barrel, staves opening at the top, lid gone. About 0.9 m."""
    p = palette()
    model = kit.Model("CampBarrel")
    model.lathe([(0.0, 0.03), (0.24, 0.0), (0.31, 0.2), (0.33, 0.45), (0.31, 0.72), (0.25, 0.92), (0.21, 0.92), (0.26, 0.5), (0.0, 0.42)], p["plank_old"], segments=12)
    for z, r in ((0.13, 0.297), (0.74, 0.31)):
        model.cylinder((0, 0, z - 0.03), (0, 0, z + 0.03), r, r, p["iron"], segments=12, caps=False)
    model.finish()
    kit.collision_cylinder("CampBarrel", (0, 0, 0), (0, 0, 0.92), 0.33, segments=10)


def firewood_pile():
    """Split logs stacked between two stakes, about 1.6 m long and 0.9 m tall, half used."""
    p = palette()
    rng = random.Random(138)
    model = kit.Model("FirewoodPile")
    for x in (-0.82, 0.82):
        model.cylinder((x, 0, 0), (x, 0, 0.98), 0.035, 0.03, p["wood_wet"], segments=5)
    for row, count in enumerate((7, 6, 4, 2)):
        for k in range(count):
            x = -0.68 + (k + (0.5 if row % 2 else 0.0)) * 0.225
            z = 0.1 + row * 0.19
            r = rng.uniform(0.085, 0.105)
            model.cylinder((x, -0.32, z), (x + rng.uniform(-0.03, 0.03), 0.32, z), r, r, p["dark_bark" if rng.random() < 0.7 else "bark"], segments=6)
    model.finish()
    kit.collision_box("FirewoodPile", (0, 0, 0.42), (1.7, 0.66, 0.84))


def drying_rack():
    """A frame of poles for drying hides, about 2 m tall; one hide left on it, gone stiff, and
    a rag of another."""
    p = palette()
    model = kit.Model("DryingRack")
    for x in (-1.0, 1.0):
        model.cylinder((x, -0.28, 0), (x * 0.96, 0, 2.0), 0.035, 0.028, p["wood_wet"], segments=5)
        model.cylinder((x, 0.28, 0), (x * 0.96, 0, 2.0), 0.035, 0.028, p["wood_wet"], segments=5)
    model.cylinder((-1.08, 0, 1.92), (1.08, 0, 1.92), 0.028, 0.028, p["wood_wet"], segments=5)
    model.cylinder((-1.0, 0, 0.82), (0.98, 0, 0.74), 0.024, 0.02, p["wood_wet"], segments=5)
    model.slab([(-0.72, 0.0, 1.88), (0.06, 0.0, 1.88), (0.12, 0.03, 0.86), (-0.64, 0.03, 0.82)], 0.016, p["hide"])
    model.slab([(0.34, 0.0, 1.88), (0.62, 0.0, 1.88), (0.52, 0.02, 1.34), (0.38, 0.02, 1.2)], 0.012, p["canvas_dark"])
    model.finish()
    kit.collision_box("DryingRack", (0, 0, 0.9), (2.1, 0.52, 1.8))


def bedroll():
    """A bedroll left lying out, half unrolled, gone mouldy."""
    p = palette()
    rng = random.Random(140)
    model = kit.Model("Bedroll")
    model.cylinder((-0.35, -0.5, 0.11), (0.35, -0.52, 0.11), 0.11, 0.11, p["canvas_dark"], segments=8)
    model.slab([(-0.33, -0.4, 0.06), (0.33, -0.42, 0.06), (0.36, 0.72, 0.03), (-0.34, 0.74, 0.03)], 0.02, p["hide"])
    model.rock((0.14, 0.5, 0.06), 0.16, p["moss"], rng, scale=(1.3, 1.0, 0.16))
    model.finish()


BUILDERS = {fn.__name__: fn for fn in (
    forest_spruce_a, forest_spruce_b, young_fir, forest_hornbeam, forest_ash, dead_pine, fallen_trunk,
    forest_rock_a, forest_rock_b, forest_crag, bracken, leaf_litter, forest_mushrooms, fallen_twigs,
    campfire, camp_tent, camp_tent_torn, log_seat, cook_tripod, camp_crates, camp_barrel, firewood_pile, drying_rack, bedroll,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
