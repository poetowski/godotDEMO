"""The woodland family: full-grown trees of several kinds, from an apple tree by the farm
to oaks and pines that stand out from far away. They share the riverside family's bark
and greens, so they sit with R1's waterside. Each asset is a small script in
tools/blender/assets/ that calls make(<slug>). Colours are sRGB. The kinds and shapes are
placeholders until the author says otherwise (docs/world/regions/R1/art.md).
"""
import math
import random

import kit
import riverside


def palette():
    """The riverside palette and the trees' own materials."""
    p = riverside.palette()
    m = kit.material
    p.update({
        "oak_dark": m("OakDark", (0.17, 0.32, 0.14), roughness=0.85),
        "oak_mid": m("OakMid", (0.24, 0.41, 0.17), roughness=0.85),
        "oak_light": m("OakLight", (0.33, 0.49, 0.20), roughness=0.85),
        "beech_dark": m("BeechDark", (0.25, 0.42, 0.15), roughness=0.85),
        "beech_mid": m("BeechMid", (0.34, 0.51, 0.18), roughness=0.85),
        "beech_light": m("BeechLight", (0.46, 0.60, 0.24), roughness=0.85),
        "pine_dark": m("PineDark", (0.11, 0.25, 0.17), roughness=0.9),
        "pine_mid": m("PineMid", (0.15, 0.31, 0.19), roughness=0.9),
        "pine_light": m("PineLight", (0.21, 0.38, 0.21), roughness=0.9),
        "birch_leaf": m("BirchLeaf", (0.52, 0.64, 0.27), roughness=0.85),
        "birch_leaf_dark": m("BirchLeafDark", (0.39, 0.54, 0.22), roughness=0.85),
        "birch_bark": m("BirchBark", (0.87, 0.86, 0.80), roughness=0.9),
        "birch_mark": m("BirchMark", (0.17, 0.16, 0.15), roughness=0.9),
        "maple_dark": m("MapleDark", (0.33, 0.43, 0.14), roughness=0.85),
        "maple_mid": m("MapleMid", (0.45, 0.53, 0.17), roughness=0.85),
        "maple_light": m("MapleLight", (0.56, 0.59, 0.21), roughness=0.85),
        "grey_bark": m("GreyBark", (0.45, 0.44, 0.40), roughness=0.95),
        "pine_bark": m("PineBark", (0.40, 0.27, 0.18), roughness=1.0),
        "apple_red": m("AppleRed", (0.74, 0.16, 0.12), roughness=0.5),
    })
    return p


def _limb(model, points, radii, mat, segments=6):
    """A trunk or a branch: tapering lengths through its points."""
    for a, b, ra, rb in zip(points, points[1:], radii, radii[1:]):
        model.cylinder(a, b, ra, rb, mat, segments=segments)


def _roots(model, rng, radius, reach, count, mat):
    """Roots flaring out from a trunk's foot, sinking into the ground."""
    for k in range(count):
        angle = math.tau * k / count + rng.uniform(-0.25, 0.25)
        far = reach * rng.uniform(0.75, 1.15)
        tip = (math.cos(angle) * far, math.sin(angle) * far, radius * 0.14)
        model.cylinder((math.cos(angle) * radius * 0.5, math.sin(angle) * radius * 0.5, radius * 0.75), tip, radius * 0.42, radius * 0.1, mat, segments=5)


def _out(angle, reach, z):
    return (math.cos(angle) * reach, math.sin(angle) * reach, z)


def _leaves(model, rng, centre, radius, tone, flat=0.74, subdivisions=2, roughness=0.15):
    """A rounded mass of leaves."""
    model.rock(centre, radius, tone, rng, scale=(1.0, 1.0, flat), subdivisions=subdivisions, roughness=roughness)


def big_oak():
    """An old oak, about 12 m tall and wider than that: a huge low trunk forking into
    heavy limbs under a broad, lumpy dome. A tree to steer by."""
    p = palette()
    rng = random.Random(81)
    model = kit.Model("BigOak")
    _roots(model, rng, 0.78, 2.3, 8, p["bark"])
    fork = 3.3
    _limb(model, [(0, 0, 0), (0.06, -0.04, 1.3), (0.02, 0.06, fork)], [0.82, 0.66, 0.6], p["bark"], segments=9)
    limbs = 6
    for k in range(limbs):
        angle = math.tau * k / limbs + rng.uniform(-0.28, 0.28)
        reach = rng.uniform(3.5, 5.1)
        rise = rng.uniform(3.0, 5.0)
        elbow = _out(angle, reach * 0.48, fork + rise * 0.42)
        tip = _out(angle + rng.uniform(-0.25, 0.25), reach, fork + rise)
        _limb(model, [(0, 0, fork - 0.3), elbow, tip], [0.34, 0.21, 0.09], p["bark"], segments=6)
        # Boughs off each limb, each ending in a mass of leaves.
        for n in range(3):
            turn = angle + rng.uniform(-0.75, 0.75)
            end = (tip[0] * rng.uniform(0.55, 0.95) + math.cos(turn) * 1.3, tip[1] * rng.uniform(0.55, 0.95) + math.sin(turn) * 1.3, fork + rise * rng.uniform(0.55, 1.05))
            model.cylinder(elbow, end, 0.1, 0.03, p["bark"], segments=4)
            tone = p["oak_dark"] if end[2] < fork + 3.2 else rng.choice((p["oak_mid"], p["oak_mid"], p["oak_light"]))
            _leaves(model, rng, end, rng.uniform(1.25, 1.75), tone, flat=0.72)
    _leaves(model, rng, (0, 0, 7.5), 3.5, p["oak_dark"], flat=0.62)
    for k in range(5):
        angle = math.tau * k / 5 + rng.uniform(-0.3, 0.3)
        _leaves(model, rng, _out(angle, rng.uniform(1.2, 2.3), rng.uniform(8.7, 9.7)), rng.uniform(1.6, 2.0), rng.choice((p["oak_mid"], p["oak_light"])), flat=0.68)
    _leaves(model, rng, (0.1, -0.1, 10.1), 2.1, p["oak_light"], flat=0.62)
    model.finish()
    kit.collision_cylinder("BigOak", (0, 0, 0), (0, 0, fork + 0.6), 0.8)


def tall_beech():
    """A tall beech, about 15 m: a long smooth grey trunk and an oval crown stacked
    high and narrow, bright at the top."""
    p = palette()
    rng = random.Random(82)
    model = kit.Model("TallBeech")
    _roots(model, rng, 0.46, 1.3, 6, p["grey_bark"])
    _limb(model, [(0, 0, 0), (0.08, 0.04, 3.2), (-0.05, 0.1, 7.2), (0.05, 0.02, 11.2)], [0.5, 0.38, 0.27, 0.12], p["grey_bark"], segments=8)
    for k in range(9):
        angle = k * 2.4 + rng.uniform(-0.25, 0.25)
        base_z = 3.6 + k * 0.82
        reach = rng.uniform(1.7, 3.2) * (1.0 - k * 0.05)
        tip = _out(angle, reach, base_z + rng.uniform(1.5, 2.6))
        _limb(model, [(0, 0, base_z), tip], [0.12, 0.03], p["grey_bark"], segments=4)
    layers = [(6.3, 2.7, 5), (8.2, 3.1, 6), (10.1, 2.7, 5), (11.9, 2.0, 4), (13.3, 1.2, 2)]
    for level, (z, spread, count) in enumerate(layers):
        for k in range(count):
            angle = math.tau * k / count + level * 0.7 + rng.uniform(-0.2, 0.2)
            tone = (p["beech_dark"], p["beech_dark"], p["beech_mid"], p["beech_mid"], p["beech_light"])[level]
            if rng.random() < 0.3:
                tone = rng.choice((p["beech_mid"], p["beech_light"]))
            _leaves(model, rng, _out(angle, spread * rng.uniform(0.45, 0.72), z + rng.uniform(-0.4, 0.4)), spread * rng.uniform(0.48, 0.6) + 0.45, tone, flat=0.84)
    _leaves(model, rng, (0.05, 0, 14.0), 1.15, p["beech_light"], flat=1.0, subdivisions=1)
    model.finish()
    kit.collision_cylinder("TallBeech", (0, 0, 0), (0, 0, 6.0), 0.5)


def tall_pine():
    """A tall pine, about 17 m: a straight reddish trunk, bare low down, and dark tiers
    narrowing to a point, each hanging a little off true."""
    p = palette()
    rng = random.Random(83)
    model = kit.Model("TallPine")
    _roots(model, rng, 0.36, 1.05, 5, p["pine_bark"])
    _limb(model, [(0, 0, 0), (0.03, 0.02, 5.0), (-0.02, 0.03, 11.0), (0, 0, 16.6)], [0.4, 0.3, 0.17, 0.02], p["pine_bark"], segments=7)
    tiers = 9
    z = 3.7
    for k in range(tiers):
        t = k / (tiers - 1)
        wide = 3.5 * (1.0 - t) ** 0.85 + 0.5
        tall = 2.75 - t * 0.85
        tone = (p["pine_dark"], p["pine_mid"], p["pine_light"])[min(int(t * 3.0), 2)]
        off = (rng.uniform(-0.14, 0.14), rng.uniform(-0.14, 0.14))
        model.cylinder((off[0], off[1], z), (off[0] * 0.3, off[1] * 0.3, z + tall), wide, wide * 0.16, tone, segments=9)
        # Boughs that break the rim's outline.
        for n in range(4):
            angle = rng.uniform(0, math.tau)
            model.cylinder(_out(angle, wide * 0.55, z + 0.32), _out(angle, wide * 1.2, z - 0.12), wide * 0.2, 0.03, tone, segments=4)
        z += tall * 0.58
    model.finish()
    kit.collision_cylinder("TallPine", (0, 0, 0), (0, 0, 5.0), 0.42)


def white_birch():
    """A slim white birch, about 9 m, its trunk marked with black and leaning a little
    under a light, airy crown."""
    p = palette()
    rng = random.Random(84)
    model = kit.Model("WhiteBirch")
    points = [(0, 0, 0), (0.08, 0.02, 1.8), (0.2, -0.04, 3.7), (0.14, 0.06, 5.7), (0.3, 0.02, 7.6)]
    radii = [0.19, 0.15, 0.115, 0.08, 0.03]
    _limb(model, points, radii, p["birch_bark"], segments=7)
    for k in range(9):
        at = rng.uniform(0.3, 6.5)
        n = min(int(at / 1.9), 3)
        t = at / 1.9 - n
        a, b = points[n], points[n + 1]
        centre = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)
        wide = (radii[n] + (radii[n + 1] - radii[n]) * t) * 1.05
        model.cylinder(centre, (centre[0], centre[1], centre[2] + rng.uniform(0.025, 0.075)), wide, wide, p["birch_mark"], segments=7)
    leaves = (p["birch_leaf"], p["birch_leaf"], p["birch_leaf_dark"])
    for k in range(7):
        angle = k * 2.4 + rng.uniform(-0.3, 0.3)
        z = 3.9 + k * 0.52
        tip = _out(angle, rng.uniform(0.75, 1.25) * (1.15 - k * 0.07), z + 0.7)
        tip = (tip[0] + 0.15, tip[1], tip[2])
        model.cylinder((0.18, 0.0, z - 0.3), tip, 0.04, 0.012, p["birch_bark"], segments=4)
        # A loose bunch at each branch's end, and hanging below it.
        for n in range(4):
            turn = rng.uniform(0, math.tau)
            bunch = (tip[0] + math.cos(turn) * 0.55, tip[1] + math.sin(turn) * 0.55, tip[2] + rng.uniform(-0.7, 0.3))
            _leaves(model, rng, bunch, rng.uniform(0.46, 0.74), rng.choice(leaves), flat=0.86, subdivisions=1, roughness=0.12)
    _leaves(model, rng, (0.3, 0.02, 7.9), 0.75, p["birch_leaf"], flat=0.95, subdivisions=1, roughness=0.12)
    model.finish()
    kit.collision_cylinder("WhiteBirch", (0, 0, 0), (0.1, 0, 3.0), 0.19)


def field_maple():
    """A round field maple, about 8 m, forking low into several stems, its leaves a
    warmer yellow-green than the others'."""
    p = palette()
    rng = random.Random(85)
    model = kit.Model("FieldMaple")
    _roots(model, rng, 0.36, 1.0, 5, p["bark"])
    model.cylinder((0, 0, 0), (0, 0, 1.5), 0.4, 0.3, p["bark"], segments=8)
    for k in range(4):
        angle = math.tau * k / 4 + rng.uniform(-0.3, 0.3)
        tip = _out(angle, rng.uniform(1.5, 2.3), rng.uniform(4.4, 5.3))
        elbow = _out(angle, 0.75, 3.0)
        _limb(model, [(0, 0, 1.3), elbow, tip], [0.2, 0.13, 0.05], p["bark"], segments=5)
    tones = (p["maple_mid"], p["maple_mid"], p["maple_light"], p["maple_dark"])
    for k in range(7):
        angle = math.tau * k / 7 + rng.uniform(-0.2, 0.2)
        _leaves(model, rng, _out(angle, rng.uniform(1.9, 2.6), rng.uniform(4.0, 4.9)), rng.uniform(1.3, 1.65), p["maple_dark"] if k % 3 == 0 else rng.choice(tones), flat=0.8)
    for k in range(4):
        angle = math.tau * k / 4 + 0.5
        _leaves(model, rng, _out(angle, rng.uniform(0.8, 1.3), rng.uniform(5.7, 6.3)), rng.uniform(1.35, 1.6), rng.choice((p["maple_mid"], p["maple_light"])), flat=0.8)
    _leaves(model, rng, (0, 0, 6.9), 1.2, p["maple_light"], flat=0.72)
    model.finish()
    kit.collision_cylinder("FieldMaple", (0, 0, 0), (0, 0, 2.2), 0.4)


def apple_tree():
    """A small old apple tree, about 4.5 m, gnarled and low, with red apples in it."""
    p = palette()
    rng = random.Random(86)
    model = kit.Model("AppleTree")
    _limb(model, [(0, 0, 0), (0.12, 0.05, 0.75), (-0.04, 0.12, 1.25)], [0.2, 0.16, 0.14], p["bark"], segments=7)
    tips = []
    for k in range(5):
        angle = math.tau * k / 5 + rng.uniform(-0.3, 0.3)
        tip = _out(angle, rng.uniform(0.95, 1.5), rng.uniform(2.3, 3.0))
        elbow = _out(angle + 0.3, 0.55, 1.75)
        _limb(model, [(0, 0.05, 1.15), elbow, tip], [0.1, 0.07, 0.03], p["bark"], segments=5)
        tips.append(tip)
    masses = []
    for k, tip in enumerate(tips):
        radius = rng.uniform(0.82, 1.02)
        _leaves(model, rng, tip, radius, p["leaf_deep"] if k % 2 else p["leaf_mid"], flat=0.78, roughness=0.1)
        masses.append((tip, radius))
    top = (0.05, 0.05, 3.45)
    _leaves(model, rng, top, 1.08, p["leaf_light"], flat=0.72, roughness=0.1)
    masses.append((top, 1.08))
    # Apples showing on the outsides of the masses.
    for k in range(24):
        centre, radius = masses[k % len(masses)]
        turn = rng.uniform(0, math.tau)
        lift = rng.uniform(-0.45, 0.35)
        out = radius * 0.97
        at = (centre[0] + math.cos(turn) * out * math.cos(lift), centre[1] + math.sin(turn) * out * math.cos(lift), centre[2] + out * math.sin(lift) * 0.72)
        model.sphere(at, 0.09, p["apple_red"], segments=5, rings=3)
    model.finish()
    kit.collision_cylinder("AppleTree", (0, 0, 0), (0, 0, 1.3), 0.22)


BUILDERS = {fn.__name__: fn for fn in (big_oak, tall_beech, tall_pine, white_birch, field_maple, apple_tree)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
