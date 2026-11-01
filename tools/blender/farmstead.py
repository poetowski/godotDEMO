"""The farmstead family: the small farm in R1's D5, and what grows along the author's
roads around it. It shares the riverside family's palette, so they belong together, and
adds hay and sawn wood. Each asset is a small script in tools/blender/assets/ that calls
make(<slug>). Colours are sRGB. The shapes and colours are placeholders until the author
says otherwise (docs/world/regions/R1/art.md).
"""
import math
import random

import kit
import riverside

# The house, in metres: half its length (X) and depth (Y) to the middle of its walls, the
# stone it stands on, and the roof over it, its ridge running along X.
HOUSE_X = 3.2
HOUSE_Y = 2.3
PLINTH = 0.55
WALL_TOP = 2.7
ROOF_X = 3.7
EAVE_Y = 3.0
EAVE_Z = 2.4
RIDGE_Z = 4.55
# Logs' thickness, and how far they stick out past the corners.
LOG_RADIUS = 0.14
LOG_STEP = 0.26
LOG_PAST = 0.22
# A fence's length between its end posts, and its height.
FENCE_LENGTH = 2.4
FENCE_HEIGHT = 0.85


def palette():
    """The riverside palette and the farm's own materials."""
    p = riverside.palette()
    m = kit.material
    p.update({
        "hay": m("Hay", (0.74, 0.64, 0.35), roughness=1.0),
        "hay_dark": m("HayDark", (0.67, 0.57, 0.30), roughness=1.0),
        "hay_old": m("HayOld", (0.56, 0.49, 0.27), roughness=1.0),
        "log": m("Log", (0.44, 0.34, 0.23), roughness=0.95),
        "log_dark": m("LogDark", (0.34, 0.27, 0.18), roughness=0.95),
        "plank": m("Plank", (0.52, 0.41, 0.27), roughness=0.9),
        "plank_dark": m("PlankDark", (0.40, 0.31, 0.21), roughness=0.9),
        "shadow": m("Shadow", (0.11, 0.09, 0.07), roughness=1.0),
        "iron": m("Iron", (0.17, 0.16, 0.15), roughness=0.7, metallic=0.4),
        "petal_red": m("PetalRed", (0.80, 0.17, 0.13), roughness=0.7),
    })
    return p


def _roof_point(side, t):
    """A point up one slope, from the eave (t = 0) to the ridge (t = 1): y and z."""
    return side * EAVE_Y * (1.0 - t), EAVE_Z + (RIDGE_Z - EAVE_Z) * t


def _thatch(model, p, rng):
    """Courses of hay bundles lapping down both slopes, each proud of the one below."""
    courses = 8
    tones = (p["hay"], p["hay"], p["hay"], p["hay_dark"], p["hay_dark"], p["hay_old"])
    for side in (-1, 1):
        for course in range(courses):
            high = min((course + 1.5) / courses, 1.0)
            y_high, z_high = _roof_point(side, high)
            x = -ROOF_X
            while x < ROOF_X - 0.01:
                next_x = min(x + rng.uniform(0.24, 0.44), ROOF_X)
                y_low, z_low = _roof_point(side, course / courses - rng.uniform(0.0, 0.04))
                z_low += 0.09
                if side < 0:
                    corners = [(x, y_low, z_low), (next_x, y_low, z_low), (next_x, y_high, z_high), (x, y_high, z_high)]
                else:
                    corners = [(x, y_high, z_high), (next_x, y_high, z_high), (next_x, y_low, z_low), (x, y_low, z_low)]
                model.slab(corners, 0.2, rng.choice(tones))
                x = next_x
    # Loose ends of hay hanging from the eaves.
    for side in (-1, 1):
        y, z = _roof_point(side, -0.02)
        for k in range(46):
            x = -ROOF_X + 2.0 * ROOF_X * k / 45 + rng.uniform(-0.05, 0.05)
            long = rng.uniform(0.14, 0.3)
            model.ribbon([(x, y, z + 0.0), (x + rng.uniform(-0.04, 0.04), y + side * 0.05, z - long)], 0.0, [rng.uniform(0.09, 0.15), 0.0], rng.choice(tones))
    model.cylinder((-ROOF_X - 0.04, 0, RIDGE_Z + 0.02), (ROOF_X + 0.04, 0, RIDGE_Z + 0.02), 0.17, 0.17, p["hay_dark"], segments=6)
    # Pairs of sticks crossed over the ridge hold it down.
    for k in range(5):
        x = -ROOF_X + 0.5 + k * (2.0 * ROOF_X - 1.0) / 4
        for side in (-1, 1):
            model.cylinder((x, side * 0.42, RIDGE_Z - 0.2), (x, -side * 0.2, RIDGE_Z + 0.26), 0.022, 0.018, p["bark"], segments=4)


def _roof_growth(model, p, rng):
    """Patches of grass rooted in low sods and moss, where the old hay has rotted."""
    leaves = [p["leaf_mid"], p["leaf_light"], p["leaf_light"], p["leaf_deep"], p["leaf_dry"]]
    for cluster in range(14):
        side = rng.choice((-1, 1))
        middle_x = rng.uniform(-ROOF_X * 0.86, ROOF_X * 0.86)
        middle_t = rng.uniform(0.06, 0.82)
        for sod in range(3):
            y, z = _roof_point(side, min(max(middle_t + rng.uniform(-0.09, 0.09), 0.02), 0.96))
            model.rock((middle_x + rng.uniform(-0.4, 0.4), y, z + 0.1), rng.uniform(0.15, 0.27), rng.choice((p["moss"], p["moss"], p["leaf_mid"])), rng, scale=(1.5, 1.25, 0.42), roughness=0.12)
        for clump in range(7):
            x = middle_x + rng.uniform(-0.62, 0.62)
            y, z = _roof_point(side, min(max(middle_t + rng.uniform(-0.13, 0.13), 0.02), 0.97))
            for n in range(5):
                model.blade((x + rng.uniform(-0.07, 0.07), y + rng.uniform(-0.07, 0.07), z + 0.08), rng.uniform(0, math.tau), rng.uniform(0.28, 0.52), rng.uniform(0.04, 0.062), rng.uniform(0.2, 0.55), rng.choice(leaves), segments=2)


def _log_walls(model, p, rng):
    """Walls of logs crossing at the corners, with a dark core behind any chinks."""
    long_half = HOUSE_X + LOG_PAST
    short_half = HOUSE_Y + LOG_PAST
    model.box((0, 0, (PLINTH + WALL_TOP) / 2), (2 * HOUSE_X - 0.08, 2 * HOUSE_Y - 0.08, WALL_TOP - PLINTH), p["log_dark"])
    z = PLINTH + LOG_RADIUS
    while z < WALL_TOP:
        for side in (-1, 1):
            model.cylinder((-long_half, side * HOUSE_Y, z), (long_half, side * HOUSE_Y, z), LOG_RADIUS, LOG_RADIUS * rng.uniform(0.92, 1.0), rng.choice((p["log"], p["log"], p["log_dark"])), segments=6)
            model.cylinder((side * HOUSE_X, -short_half, z + LOG_STEP / 2), (side * HOUSE_X, short_half, z + LOG_STEP / 2), LOG_RADIUS, LOG_RADIUS * rng.uniform(0.92, 1.0), rng.choice((p["log"], p["log"], p["log_dark"])), segments=6)
        z += LOG_STEP
    # The gables go on up in shorter and shorter logs, under the hay.
    z = WALL_TOP + LOG_STEP / 2
    while True:
        half = EAVE_Y * (RIDGE_Z - 0.28 - z) / (RIDGE_Z - EAVE_Z)
        if half < 0.12:
            break
        half = min(half, HOUSE_Y)
        for side in (-1, 1):
            model.cylinder((side * HOUSE_X, -half, z), (side * HOUSE_X, half, z), LOG_RADIUS, LOG_RADIUS, rng.choice((p["log"], p["log_dark"])), segments=6)
        z += LOG_STEP
    # Rafters show at the ends of the roof.
    for x in (-ROOF_X + 0.02, ROOF_X - 0.02):
        for side in (-1, 1):
            y, z_low = _roof_point(side, -0.02)
            model.cylinder((x, y, z_low - 0.12), (x, 0, RIDGE_Z - 0.12), 0.06, 0.05, p["bark"], segments=5)


def _shutters(model, p, rng, centre, across_x):
    """A closed window: a frame, two leaves of planks and a bar across them. `across_x`
    is True on a wall facing -Y or +Y, where the leaves spread along X."""
    wide = 0.82
    tall = 0.88
    def block(along, up, deep, size_along, size_up, size_deep, mat):
        at = (centre[0] + along, centre[1] + deep, centre[2] + up) if across_x else (centre[0] + deep, centre[1] + along, centre[2] + up)
        size = (size_along, size_deep, size_up) if across_x else (size_deep, size_along, size_up)
        model.box(at, size, mat)
    out = 1.0 if (centre[1] if across_x else centre[0]) > 0 else -1.0
    block(0, 0, 0, wide + 0.16, tall + 0.16, 0.05, p["log_dark"])
    planks = 6
    for k in range(planks):
        along = -wide / 2 + wide * (k + 0.5) / planks
        block(along, 0, out * 0.04, wide / planks - 0.012, tall, 0.04, rng.choice((p["plank"], p["plank"], p["plank_dark"])))
    block(0, tall * 0.5 + 0.06, out * 0.05, wide + 0.26, 0.09, 0.08, p["log_dark"])
    block(0, -tall * 0.5 - 0.06, out * 0.05, wide + 0.3, 0.09, 0.1, p["log_dark"])
    block(0, 0.02, out * 0.075, wide + 0.06, 0.07, 0.035, p["plank_dark"])


def _door(model, p, rng):
    """A closed door of planks at the front, with its frame and stone steps."""
    y = -(HOUSE_Y + LOG_RADIUS + 0.015)
    bottom = PLINTH
    tall = 1.98
    wide = 1.02
    model.box((0, y + 0.02, bottom + tall / 2), (wide + 0.1, 0.05, tall + 0.05), p["shadow"])
    planks = 5
    for k in range(planks):
        x = -wide / 2 + wide * (k + 0.5) / planks
        model.box((x, y - 0.02, bottom + tall / 2), (wide / planks - 0.012, 0.05, tall), rng.choice((p["plank"], p["plank_dark"])))
    for z in (bottom + 0.35, bottom + tall - 0.35):
        model.box((0, y - 0.055, z), (wide - 0.06, 0.03, 0.12), p["plank_dark"])
    model.sphere((wide * 0.34, y - 0.09, bottom + tall * 0.5), 0.04, p["iron"], segments=6, rings=4)
    for x in (-wide / 2 - 0.09, wide / 2 + 0.09):
        model.cylinder((x, y - 0.03, bottom), (x, y - 0.03, bottom + tall + 0.1), 0.075, 0.07, p["bark"], segments=6)
    model.cylinder((-wide / 2 - 0.2, y - 0.03, bottom + tall + 0.1), (wide / 2 + 0.2, y - 0.03, bottom + tall + 0.1), 0.08, 0.08, p["bark"], segments=6)
    model.box((0, y - 0.42, PLINTH * 0.75), (1.34, 0.5, 0.2), p["stone_mid"])
    model.box((0, y - 0.82, PLINTH * 0.32), (1.5, 0.56, PLINTH * 0.64), p["stone_dark"])


def farmhouse():
    """A small log farmhouse with its windows shuttered, on a stone footing, under an old
    roof of hay with grass growing in it."""
    p = palette()
    rng = random.Random(61)
    model = kit.Model("Farmhouse")
    model.box((0, 0, PLINTH / 2), (2 * HOUSE_X + 0.42, 2 * HOUSE_Y + 0.42, PLINTH), p["stone_dark"])
    around = 2 * (HOUSE_X + HOUSE_Y)
    for k in range(20):
        along = k / 20 * around * 2
        if along < 2 * HOUSE_X:
            x, y = -HOUSE_X + along, -HOUSE_Y - 0.2
        elif along < 2 * HOUSE_X + 2 * HOUSE_Y:
            x, y = HOUSE_X + 0.2, -HOUSE_Y + along - 2 * HOUSE_X
        elif along < 4 * HOUSE_X + 2 * HOUSE_Y:
            x, y = HOUSE_X - (along - 2 * HOUSE_X - 2 * HOUSE_Y), HOUSE_Y + 0.2
        else:
            x, y = -HOUSE_X - 0.2, HOUSE_Y - (along - 4 * HOUSE_X - 2 * HOUSE_Y)
        if abs(x) < 0.8 and y < 0:
            continue
        model.rock((x, y, rng.uniform(0.1, 0.22)), rng.uniform(0.16, 0.28), rng.choice((p["stone_mid"], p["stone_light"], p["stone_dark"])), rng, scale=(1.3, 0.8, 0.8))
    _log_walls(model, p, rng)
    _thatch(model, p, rng)
    _roof_growth(model, p, rng)
    _door(model, p, rng)
    wall = HOUSE_Y + LOG_RADIUS + 0.02
    for x in (-1.8, 1.8):
        _shutters(model, p, rng, (x, -wall, 1.68), True)
    _shutters(model, p, rng, (0.0, wall, 1.68), True)
    end = HOUSE_X + LOG_RADIUS + 0.02
    for x in (-end, end):
        _shutters(model, p, rng, (x, 0.0, 1.68), False)
    # A stone chimney through the roof.
    model.box((1.85, 0.62, 3.65), (0.66, 0.66, 2.6), p["stone_mid"])
    model.box((1.87, 0.6, 4.72), (0.72, 0.72, 0.28), p["stone_dark"])
    model.box((1.85, 0.62, 4.92), (0.82, 0.82, 0.1), p["stone_light"])
    model.box((1.85, 0.62, 4.93), (0.42, 0.42, 0.1), p["shadow"])
    # Firewood stacked under the eave.
    for row in range(3):
        for k in range(5 - row):
            y = -1.25 + 0.2 * row * 0.5 + k * 0.2
            model.cylinder((HOUSE_X + 0.3, y, PLINTH * 0.2 + 0.09 + row * 0.17), (HOUSE_X + 0.82, y + 0.01, PLINTH * 0.2 + 0.09 + row * 0.17), 0.09, 0.085, rng.choice((p["wood_drift"], p["log"])), segments=6)
    model.finish()
    kit.collision_box("Farmhouse", (0, 0, WALL_TOP / 2), (2 * HOUSE_X + 0.42, 2 * HOUSE_Y + 0.42, WALL_TOP))
    for n, side in enumerate((-1, 1)):
        y, z = _roof_point(side, 0.0)
        kit.collision_slab(f"FarmhouseRoof{n}", (0, y, z - 0.2), (0, 0, RIDGE_Z - 0.2), 2 * ROOF_X, 0.3)


def _post(model, p, rng, x, y=0.0, lean=(0.0, 0.0), tall=None, thick=0.066):
    """A rough stake with a chopped top, a little off straight."""
    top = (tall if tall else FENCE_HEIGHT) * rng.uniform(0.95, 1.08)
    head = (x + lean[0] + rng.uniform(-0.015, 0.015), y + lean[1] + rng.uniform(-0.015, 0.015), top)
    model.cylinder((x, y, 0.0), head, thick * rng.uniform(0.92, 1.08), thick * rng.uniform(0.68, 0.8), rng.choice((p["bark"], p["log_dark"])), segments=6)
    return head


def _rail(model, p, rng, a, b, sag=0.03):
    """A split sapling between two points, sagging a little, its ends past them."""
    middle = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + rng.uniform(-0.012, 0.012), (a[2] + b[2]) / 2 - sag)
    tone = rng.choice((p["wood_drift"], p["log"], p["wood_drift"]))
    radius = rng.uniform(0.04, 0.05)
    model.cylinder(a, middle, radius, radius * 0.92, tone, segments=5)
    model.cylinder(middle, b, radius * 0.92, radius * 0.85, tone, segments=5)


def _fence_collision(name):
    kit.collision_box(name, (0, 0, FENCE_HEIGHT / 2), (FENCE_LENGTH, 0.14, FENCE_HEIGHT))


def farm_fence_a():
    """Two rails of rough saplings between stakes."""
    p = palette()
    rng = random.Random(62)
    model = kit.Model("FarmFenceA")
    half = FENCE_LENGTH / 2
    for x in (-half + 0.03, half - 0.03):
        _post(model, p, rng, x)
    for z in (FENCE_HEIGHT * 0.84, FENCE_HEIGHT * 0.46):
        _rail(model, p, rng, (-half - 0.1, 0.04, z), (half + 0.1, 0.04, z + rng.uniform(-0.03, 0.03)))
    model.finish()
    _fence_collision("FarmFenceA")


def farm_fence_b():
    """A woven hurdle: thin rods wound in and out of a row of stakes."""
    p = palette()
    rng = random.Random(63)
    model = kit.Model("FarmFenceB")
    half = FENCE_LENGTH / 2
    stakes = 8
    xs = [-half + 0.03 + (FENCE_LENGTH - 0.06) * k / (stakes - 1) for k in range(stakes)]
    for x in xs:
        end = x in (xs[0], xs[-1])
        _post(model, p, rng, x, tall=FENCE_HEIGHT * (1.0 if end else 0.84), thick=0.06 if end else 0.026)
    z = 0.1
    row = 0
    while z < FENCE_HEIGHT * 0.76:
        tone = rng.choice((p["wood_drift"], p["wood_drift"], p["log"], p["plank"]))
        for k in range(stakes - 1):
            sign = 1 if (k + row) % 2 else -1
            model.cylinder((xs[k], sign * 0.032, z), (xs[k + 1], -sign * 0.032, z + rng.uniform(-0.006, 0.006)), 0.021, 0.021, tone, segments=4)
        z += 0.05
        row += 1
    model.finish()
    _fence_collision("FarmFenceB")


def farm_fence_c():
    """An old length of the rail fence: one stake leaning, one rail fallen, a rail split."""
    p = palette()
    rng = random.Random(64)
    model = kit.Model("FarmFenceC")
    half = FENCE_LENGTH / 2
    left = _post(model, p, rng, -half + 0.03, lean=(0.05, 0.03))
    right = _post(model, p, rng, half - 0.03, lean=(-0.2, -0.1), tall=FENCE_HEIGHT * 0.9)
    _rail(model, p, rng, (-half - 0.1, 0.04, left[2] * 0.82), (right[0] + 0.12, right[1] + 0.03, right[2] * 0.8), sag=0.05)
    # The lower rail has come away at one end and lies against the ground.
    _rail(model, p, rng, (-half + 0.06, 0.05, FENCE_HEIGHT * 0.42), (half - 0.25, -0.12, 0.03), sag=0.0)
    model.finish()
    _fence_collision("FarmFenceC")


def hay_stack():
    """A stack of hay built round a pole, as tall as a man and more."""
    p = palette()
    rng = random.Random(65)
    model = kit.Model("HayStack")
    model.lathe([(0.72, 0.0), (0.84, 0.3), (0.8, 0.92), (0.56, 1.42), (0.24, 1.78), (0.03, 1.9)], p["hay"], segments=11)
    # Layers lapping down it, each with a slightly different colour and a loose rim.
    for low, high, wide, top_wide, tone in ((0.0, 0.62, 0.9, 0.82, "hay_dark"), (0.5, 1.12, 0.84, 0.66, "hay"), (1.02, 1.58, 0.68, 0.34, "hay_dark")):
        model.lathe([(wide, low), (top_wide, high)], p[tone], segments=11)
        for k in range(18):
            angle = math.tau * k / 18 + rng.uniform(-0.1, 0.1)
            x, y = math.cos(angle) * wide, math.sin(angle) * wide
            model.ribbon([(x, y, low + 0.14), (x * 1.04, y * 1.04, max(low - 0.1, 0.0))], angle + math.pi / 2, [0.2, 0.0], p[tone])
    for k in range(12):
        angle = rng.uniform(0, math.tau)
        model.blade((math.cos(angle) * 0.92, math.sin(angle) * 0.92, 0.0), angle, rng.uniform(0.2, 0.36), 0.04, 0.9, rng.choice((p["hay"], p["hay_dark"], p["leaf_dry"])))
    model.cylinder((0, 0, 1.5), (0.03, 0.02, 2.2), 0.04, 0.025, p["bark"], segments=5)
    model.finish()
    kit.collision_cylinder("HayStack", (0, 0, 0), (0, 0, 1.5), 0.82)


def big_boulder_a():
    """A big rounded boulder, moss on its shoulders."""
    riverside._stone("BigBoulderA", 66, 1.35, 0.82, "stone_mid", moss=0.6, solid=True)


def big_boulder_b():
    """A big split boulder: a tall piece with a lower one leaning on it, and moss in the join."""
    p = palette()
    rng = random.Random(67)
    model = kit.Model("BigBoulderB")
    model.rock((-0.38, 0.05, 0.92), 1.08, p["stone_light"], rng, scale=(0.85, 0.82, 1.0), subdivisions=2)
    model.rock((0.92, -0.2, 0.42), 0.82, p["stone_dark"], rng, scale=(1.0, 0.85, 0.72), subdivisions=2)
    model.rock((0.4, 0.05, 0.92), 0.48, p["moss"], rng, scale=(1.3, 1.05, 0.55), subdivisions=1, roughness=0.14)
    model.rock((-0.55, -0.15, 1.72), 0.46, p["moss"], rng, scale=(1.3, 1.0, 0.42), subdivisions=1, roughness=0.14)
    model.finish()
    kit.collision_cylinder("BigBoulderB", (-0.38, 0.05, 0), (-0.38, 0.05, 1.8), 0.82)
    kit.collision_cylinder("BigBoulderBLow", (0.92, -0.2, 0), (0.92, -0.2, 0.85), 0.68)


def moss_patch():
    """A low cushion of moss spreading over the ground."""
    p = palette()
    rng = random.Random(68)
    model = kit.Model("MossPatch")
    for k in range(6):
        angle = math.tau * k / 6 + rng.uniform(-0.3, 0.3)
        out = 0.0 if k == 0 else rng.uniform(0.22, 0.42)
        model.rock((math.cos(angle) * out, math.sin(angle) * out, 0.02), rng.uniform(0.2, 0.34), rng.choice((p["moss"], p["moss"], p["leaf_deep"])), rng, scale=(1.2, 1.05, 0.34), subdivisions=1, roughness=0.14)
    model.finish()


def meadow_grass_a():
    """A low clump of the field's grass."""
    p = palette()
    rng = random.Random(69)
    model = kit.Model("MeadowGrassA")
    riverside._blades(model, rng, 13, 0.13, 0.36, 0.34, 0.03, [p["leaf_mid"], p["leaf_light"], p["leaf_light"]])
    model.finish()


def meadow_grass_b():
    """A taller clump gone to seed, drying at the tips."""
    p = palette()
    rng = random.Random(70)
    model = kit.Model("MeadowGrassB")
    riverside._blades(model, rng, 9, 0.11, 0.44, 0.3, 0.028, [p["leaf_mid"], p["leaf_light"], p["leaf_dry"]])
    for k in range(5):
        angle = math.tau * k / 5 + rng.uniform(-0.4, 0.4)
        out = rng.uniform(0.04, 0.16)
        tall = rng.uniform(0.52, 0.72)
        top = (math.cos(angle) * out, math.sin(angle) * out, tall)
        model.cylinder((top[0] * 0.2, top[1] * 0.2, 0), top, 0.006, 0.004, p["leaf_dry"], segments=3)
        model.sphere((top[0], top[1], tall + 0.03), 0.018, p["leaf_dry"], scale=(0.8, 0.8, 2.4), segments=5, rings=3)
    model.finish()


def _flowers(name, seed, petal, middle, petals, length, width, lift, heart):
    """A few flowers on thin stems, big enough to read from where the hero looks, with
    leaves at their feet."""
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    riverside._blades(model, rng, 7, 0.12, 0.2, 0.55, 0.04, [p["leaf_mid"], p["leaf_deep"]])
    for k in range(6):
        angle = math.tau * k / 6 + rng.uniform(-0.35, 0.35)
        out = rng.uniform(0.05, 0.2)
        x, y = math.cos(angle) * out, math.sin(angle) * out
        z = rng.uniform(0.2, 0.34)
        model.cylinder((x * 0.3, y * 0.3, 0), (x, y, z), 0.009, 0.007, p["leaf_light"], segments=3)
        turn = rng.uniform(0, math.tau)
        for n in range(petals):
            model.petal((x, y, z), turn + math.tau * n / petals, length, width, lift, p[petal])
        if middle:
            model.sphere((x, y, z + heart * 0.75), heart, p[middle], scale=(1, 1, 0.75), segments=4, rings=2)
    model.finish()


def wild_flowers_a():
    """White daisies with yellow hearts."""
    _flowers("WildFlowersA", 71, "petal_white", "petal_yellow", 7, 0.075, 0.04, 0.012, 0.022)


def wild_flowers_b():
    """Blue-violet cornflowers."""
    _flowers("WildFlowersB", 72, "petal_violet", None, 6, 0.07, 0.04, 0.035, 0.0)


def wild_flowers_c():
    """Red poppies, wide open, a small dark heart in each."""
    _flowers("WildFlowersC", 73, "petal_red", "shadow", 5, 0.085, 0.075, 0.028, 0.018)


BUILDERS = {fn.__name__: fn for fn in (
    farmhouse, farm_fence_a, farm_fence_b, farm_fence_c, hay_stack, big_boulder_a, big_boulder_b, moss_patch,
    meadow_grass_a, meadow_grass_b, wild_flowers_a, wild_flowers_b, wild_flowers_c,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
