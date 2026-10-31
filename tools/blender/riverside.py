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


def _wet_stone(name, seed, radius, tall):
    """A dark water-worn stone breaking the surface, with foam around its waist."""
    p = palette()
    p["foam"] = kit.material("Foam", (0.90, 0.94, 0.95), roughness=0.6)
    rng = random.Random(seed)
    model = kit.Model(name)
    model.rock((0, 0, radius * tall * 0.5), radius, p["stone_dark"], rng, scale=(1.0, rng.uniform(0.7, 0.9), tall), subdivisions=2, roughness=0.14)
    for k in range(9):
        angle = math.tau * k / 9 + rng.uniform(-0.15, 0.15)
        at = radius * rng.uniform(0.95, 1.15)
        size = radius * rng.uniform(0.16, 0.3)
        model.rock((math.cos(angle) * at, math.sin(angle) * at * 0.82, 0.03), size, p["foam"], rng, scale=(1.3, 1.0, 0.22), subdivisions=0)
    model.finish()


def rapid_stone_a():
    _wet_stone("RapidStoneA", 41, 0.62, 0.95)


def rapid_stone_b():
    _wet_stone("RapidStoneB", 42, 0.42, 0.7)


def gravel_bar():
    p = palette()
    p["gravel"] = kit.material("Gravel", (0.56, 0.53, 0.46), roughness=1.0)
    rng = random.Random(43)
    model = kit.Model("GravelBar")
    model.rock((0, 0, 0.05), 1.5, p["gravel"], rng, scale=(1.0, 0.68, 0.14), subdivisions=2, roughness=0.1)
    for k in range(22):
        angle = rng.uniform(0, math.tau)
        at = rng.uniform(0.1, 1.0) ** 0.7
        radius = rng.uniform(0.05, 0.15)
        tone = p[rng.choice(["stone_light", "stone_mid", "stone_dark"])]
        x, y = math.cos(angle) * at * 1.3, math.sin(angle) * at * 0.85
        model.rock((x, y, 0.2 * (1.0 - at * at) + radius * 0.2), radius, tone, rng, scale=(1.0, 0.85, 0.65), subdivisions=0)
    model.finish()


def spray_moss():
    p = palette()
    rng = random.Random(44)
    model = kit.Model("SprayMoss")
    for k in range(4):
        angle = math.tau * k / 4 + rng.uniform(-0.3, 0.3)
        at = 0.32 if k else 0.0
        model.rock((math.cos(angle) * at, math.sin(angle) * at, 0.05), rng.uniform(0.28, 0.42), p["moss" if k % 2 else "leaf_deep"], rng, scale=(1.1, 1.0, 0.42), subdivisions=1, roughness=0.18)
    for k in range(5):
        model.frond((rng.uniform(-0.3, 0.3), rng.uniform(-0.3, 0.3), 0.12), rng.uniform(0, math.tau), rng.uniform(0.35, 0.5), p["leaf_light"], leaflets=5)
    model.finish()


def _outcrop(name, seed, blocks):
    """Jagged bedrock showing through the ground: overlapping angular blocks, each
    (x, y, height of its middle, half width, half depth, half height)."""
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    for k, (x, y, z, wide, deep, tall) in enumerate(blocks):
        tone = p[("stone_dark", "stone_mid", "stone_dark", "stone_light")[k % 4]]
        model.rock((x, y, z), 1.0, tone, rng, scale=(wide, deep, tall), subdivisions=1, roughness=0.28)
        if k % 3 == 1:
            model.rock((x - wide * 0.2, y + deep * 0.2, z + tall * 0.72), 1.0, p["moss"], rng, scale=(wide * 0.55, deep * 0.5, tall * 0.22), subdivisions=1, roughness=0.14)
    model.finish()


def cliff_outcrop_a():
    _outcrop("CliffOutcropA", 45, [
        (-1.5, 0.3, 0.9, 1.7, 1.4, 1.5), (0.7, -0.3, 1.5, 1.5, 1.2, 2.1), (2.2, 0.6, 0.7, 1.2, 1.1, 1.1),
        (0.1, 1.2, 0.6, 1.5, 0.9, 0.9), (-0.5, -1.1, 0.4, 1.3, 0.8, 0.6),
    ])
    kit.collision_box("CliffOutcropA", (0.2, 0, 1.3), (5.2, 3.2, 2.6))


def cliff_outcrop_b():
    _outcrop("CliffOutcropB", 46, [
        (0.2, 0.0, 2.2, 1.05, 0.85, 3.1), (-1.0, 0.3, 1.2, 1.0, 0.9, 1.9), (1.1, -0.4, 0.8, 0.9, 0.8, 1.2),
        (-0.1, 0.9, 0.6, 1.0, 0.6, 0.8),
    ])
    kit.collision_cylinder("CliffOutcropB", (0, 0, 0), (0, 0, 4.6), 1.3)


def wind_snag():
    """A dead tree, bleached and bent away from the drop by the wind off it."""
    p = palette()
    rng = random.Random(47)
    model = kit.Model("WindSnag")
    trunk = [(0, 0, 0), (0.08, 0, 1.3), (0.34, 0.04, 2.6), (0.82, 0.02, 3.7), (1.45, -0.05, 4.5)]
    radii = [0.24, 0.19, 0.14, 0.09, 0.04]
    for k in range(4):
        model.cylinder(trunk[k], trunk[k + 1], radii[k], radii[k + 1], p["wood_drift"], segments=7)
    for k in range(5):
        angle = math.tau * k / 5
        model.cylinder((0, 0, 0.12), (math.cos(angle) * 0.62, math.sin(angle) * 0.62, -0.02), 0.13, 0.03, p["wood_wet"], segments=5)
    for start, tip in [
        (trunk[1], (0.95, 0.7, 2.0)), (trunk[2], (1.25, -0.65, 3.05)), (trunk[2], (-0.1, 0.72, 3.15)),
        (trunk[3], (1.5, 0.55, 3.95)), (trunk[3], (1.25, -0.5, 4.35)),
    ]:
        elbow = ((start[0] + tip[0]) * 0.5 + rng.uniform(-0.1, 0.1), (start[1] + tip[1]) * 0.5, (start[2] + tip[2]) * 0.5 + 0.12)
        model.cylinder(start, elbow, 0.055, 0.035, p["wood_drift"], segments=5)
        model.cylinder(elbow, tip, 0.035, 0.008, p["wood_drift"], segments=4)
    model.finish()
    kit.collision_cylinder("WindSnag", (0, 0, 0), (0.3, 0, 2.7), 0.2)


def _alder_crown(model, rng, p, top, wide):
    """Rounded masses of leaves, darker below and lighter on top."""
    for k in range(9):
        spin = math.tau * k / 9 + rng.uniform(-0.25, 0.25)
        out = wide * rng.uniform(0.35, 0.8)
        z = top + rng.uniform(-1.5, 0.4)
        tone = p["leaf_deep"] if z < top - 0.7 else (p["leaf_mid"] if rng.random() < 0.65 else p["leaf_light"])
        model.rock((math.cos(spin) * out, math.sin(spin) * out, z), wide * rng.uniform(0.42, 0.58), tone, rng, scale=(1.0, 1.0, 0.78), roughness=0.14)
    model.rock((0, 0, top + 0.7), wide * 0.62, p["leaf_mid"], rng, scale=(1.0, 1.0, 0.8), roughness=0.14)


def lake_alder():
    """A full-grown alder of the lake's shores, about 6.5 m tall."""
    p = palette()
    rng = random.Random(48)
    model = kit.Model("LakeAlder")
    trunk = [(0, 0, 0), (0.05, 0.03, 1.4), (-0.03, 0.08, 2.9), (0.04, 0.03, 4.3)]
    radii = [0.26, 0.2, 0.15, 0.09]
    for k in range(3):
        model.cylinder(trunk[k], trunk[k + 1], radii[k], radii[k + 1], p["bark"], segments=8)
    for k in range(6):
        angle = math.tau * k / 6 + rng.uniform(-0.2, 0.2)
        model.cylinder((0, 0, 0.14), (math.cos(angle) * 0.72, math.sin(angle) * 0.72, -0.02), 0.15, 0.03, p["bark"], segments=5)
    for k in range(6):
        angle = math.tau * k / 6 + rng.uniform(-0.3, 0.3)
        base = trunk[1 + k % 3]
        tip = (math.cos(angle) * 1.0, math.sin(angle) * 1.0, max(base[2] + 1.0, 3.9))
        model.cylinder(base, tip, 0.07, 0.025, p["bark"], segments=5)
    _alder_crown(model, rng, p, 5.1, 2.1)
    model.finish()
    kit.collision_cylinder("LakeAlder", (0, 0, 0), (0, 0, 3.0), 0.27)


def fallen_alder():
    """An alder fallen from the bank: its roots in the air, its crown in the lake."""
    p = palette()
    rng = random.Random(49)
    model = kit.Model("FallenAlder")
    points = [(-2.6, 0.0, 0.3), (-1.2, 0.05, 0.27), (0.4, -0.04, 0.2), (1.8, 0.05, 0.13), (3.0, 0.0, 0.08)]
    radii = [0.27, 0.23, 0.18, 0.12, 0.05]
    for k in range(4):
        model.cylinder(points[k], points[k + 1], radii[k], radii[k + 1], p["wood_wet"], segments=8)
    # The roots torn out of the bank.
    for k in range(9):
        angle = math.tau * k / 9 + rng.uniform(-0.2, 0.2)
        tip = (-2.85, math.cos(angle) * rng.uniform(0.75, 1.1), 0.5 + math.sin(angle) * rng.uniform(0.3, 0.75))
        model.cylinder((-2.6, 0, 0.32), (tip[0], tip[1], max(tip[2], 0.02)), 0.09, 0.015, p["bark"], segments=4)
    model.rock((-2.72, 0, 0.42), 0.48, p["bark"], rng, scale=(0.35, 1.0, 0.9), subdivisions=1)
    # What's left of the crown.
    for start, tip in [
        (points[2], (1.3, 0.95, 1.05)), (points[2], (1.15, -0.85, 0.85)), (points[3], (2.8, 0.7, 0.9)),
        (points[3], (2.65, -0.65, 0.65)), (points[1], (-0.35, 0.75, 0.95)),
    ]:
        model.cylinder(start, tip, 0.05, 0.012, p["wood_drift"], segments=5)
    model.rock((-0.7, 0.05, 0.47), 0.32, p["moss"], rng, scale=(1.8, 0.65, 0.35), subdivisions=1)
    model.finish()
    kit.collision_box("FallenAlder", (0.0, 0, 0.26), (5.4, 0.5, 0.52))


def shore_slab():
    """Flat rock shelving into the water at the lake's edge, about 3 m across."""
    p = palette()
    rng = random.Random(50)
    model = kit.Model("ShoreSlab")
    for x, y, z, wide, deep, tall, tone in [
        (-0.3, 0.1, 0.08, 1.35, 1.0, 0.2, "stone_mid"), (0.65, -0.3, 0.07, 0.9, 0.75, 0.16, "stone_light"),
        (-0.8, -0.55, 0.05, 0.7, 0.55, 0.12, "stone_dark"), (0.2, 0.65, 0.2, 0.75, 0.42, 0.12, "stone_light"),
    ]:
        model.rock((x, y, z), 1.0, p[tone], rng, scale=(wide, deep, tall), subdivisions=1, roughness=0.12)
    model.rock((-0.65, 0.5, 0.24), 0.42, p["moss"], rng, scale=(1.25, 0.8, 0.22), subdivisions=1, roughness=0.14)
    model.finish()
    kit.collision_box("ShoreSlab", (0, 0, 0.1), (2.8, 2.0, 0.24))


# The bridge, in metres: along Y, its deck's top at this height at each end and this
# much higher in the middle.
BRIDGE_LENGTH = 21.0
BRIDGE_WIDTH = 2.2
BRIDGE_END = 6.0
BRIDGE_RISE = 2.0
FENCE_HEIGHT = 0.75


def _deck_height(y):
    return BRIDGE_END + BRIDGE_RISE * (1.0 - (2.0 * y / BRIDGE_LENGTH) ** 2)


def wooden_bridge():
    """An old curved bridge of logs: small fences with some rails gone, a few deck logs
    missing, and pairs of columns standing in the water. Its origin is below the river
    bed, so placing it takes its columns down there."""
    p = palette()
    rng = random.Random(51)
    model = kit.Model("WoodenBridge")
    half = BRIDGE_LENGTH / 2
    # The deck: logs across, some darker, a few gone, never two together or near the ends.
    y = -half
    gone_last = False
    while y <= half:
        missing = not gone_last and abs(y) < half - 1.5 and rng.random() < 0.07
        gone_last = missing
        if not missing:
            z = _deck_height(y) - 0.08
            reach = BRIDGE_WIDTH / 2 + rng.uniform(-0.1, 0.12)
            tone = p["wood_drift"] if rng.random() < 0.3 else p["bark"]
            model.cylinder((-reach, y, z + rng.uniform(-0.012, 0.012)), (reach, y + rng.uniform(-0.03, 0.03), z), 0.095, rng.uniform(0.08, 0.095), tone, segments=6)
        y += 0.235
    # Two beams under it, along the curve.
    steps = 14
    for side in (-0.72, 0.72):
        for k in range(steps):
            a = -half + BRIDGE_LENGTH * k / steps
            b = -half + BRIDGE_LENGTH * (k + 1) / steps
            model.cylinder((side, a, _deck_height(a) - 0.27), (side, b, _deck_height(b) - 0.27), 0.12, 0.12, p["wood_wet"], segments=6)
    # The columns: pairs leaning in a little, each with a beam across and some braced.
    for at in (-6.6, -2.2, 2.2, 6.6):
        top = _deck_height(at) - 0.36
        for side in (-0.82, 0.82):
            lean = rng.uniform(-0.05, 0.05)
            model.cylinder((side * 1.14, at + lean, 0.0), (side, at, top), 0.17, 0.12, p["wood_wet"], segments=7)
        model.cylinder((-1.05, at, top - 0.05), (1.05, at, top + 0.02), 0.09, 0.09, p["bark"], segments=6)
        if at < 3.0:
            model.cylinder((-0.92, at, top - 2.6), (0.88, at, top - 0.25), 0.05, 0.05, p["wood_drift"], segments=5)
        # Weed at the waterline, about where the river stands on it.
        model.rock((0.86, at, 3.95), 0.2, p["moss"], rng, scale=(1.0, 1.0, 0.45), roughness=0.14)
    # The fences: a post every so often, and two rails with some lengths gone.
    posts = 9
    for side in (-1.04, 1.04):
        heights = []
        for k in range(posts + 1):
            at = -half + 0.2 + (BRIDGE_LENGTH - 0.4) * k / posts
            deck = _deck_height(at)
            tall = FENCE_HEIGHT * (0.55 if rng.random() < 0.1 else rng.uniform(0.93, 1.04))
            model.cylinder((side, at, deck - 0.3), (side, at + rng.uniform(-0.02, 0.02), deck + tall), 0.05, 0.042, p["bark"], segments=6)
            heights.append((at, deck))
        for (a, deck_a), (b, deck_b) in zip(heights, heights[1:]):
            if rng.random() > 0.14:
                model.cylinder((side, a, deck_a + FENCE_HEIGHT * 0.92), (side, b, deck_b + FENCE_HEIGHT * 0.92), 0.034, 0.034, p["wood_drift"], segments=5)
            if rng.random() > 0.22:
                model.cylinder((side, a, deck_a + FENCE_HEIGHT * 0.5), (side, b, deck_b + FENCE_HEIGHT * 0.5), 0.026, 0.026, p["wood_drift"], segments=4)
    for at in (-7.2, 1.3, 8.1):
        model.rock((rng.choice((-0.85, 0.85)), at, _deck_height(at) + 0.01), 0.16, p["moss"], rng, scale=(1.6, 1.0, 0.3), roughness=0.14)
    model.finish()
    # What's walked on, and what keeps the walker on it. Gaps in the deck are too
    # small to fall through, so one surface covers them.
    pieces = 14
    for k in range(pieces):
        # Overlapping a little, so there's no seam to slip through.
        a = -half + BRIDGE_LENGTH * k / pieces - 0.03
        b = -half + BRIDGE_LENGTH * (k + 1) / pieces + 0.03
        start = (0.0, a, _deck_height(a) - 0.3)
        end = (0.0, b, _deck_height(b) - 0.3)
        kit.collision_slab(f"WoodenBridgeDeck{k}", start, end, BRIDGE_WIDTH, 0.32)
        for n, side in enumerate((-1.04, 1.04)):
            kit.collision_slab(f"WoodenBridgeFence{k}x{n}", (side, a, _deck_height(a)), (side, b, _deck_height(b)), 0.1, FENCE_HEIGHT)
    for n, at in enumerate((-6.6, -2.2, 2.2, 6.6)):
        for m, side in enumerate((-0.9, 0.9)):
            kit.collision_cylinder(f"WoodenBridgeColumn{n}x{m}", (side, at, 0.0), (side, at, _deck_height(at) - 0.3), 0.15, segments=6)


def _lantern_parts():
    m = kit.material
    return {
        "iron": m("LanternIron", (0.16, 0.15, 0.14), roughness=0.7, metallic=0.4),
        "glass": m("LanternGlass", (0.95, 0.8, 0.5), roughness=0.2, alpha=0.35),
        "candle": m("LanternCandle", (0.9, 0.82, 0.6), roughness=0.8),
    }


def _lantern_head(model, parts, x, y, z, size=0.13):
    """A small iron cage with glass, a candle and a pointed roof; `z` is its floor."""
    tall = size * 2.2
    model.box((x, y, z + 0.012), (size * 2.1, size * 2.1, 0.025), parts["iron"])
    model.box((x, y, z + tall / 2), (size * 1.7, size * 1.7, tall), parts["glass"])
    for sx in (-1, 1):
        for sy in (-1, 1):
            model.cylinder((x + sx * size, y + sy * size, z), (x + sx * size, y + sy * size, z + tall), 0.012, 0.012, parts["iron"], segments=4)
    model.cylinder((x, y, z + 0.02), (x, y, z + 0.14), 0.03, 0.028, parts["candle"], segments=6)
    model.cylinder((x, y, z + tall), (x, y, z + tall + size * 0.9), size * 1.5, 0.015, parts["iron"], segments=4)
    model.sphere((x, y, z + tall + size * 1.0), 0.022, parts["iron"], segments=6, rings=4)


def lantern_post():
    """A lantern on top of a plain wooden post, about 2.2 m."""
    p = palette()
    parts = _lantern_parts()
    rng = random.Random(52)
    model = kit.Model("LanternPost")
    model.cylinder((0, 0, 0), (0, 0, 1.72), 0.075, 0.06, p["bark"], segments=6)
    model.box((0, 0, 1.73), (0.32, 0.32, 0.04), p["wood_wet"])
    for k in range(4):
        angle = math.tau * k / 4 + 0.4
        model.rock((math.cos(angle) * 0.16, math.sin(angle) * 0.16, 0.05), 0.09, p["stone_mid"], rng, scale=(1.0, 0.9, 0.7))
    _lantern_head(model, parts, 0, 0, 1.75)
    model.finish()
    kit.collision_cylinder("LanternPost", (0, 0, 0), (0, 0, 2.0), 0.1, segments=6)


def lantern_hook():
    """A lantern hanging from a shepherd's crook of bent wood, about 2.4 m."""
    p = palette()
    parts = _lantern_parts()
    model = kit.Model("LanternHook")
    bend = [(0, 0, 0), (0.0, 0, 1.3), (0.01, 0, 1.95), (0.08, 0, 2.22), (0.26, 0, 2.36), (0.44, 0, 2.3), (0.5, 0, 2.14)]
    radii = [0.06, 0.05, 0.042, 0.036, 0.03, 0.026, 0.02]
    for k in range(len(bend) - 1):
        model.cylinder(bend[k], bend[k + 1], radii[k], radii[k + 1], p["bark"], segments=6)
    model.cylinder((0.5, 0, 2.14), (0.5, 0, 1.95), 0.008, 0.008, parts["iron"], segments=4)
    _lantern_head(model, parts, 0.5, 0, 1.6, size=0.11)
    model.finish()
    kit.collision_cylinder("LanternHook", (0, 0, 0), (0, 0, 2.2), 0.08, segments=6)


def lantern_stone():
    """A low stone lantern with a window on each side and a mossy cap, about 0.8 m."""
    p = palette()
    parts = _lantern_parts()
    rng = random.Random(53)
    model = kit.Model("LanternStone")
    model.rock((0, 0, 0.1), 0.26, p["stone_dark"], rng, scale=(1.0, 1.0, 0.6))
    model.cylinder((0, 0, 0.12), (0, 0, 0.4), 0.11, 0.09, p["stone_mid"], segments=6)
    model.box((0, 0, 0.42), (0.34, 0.34, 0.05), p["stone_light"])
    for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        model.box((sx * 0.13, sy * 0.13, 0.54), (0.06, 0.06, 0.2), p["stone_mid"])
    model.box((0, 0, 0.54), (0.2, 0.2, 0.18), parts["glass"])
    model.cylinder((0, 0, 0.445), (0, 0, 0.56), 0.03, 0.028, parts["candle"], segments=6)
    model.cylinder((0, 0, 0.64), (0, 0, 0.8), 0.27, 0.03, p["stone_light"], segments=6)
    model.rock((-0.06, 0.05, 0.66), 0.13, p["moss"], rng, scale=(1.2, 1.0, 0.4), roughness=0.14)
    model.finish()
    kit.collision_cylinder("LanternStone", (0, 0, 0), (0, 0, 0.8), 0.2, segments=6)


BUILDERS = {fn.__name__: fn for fn in (
    river_stone_a, river_stone_b, river_stone_c, pebbles_patch, mossy_boulder_a, mossy_boulder_b,
    lily_pads, lily_white, lily_pink, reeds_a, reeds_b, cattails, sedge_a, sedge_b, waterside_fern,
    blue_flag_iris, marsh_marigold, driftwood_log, driftwood_branch, mossy_stump, willow_shrub, young_willow,
    rapid_stone_a, rapid_stone_b, gravel_bar, spray_moss, cliff_outcrop_a, cliff_outcrop_b, wind_snag,
    lake_alder, fallen_alder, shore_slab, wooden_bridge, lantern_post, lantern_hook, lantern_stone,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
