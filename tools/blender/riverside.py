"""The riverside family: R1's waterside assets share this palette and these
shapes, so stones, plants and wood belong together. Each asset is a small script
in tools/blender/assets/ that calls make(<slug>). Colours are sRGB, close to the
field's grass. The palette and every shape are placeholders until the author
says otherwise (docs/world/regions/R1/art.md).
"""
import math
import random

import kit


def palette():
    """The family's materials. Made anew per build: a clean scene drops them."""
    m = kit.material
    return {
        "stone_light": m("StoneLight", (0.58, 0.57, 0.52), roughness=0.95),
        "stone_mid": m("StoneMid", (0.47, 0.48, 0.46), roughness=0.95),
        "stone_dark": m("StoneDark", (0.37, 0.39, 0.39), roughness=0.95),
        "moss": m("Moss", (0.34, 0.45, 0.20), roughness=1.0),
        "leaf_deep": m("LeafDeep", (0.21, 0.37, 0.17), roughness=0.85),
        "leaf_mid": m("LeafMid", (0.30, 0.47, 0.20), roughness=0.85),
        "leaf_light": m("LeafLight", (0.43, 0.57, 0.25), roughness=0.85),
        "leaf_dry": m("LeafDry", (0.63, 0.60, 0.34), roughness=0.9),
        "pad": m("LilyPad", (0.17, 0.39, 0.21), roughness=0.5),
        "petal_white": m("PetalWhite", (0.95, 0.93, 0.86), roughness=0.7),
        "petal_pink": m("PetalPink", (0.90, 0.60, 0.70), roughness=0.7),
        "petal_violet": m("PetalViolet", (0.43, 0.35, 0.73), roughness=0.7),
        "petal_yellow": m("PetalYellow", (0.93, 0.73, 0.17), roughness=0.7),
        "cattail": m("CattailHead", (0.33, 0.21, 0.12), roughness=1.0),
        "wood_wet": m("WoodWet", (0.31, 0.25, 0.19), roughness=0.9),
        "wood_drift": m("WoodDrift", (0.63, 0.58, 0.49), roughness=0.95),
        "bark": m("Bark", (0.37, 0.31, 0.23), roughness=1.0),
    }


def _stone(name, seed, radius, squash, tone, moss=0.0, solid=False):
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    height = radius * squash
    model.rock((0, 0, height * 0.55), radius, p[tone], rng, scale=(1.0, rng.uniform(0.75, 0.95), squash), subdivisions=2 if radius > 0.5 else 1)
    if moss > 0.0:
        # Sunk into the stone, so only an uneven patch shows.
        model.rock((-radius * 0.12, radius * 0.1, height * 0.86), radius * moss * 1.25, p["moss"], rng, scale=(1.0, 0.85, 0.42), subdivisions=2 if radius > 0.5 else 1, roughness=0.14)
    model.finish()
    if solid:
        kit.collision_cylinder(name, (0, 0, 0), (0, 0, height * 1.25), radius * 0.85)


def river_stone_a():
    _stone("RiverStoneA", 11, 0.2, 0.62, "stone_mid")


def river_stone_b():
    _stone("RiverStoneB", 12, 0.14, 0.8, "stone_light")


def river_stone_c():
    _stone("RiverStoneC", 13, 0.3, 0.42, "stone_dark", moss=0.5)


def pebbles_patch():
    p = palette()
    rng = random.Random(14)
    model = kit.Model("PebblesPatch")
    for k in range(16):
        angle = rng.uniform(0, math.tau)
        at = rng.uniform(0.0, 0.48) ** 0.8
        radius = rng.uniform(0.025, 0.08)
        tone = p[rng.choice(["stone_light", "stone_mid", "stone_dark"])]
        model.rock((math.cos(angle) * at, math.sin(angle) * at, radius * 0.4), radius, tone, rng, scale=(1.0, 0.85, 0.6), subdivisions=0)
    model.finish()


def mossy_boulder_a():
    _stone("MossyBoulderA", 15, 0.62, 0.95, "stone_mid", moss=0.62, solid=True)


def mossy_boulder_b():
    p = palette()
    rng = random.Random(16)
    model = kit.Model("MossyBoulderB")
    model.rock((-0.25, 0, 0.55), 0.72, p["stone_dark"], rng, scale=(1.0, 0.85, 0.82), subdivisions=2)
    model.rock((0.55, -0.2, 0.28), 0.4, p["stone_mid"], rng, scale=(1.0, 0.9, 0.75), subdivisions=1)
    model.rock((-0.32, 0.08, 0.86), 0.56, p["moss"], rng, scale=(1.0, 0.85, 0.44), subdivisions=2, roughness=0.14)
    model.finish()
    kit.collision_cylinder("MossyBoulderB", (-0.1, 0, 0), (-0.1, 0, 1.05), 0.8)


def _lily(model, p, rng, centre, radius, flower=None):
    """A pad, and a bloom on it if `flower` names a petal colour."""
    x, y = centre
    model.pad((x, y, 0.012), radius, p["pad"], notch=rng.uniform(0, math.tau))
    if flower is None:
        return
    for ring, (count, length, lift, start) in enumerate(((8, 0.15, 0.035, 0.0), (7, 0.115, 0.06, 0.4), (5, 0.08, 0.075, 0.1))):
        for k in range(count):
            angle = start + math.tau * k / count
            model.petal((x, y, 0.035 + ring * 0.008), angle, length, length * 0.42, lift, p[flower])
    model.sphere((x, y, 0.055), 0.028, p["petal_yellow"], segments=6, rings=4)


def _lily_group(name, seed, spots):
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    for x, y, radius, flower in spots:
        _lily(model, p, rng, (x, y), radius, flower)
    model.finish()


def lily_pads():
    _lily_group("LilyPads", 21, [(0.0, 0.0, 0.2, None), (0.33, 0.12, 0.15, None), (-0.28, 0.2, 0.17, None), (-0.12, -0.32, 0.14, None), (0.28, -0.26, 0.12, None)])


def lily_white():
    _lily_group("LilyWhite", 22, [(0.0, 0.0, 0.22, "petal_white"), (0.36, 0.1, 0.15, None), (-0.3, -0.18, 0.16, None)])


def lily_pink():
    _lily_group("LilyPink", 23, [(0.0, 0.05, 0.2, "petal_pink"), (-0.34, 0.08, 0.14, None), (0.2, -0.3, 0.15, None), (0.34, 0.26, 0.1, None)])


def _blades(model, rng, count, spread, height, lean, width, mats):
    """A clump of leaves from one foot, the outer ones leaning further out."""
    for k in range(count):
        angle = rng.uniform(0, math.tau)
        out = rng.uniform(0.0, spread)
        base = (math.cos(angle) * out, math.sin(angle) * out, 0.0)
        tall = height * rng.uniform(0.65, 1.0)
        bend = lean * rng.uniform(0.5, 1.2) * (0.5 + out / max(spread, 0.001))
        model.blade(base, angle, tall, width * rng.uniform(0.8, 1.2), bend, rng.choice(mats))


def reeds_a():
    p = palette()
    rng = random.Random(31)
    model = kit.Model("ReedsA")
    _blades(model, rng, 30, 0.2, 1.48, 0.16, 0.046, [p["leaf_mid"], p["leaf_light"], p["leaf_deep"], p["leaf_dry"]])
    model.finish()


def reeds_b():
    p = palette()
    rng = random.Random(32)
    model = kit.Model("ReedsB")
    _blades(model, rng, 22, 0.15, 1.08, 0.2, 0.042, [p["leaf_deep"], p["leaf_mid"], p["leaf_light"]])
    model.finish()


def cattails():
    p = palette()
    rng = random.Random(33)
    model = kit.Model("Cattails")
    _blades(model, rng, 11, 0.18, 1.2, 0.26, 0.04, [p["leaf_deep"], p["leaf_mid"]])
    for k in range(4):
        angle = math.tau * k / 4 + rng.uniform(-0.5, 0.5)
        out = rng.uniform(0.03, 0.14)
        tall = rng.uniform(1.4, 1.72)
        x, y = math.cos(angle) * out, math.sin(angle) * out
        top = (x * 1.6, y * 1.6, tall)
        model.cylinder((x, y, 0), top, 0.011, 0.007, p["leaf_mid"], segments=4)
        head_low = (x * 1.5, y * 1.5, tall - 0.3)
        head_high = (x * 1.58, y * 1.58, tall - 0.05)
        model.cylinder(head_low, head_high, 0.03, 0.028, p["cattail"], segments=6)
    model.finish()


def sedge_a():
    p = palette()
    rng = random.Random(34)
    model = kit.Model("SedgeA")
    _blades(model, rng, 16, 0.12, 0.46, 0.32, 0.026, [p["leaf_mid"], p["leaf_light"], p["leaf_dry"]])
    model.finish()


def sedge_b():
    p = palette()
    rng = random.Random(35)
    model = kit.Model("SedgeB")
    _blades(model, rng, 20, 0.17, 0.62, 0.42, 0.028, [p["leaf_deep"], p["leaf_mid"], p["leaf_light"]])
    model.finish()


def waterside_fern():
    p = palette()
    rng = random.Random(36)
    model = kit.Model("WatersideFern")
    for k in range(8):
        angle = math.tau * k / 8 + rng.uniform(-0.2, 0.2)
        model.frond((0, 0, 0), angle, rng.uniform(0.42, 0.6), rng.choice([p["leaf_deep"], p["leaf_mid"]]))
    model.finish()


def blue_flag_iris():
    p = palette()
    rng = random.Random(37)
    model = kit.Model("BlueFlagIris")
    _blades(model, rng, 12, 0.1, 0.72, 0.06, 0.04, [p["leaf_deep"], p["leaf_mid"]])
    for k in range(3):
        angle = math.tau * k / 3 + rng.uniform(-0.3, 0.3)
        out = rng.uniform(0.07, 0.13)
        tall = rng.uniform(0.74, 0.9)
        x, y = math.cos(angle) * out, math.sin(angle) * out
        model.cylinder((x * 0.3, y * 0.3, 0), (x, y, tall), 0.008, 0.006, p["leaf_mid"], segments=4)
        for n in range(3):
            turn = math.tau * n / 3 + angle
            model.petal((x, y, tall), turn, 0.085, 0.05, -0.035, p["petal_violet"])
            model.petal((x, y, tall), turn + math.pi / 3, 0.055, 0.03, 0.06, p["petal_violet"])
        model.sphere((x, y, tall), 0.012, p["petal_yellow"], segments=5, rings=3)
    model.finish()


def marsh_marigold():
    p = palette()
    rng = random.Random(38)
    model = kit.Model("MarshMarigold")
    for k in range(9):
        angle = rng.uniform(0, math.tau)
        out = rng.uniform(0.04, 0.2)
        x, y = math.cos(angle) * out, math.sin(angle) * out
        z = rng.uniform(0.1, 0.2)
        model.cylinder((x * 0.3, y * 0.3, 0), (x, y, z), 0.006, 0.005, p["leaf_mid"], segments=4)
        model.pad((x, y, z), rng.uniform(0.06, 0.085), rng.choice([p["leaf_deep"], p["leaf_mid"]]), notch=angle, segments=7)
    for k in range(5):
        angle = rng.uniform(0, math.tau)
        out = rng.uniform(0.02, 0.17)
        x, y = math.cos(angle) * out, math.sin(angle) * out
        z = rng.uniform(0.22, 0.31)
        model.cylinder((x * 0.3, y * 0.3, 0), (x, y, z), 0.005, 0.004, p["leaf_light"], segments=4)
        for n in range(5):
            model.petal((x, y, z), math.tau * n / 5, 0.04, 0.03, 0.012, p["petal_yellow"])
    model.finish()


def driftwood_log():
    p = palette()
    rng = random.Random(41)
    model = kit.Model("DriftwoodLog")
    points = [(-0.92, -0.05, 0.13), (-0.45, 0.04, 0.15), (0.05, 0.0, 0.14), (0.5, 0.07, 0.12), (0.92, 0.0, 0.09)]
    radii = [0.13, 0.15, 0.14, 0.115, 0.075]
    for a, b, ra, rb in zip(points, points[1:], radii, radii[1:]):
        model.cylinder(a, b, ra, rb, p["wood_drift"], segments=7)
    model.cylinder((-0.3, 0.05, 0.2), (-0.1, 0.42, 0.36), 0.05, 0.015, p["wood_drift"], segments=5)
    model.cylinder((0.35, 0.03, 0.2), (0.58, -0.34, 0.33), 0.04, 0.012, p["wood_wet"], segments=5)
    model.rock((0.05, -0.05, 0.1), 0.2, p["moss"], rng, scale=(1.5, 0.6, 0.55))
    model.finish()
    kit.collision_box("DriftwoodLog", (0, 0, 0.14), (1.8, 0.3, 0.28))


def driftwood_branch():
    p = palette()
    model = kit.Model("DriftwoodBranch")
    points = [(-0.62, 0.0, 0.05), (-0.2, 0.08, 0.08), (0.2, -0.04, 0.09), (0.62, 0.05, 0.26)]
    radii = [0.05, 0.05, 0.04, 0.012]
    for a, b, ra, rb in zip(points, points[1:], radii, radii[1:]):
        model.cylinder(a, b, ra, rb, p["wood_drift"], segments=5)
    model.cylinder((-0.1, 0.05, 0.08), (0.1, 0.42, 0.22), 0.028, 0.008, p["wood_drift"], segments=4)
    model.cylinder((0.18, -0.04, 0.1), (0.42, -0.36, 0.05), 0.024, 0.008, p["wood_wet"], segments=4)
    model.finish()


def mossy_stump():
    p = palette()
    rng = random.Random(43)
    model = kit.Model("MossyStump")
    model.lathe([(0.34, 0.0), (0.26, 0.1), (0.24, 0.42), (0.21, 0.56)], p["bark"], segments=9)
    model.lathe([(0.21, 0.56), (0.15, 0.565), (0.0, 0.54)], p["wood_drift"], segments=9)
    for k in range(5):
        angle = math.tau * k / 5 + rng.uniform(-0.3, 0.3)
        model.cylinder((math.cos(angle) * 0.2, math.sin(angle) * 0.2, 0.1), (math.cos(angle) * 0.52, math.sin(angle) * 0.52, 0.015), 0.07, 0.02, p["bark"], segments=5)
    model.rock((-0.14, 0.1, 0.5), 0.2, p["moss"], rng, scale=(1.0, 0.8, 0.35))
    model.rock((0.16, -0.22, 0.14), 0.15, p["moss"], rng, scale=(1.0, 0.7, 0.5))
    for z, angle, size in ((0.36, 0.5, 0.08), (0.27, 1.0, 0.06), (0.42, 1.5, 0.05)):
        x, y = math.cos(angle) * 0.25, math.sin(angle) * 0.25
        model.sphere((x, y, z), size, p["leaf_dry"], scale=(1.0, 1.0, 0.3), segments=6, rings=3)
    model.finish()
    kit.collision_cylinder("MossyStump", (0, 0, 0), (0, 0, 0.56), 0.27)


def _strand(model, rng, start, length, mats):
    """A willow's hanging strand of leaves, swinging a little aside."""
    sx, sy, sz = start
    side = rng.uniform(0, math.tau)
    drift = rng.uniform(0.04, 0.16)
    points = [(sx + math.cos(side) * drift * t * t, sy + math.sin(side) * drift * t * t, sz - length * t) for t in (0.0, 0.34, 0.67, 1.0)]
    model.ribbon(points, side, [0.03, 0.055, 0.045, 0.0], rng.choice(mats))


def _foliage(model, rng, at, radius, leaves, strands, longest):
    """A soft mass of leaves: a few round lumps, strands hanging from all round."""
    for k in range(4):
        spin = rng.uniform(0, math.tau)
        out = radius * rng.uniform(0.15, 0.6)
        lump = (at[0] + math.cos(spin) * out, at[1] + math.sin(spin) * out, at[2] + radius * rng.uniform(-0.2, 0.3))
        model.rock(lump, radius * rng.uniform(0.42, 0.62), rng.choice(leaves), rng, scale=(1.0, 1.0, 0.72), roughness=0.16)
    for n in range(strands):
        spin = rng.uniform(0, math.tau)
        out = radius * rng.uniform(0.3, 1.0)
        start = (at[0] + math.cos(spin) * out, at[1] + math.sin(spin) * out, at[2] - radius * rng.uniform(0.05, 0.35))
        _strand(model, rng, start, rng.uniform(longest * 0.45, longest), leaves)


def willow_shrub():
    p = palette()
    rng = random.Random(44)
    model = kit.Model("WillowShrub")
    leaves = [p["leaf_mid"], p["leaf_light"], p["leaf_deep"]]
    for k in range(7):
        angle = math.tau * k / 7 + rng.uniform(-0.25, 0.25)
        out = rng.uniform(0.28, 0.55)
        top = (math.cos(angle) * out, math.sin(angle) * out, rng.uniform(1.05, 1.42))
        model.cylinder((0, 0, 0), top, 0.025, 0.008, p["bark"], segments=4)
        _foliage(model, rng, top, 0.3, leaves, 7, 0.95)
    model.finish()


def young_willow():
    p = palette()
    rng = random.Random(45)
    model = kit.Model("YoungWillow")
    leaves = [p["leaf_mid"], p["leaf_light"], p["leaf_deep"]]
    trunk = [(0.0, 0.0, 0.0), (0.05, 0.02, 0.9), (0.02, 0.06, 1.8), (-0.04, 0.03, 2.6)]
    radii = [0.17, 0.12, 0.09, 0.06]
    for a, b, ra, rb in zip(trunk, trunk[1:], radii, radii[1:]):
        model.cylinder(a, b, ra, rb, p["bark"], segments=7)
    for k in range(5):
        angle = rng.uniform(0, 0.3) + math.tau * k / 5
        model.cylinder((0, 0, 0.06), (math.cos(angle) * 0.42, math.sin(angle) * 0.42, 0.0), 0.11, 0.02, p["bark"], segments=4)
    model.sphere((-0.03, 0.03, 3.5), 0.72, p["leaf_deep"], scale=(1.35, 1.35, 0.75), segments=8, rings=5)
    for k in range(11):
        angle = math.tau * k / 11 + rng.uniform(-0.2, 0.2)
        reach = rng.uniform(0.7, 1.75)
        base = trunk[1 + k % 3]
        tip = (math.cos(angle) * reach, math.sin(angle) * reach, 4.05 - reach * rng.uniform(0.2, 0.55))
        elbow = (base[0] + (tip[0] - base[0]) * 0.55, base[1] + (tip[1] - base[1]) * 0.55, base[2] + (tip[2] - base[2]) * 0.75)
        model.cylinder(base, elbow, 0.05, 0.03, p["bark"], segments=5)
        model.cylinder(elbow, tip, 0.03, 0.01, p["bark"], segments=4)
        _foliage(model, rng, tip, rng.uniform(0.5, 0.72), leaves, 14, min(2.5, tip[2] - 0.5))
    model.finish()
    kit.collision_cylinder("YoungWillow", (0, 0, 0), (0, 0, 2.6), 0.17)


BUILDERS = {fn.__name__: fn for fn in (
    river_stone_a, river_stone_b, river_stone_c, pebbles_patch, mossy_boulder_a, mossy_boulder_b,
    lily_pads, lily_white, lily_pink, reeds_a, reeds_b, cattails, sedge_a, sedge_b, waterside_fern,
    blue_flag_iris, marsh_marigold, driftwood_log, driftwood_branch, mossy_stump, willow_shrub, young_willow,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
