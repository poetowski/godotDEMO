"""The village family: the houses of R1's village, its old stave church on the hill, the farm's
shed, and what lies about between them. It's built the way the farmhouse is, from the farmstead
family's logs, planks, hay and stone, so the farm by the river and the village read as one
people. Roofs add turf and tarred shingles, the old northern way. The church has no cross:
dragon heads on its gables and a sun wheel on its spire. Each asset is a small script in
tools/blender/assets/ that calls make(<slug>). Colours are sRGB. The kinds and shapes are
placeholders until the author says otherwise (docs/world/regions/R1/art.md).
"""
import math
import random

import farmstead
import kit


def palette():
    """The farmstead palette and the village's own materials."""
    p = farmstead.palette()
    m = kit.material
    p.update({
        "tar": m("Tar", (0.20, 0.15, 0.11), roughness=0.85),
        "tar_light": m("TarLight", (0.29, 0.22, 0.15), roughness=0.9),
        "shingle_a": m("ShingleA", (0.22, 0.18, 0.14), roughness=0.95),
        "shingle_b": m("ShingleB", (0.26, 0.21, 0.16), roughness=0.95),
        "shingle_c": m("ShingleC", (0.31, 0.26, 0.20), roughness=1.0),
        "birch_bark": m("BirchBarkEdge", (0.72, 0.68, 0.58), roughness=0.95),
        "turf": m("Turf", (0.31, 0.44, 0.19), roughness=1.0),
        "turf_dark": m("TurfDark", (0.24, 0.36, 0.16), roughness=1.0),
        "ivy": m("Ivy", (0.17, 0.33, 0.15), roughness=0.85),
        "ivy_light": m("IvyLight", (0.27, 0.43, 0.18), roughness=0.85),
        "cloth": m("Cloth", (0.56, 0.31, 0.21), roughness=1.0),
        "cloth_pale": m("ClothPale", (0.72, 0.66, 0.51), roughness=1.0),
        "soil": m("Soil", (0.27, 0.20, 0.13), roughness=1.0),
        "water_dark": m("WaterDark", (0.10, 0.17, 0.20), roughness=0.2),
        "carving": m("Carving", (0.33, 0.24, 0.15), roughness=0.9),
        "rune": m("Rune", (0.13, 0.11, 0.10), roughness=1.0),
        "ember": m("VillageEmber", (0.95, 0.36, 0.09), roughness=0.8, emission=(1.0, 0.36, 0.08), emission_strength=2.2),
    })
    return p


# ---- walls and roofs


def _footing(model, p, rng, hx, hy, tall):
    """A low stone footing with field stones gathered against it."""
    model.box((0, 0, tall / 2), (2 * hx + 0.4, 2 * hy + 0.4, tall), p["stone_dark"])
    around = 4 * (hx + hy)
    for k in range(int(around / 1.2)):
        along = (k + rng.uniform(0.0, 0.6)) * 1.2
        if along < 2 * hx:
            x, y = -hx + along, -hy - 0.2
        elif along < 2 * (hx + hy):
            x, y = hx + 0.2, -hy + along - 2 * hx
        elif along < 4 * hx + 2 * hy:
            x, y = hx - (along - 2 * hx - 2 * hy), hy + 0.2
        else:
            x, y = -hx - 0.2, hy - (along - 4 * hx - 2 * hy)
        if abs(x) < 0.85 and y < 0:
            continue
        model.rock((x, y, rng.uniform(0.1, 0.2)), rng.uniform(0.15, 0.26), rng.choice((p["stone_mid"], p["stone_light"], p["stone_dark"])), rng, scale=(1.3, 0.8, 0.8))


def _log_walls(model, p, rng, hx, hy, base, top, ridge, eave_y, eave_z, radius=0.14, past=0.22):
    """Walls of logs crossing at the corners, going on up in the gables under the roof."""
    step = radius * 1.85
    model.box((0, 0, (base + top) / 2), (2 * hx - 0.08, 2 * hy - 0.08, top - base), p["log_dark"])
    z = base + radius
    while z < top:
        for side in (-1, 1):
            model.cylinder((-hx - past, side * hy, z), (hx + past, side * hy, z), radius, radius * rng.uniform(0.92, 1.0), rng.choice((p["log"], p["log"], p["log_dark"])), segments=6)
            model.cylinder((side * hx, -hy - past, z + step / 2), (side * hx, hy + past, z + step / 2), radius, radius * rng.uniform(0.92, 1.0), rng.choice((p["log"], p["log"], p["log_dark"])), segments=6)
        z += step
    z = top + step / 2
    while True:
        half = eave_y * (ridge - 0.28 - z) / (ridge - eave_z)
        if half < 0.12:
            break
        half = min(half, hy)
        for side in (-1, 1):
            model.cylinder((side * hx, -half, z), (side * hx, half, z), radius, radius, rng.choice((p["log"], p["log_dark"])), segments=6)
        z += step


def _plank_walls(model, p, rng, hx, hy, base, top, ridge, tones=("plank", "plank_dark", "plank")):
    """Upright boards over a dark core, with a gable of boards at each end."""
    model.box((0, 0, (base + top) / 2), (2 * hx - 0.04, 2 * hy - 0.04, top - base), p["log_dark"])
    tall = top - base
    middle = (base + top) / 2
    wide = 0.27
    for side in (-1, 1):
        for k in range(int(2 * hx / wide)):
            model.box((-hx + wide * (k + 0.5), side * hy, middle), (wide - 0.02, 0.05, tall), p[rng.choice(tones)])
        for k in range(int(2 * hy / wide)):
            y = -hy + wide * (k + 0.5)
            top_here = ridge - (ridge - top) * abs(y) / hy - 0.12
            model.box((side * hx, y, (base + top_here) / 2), (0.05, wide - 0.02, top_here - base), p[rng.choice(tones)])
    for x, y in ((-hx, -hy), (hx, -hy), (-hx, hy), (hx, hy)):
        model.cylinder((x, y, base), (x, y, top + 0.05), 0.09, 0.08, p["bark"], segments=6)


def _roof_plane(model, rng, a, b, c, d, courses, bands, tones, thick=0.12, lap=0.06):
    """Courses of bundles or shingles over a plane whose corners run anticlockwise from
    above: a and b along the eave, then c and d along the top. Each course overlaps the one
    below it, and a tone is picked per piece."""
    def at(u, v):
        low = [a[n] + (b[n] - a[n]) * u for n in range(3)]
        high = [d[n] + (c[n] - d[n]) * u for n in range(3)]
        return tuple(low[n] + (high[n] - low[n]) * v for n in range(3))

    for course in range(courses):
        v0 = course / courses
        v1 = min((course + 1.45) / courses, 1.0)
        shift = rng.uniform(0.0, 1.0 / bands)
        u = 0.0
        k = 0
        while u < 0.999:
            next_u = min((k + 1) / bands + shift * (1 if k + 1 < bands else 0), 1.0)
            # Its lower edge stands proud of the course beneath, as bundles and shingles do.
            lift = (lap * 2.2, lap * 2.2, 0.0, 0.0)
            corners = []
            for n, point in enumerate((at(u, v0), at(next_u, v0), at(next_u, v1), at(u, v1))):
                corners.append((point[0], point[1], point[2] + lift[n]))
            model.slab(corners, thick, rng.choice(tones))
            u = next_u
            k += 1


def _gable_roof(model, rng, rx, ey, ez, rz, courses, bands, tones, thick=0.12):
    """Both slopes of a gabled roof, ridge along X."""
    _roof_plane(model, rng, (-rx, -ey, ez), (rx, -ey, ez), (rx, 0.0, rz), (-rx, 0.0, rz), courses, bands, tones, thick)
    _roof_plane(model, rng, (rx, ey, ez), (-rx, ey, ez), (-rx, 0.0, rz), (rx, 0.0, rz), courses, bands, tones, thick)


def _roof_collision(name, rx, ey, ez, rz):
    for n, side in enumerate((-1, 1)):
        kit.collision_slab(f"{name}Roof{n}", (0, side * ey, ez - 0.2), (0, 0, rz - 0.2), 2 * rx, 0.3)


def _slope_point(side, t, ey, ez, rz):
    return side * ey * (1.0 - t), ez + (rz - ez) * t


def _slope_patch(model, tone, rng, side, x, t, ey, ez, rz, size, pieces=5, lift=0.2):
    """A sheet of moss or a bare place lying along a roof's slope, in ragged overlapping
    pieces, instead of a lump sitting on it."""
    run = max(math.hypot(ey, rz - ez), 0.1)
    for k in range(pieces):
        cx = x + rng.uniform(-size, size) * 0.7
        ct = t + rng.uniform(-size, size) * 0.7 / run
        w = size * rng.uniform(0.35, 0.7)
        h = size * rng.uniform(0.35, 0.7) / run
        t0 = max(ct - h, 0.0)
        t1 = min(ct + h, 0.99)
        y0, z0 = _slope_point(side, t0, ey, ez, rz)
        y1, z1 = _slope_point(side, t1, ey, ez, rz)
        if side < 0:
            corners = [(cx - w, y0, z0 + lift), (cx + w, y0, z0 + lift), (cx + w, y1, z1 + lift), (cx - w, y1, z1 + lift)]
        else:
            corners = [(cx + w, y0, z0 + lift), (cx - w, y0, z0 + lift), (cx - w, y1, z1 + lift), (cx + w, y1, z1 + lift)]
        model.slab(corners, 0.06, tone)


def _growth(model, p, rng, rx, ey, ez, rz, clusters, blades=5, flowers=False):
    """Sods and grass rooted in a roof."""
    leaves = [p["leaf_mid"], p["leaf_light"], p["leaf_light"], p["leaf_deep"], p["leaf_dry"]]
    for cluster in range(clusters):
        side = rng.choice((-1, 1))
        mx = rng.uniform(-rx * 0.86, rx * 0.86)
        mt = rng.uniform(0.06, 0.84)
        y, z = _slope_point(side, mt, ey, ez, rz)
        _slope_patch(model, rng.choice((p["moss"], p["moss"], p["leaf_mid"])), rng, side, mx, mt, ey, ez, rz, rng.uniform(0.3, 0.5), pieces=3)
        for clump in range(4):
            x = mx + rng.uniform(-0.5, 0.5)
            y, z = _slope_point(side, min(max(mt + rng.uniform(-0.12, 0.12), 0.02), 0.97), ey, ez, rz)
            for n in range(blades):
                model.blade((x + rng.uniform(-0.06, 0.06), y + rng.uniform(-0.06, 0.06), z + 0.08), rng.uniform(0, math.tau), rng.uniform(0.28, 0.5), rng.uniform(0.04, 0.06), rng.uniform(0.2, 0.55), rng.choice(leaves), segments=2)
            if flowers and clump == 0:
                model.sphere((x, y, z + 0.34), 0.05, p["petal_yellow"], segments=5, rings=3)


def _turf_roof(model, p, rng, rx, ey, ez, rz):
    """Sod over birch bark: a thick green blanket, its pale bark edge held by a timber at the
    eave, the roof of the old north, with grass and small flowers growing out of it."""
    for n, side in enumerate((-1, 1)):
        a, b, c, d = ((-rx, -ey, ez), (rx, -ey, ez), (rx, 0.0, rz), (-rx, 0.0, rz)) if side < 0 else ((rx, ey, ez), (-rx, ey, ez), (-rx, 0.0, rz), (rx, 0.0, rz))
        _roof_plane(model, rng, a, b, c, d, 3, 4, (p["turf"], p["turf"], p["turf_dark"]), thick=0.2, lap=0.05)
        y, z = _slope_point(side, -0.02, ey, ez, rz)
        model.cylinder((-rx - 0.05, y, z + 0.02), (rx + 0.05, y, z + 0.02), 0.075, 0.075, p["bark"], segments=6)
        model.box((0, y * 0.985, z - 0.11), (2 * rx + 0.1, 0.1, 0.12), p["birch_bark"])
    for k in range(int(rx * 7)):
        side = rng.choice((-1, 1))
        y, z = _slope_point(side, rng.uniform(0.05, 0.95), ey, ez, rz)
        model.rock((rng.uniform(-rx * 0.92, rx * 0.92), y, z + 0.14), rng.uniform(0.24, 0.42), rng.choice((p["turf"], p["turf_dark"], p["moss"])), rng, scale=(1.4, 1.15, 0.62), roughness=0.14)
    _growth(model, p, rng, rx, ey, ez, rz, int(rx * 3), blades=4, flowers=True)
    # Barge boards up the gable ends, crossing at the ridge.
    for x in (-rx - 0.02, rx + 0.02):
        for side in (-1, 1):
            y, z = _slope_point(side, -0.03, ey, ez, rz)
            model.cylinder((x, y, z + 0.02), (x, -side * 0.26, rz + 0.3), 0.06, 0.045, p["log_dark"], segments=5)


def _thatch(model, p, rng, rx, ey, ez, rz):
    """A hay roof like the farmhouse's."""
    tones = (p["hay"], p["hay"], p["hay"], p["hay_dark"], p["hay_dark"], p["hay_old"])
    _gable_roof(model, rng, rx, ey, ez, rz, 8, int(rx * 5), tones, thick=0.2)
    model.cylinder((-rx - 0.04, 0, rz + 0.08), (rx + 0.04, 0, rz + 0.08), 0.17, 0.17, p["hay_dark"], segments=6)
    for side in (-1, 1):
        y, z = _slope_point(side, -0.02, ey, ez, rz)
        for k in range(int(rx * 8)):
            x = -rx + 2 * rx * k / (rx * 8) + rng.uniform(-0.05, 0.05)
            long = rng.uniform(0.14, 0.3)
            model.ribbon([(x, y, z + 0.05), (x + rng.uniform(-0.04, 0.04), y + side * 0.05, z - long)], 0.0, [rng.uniform(0.09, 0.15), 0.0], rng.choice(tones))
    for k in range(int(rx * 1.4)):
        x = -rx + 0.5 + k * (2 * rx - 1.0) / max(int(rx * 1.4) - 1, 1)
        for side in (-1, 1):
            model.cylinder((x, side * 0.42, rz - 0.15), (x, -side * 0.2, rz + 0.32), 0.022, 0.018, p["bark"], segments=4)


def _door(model, p, rng, y, base, wide=1.02, tall=1.95, x=0.0, steps=True):
    """A closed door of planks in a timber frame, facing -Y."""
    model.box((x, y + 0.02, base + tall / 2), (wide + 0.1, 0.05, tall + 0.05), p["shadow"])
    for k in range(5):
        at = x - wide / 2 + wide * (k + 0.5) / 5
        model.box((at, y - 0.02, base + tall / 2), (wide / 5 - 0.012, 0.05, tall), rng.choice((p["plank"], p["plank_dark"])))
    for z in (base + 0.35, base + tall - 0.35):
        model.box((x, y - 0.055, z), (wide - 0.06, 0.03, 0.12), p["plank_dark"])
    model.sphere((x + wide * 0.34, y - 0.09, base + tall * 0.5), 0.04, p["iron"], segments=6, rings=4)
    for at in (x - wide / 2 - 0.09, x + wide / 2 + 0.09):
        model.cylinder((at, y - 0.03, base), (at, y - 0.03, base + tall + 0.1), 0.075, 0.07, p["bark"], segments=6)
    model.cylinder((x - wide / 2 - 0.2, y - 0.03, base + tall + 0.1), (x + wide / 2 + 0.2, y - 0.03, base + tall + 0.1), 0.08, 0.08, p["bark"], segments=6)
    if steps:
        model.box((x, y - 0.42, base * 0.75), (1.34, 0.5, base * 0.5), p["stone_mid"])
        model.box((x, y - 0.8, base * 0.3), (1.5, 0.5, base * 0.6), p["stone_dark"])


def _shutter(model, p, rng, at, faces_y, wide=0.78, tall=0.82):
    """A window with its shutters closed. `faces_y` is True on a wall facing -Y or +Y."""
    out = 1.0 if (at[1] if faces_y else at[0]) > 0 else -1.0

    def block(along, up, deep, size_along, size_up, size_deep, mat):
        where = (at[0] + along, at[1] + deep, at[2] + up) if faces_y else (at[0] + deep, at[1] + along, at[2] + up)
        size = (size_along, size_deep, size_up) if faces_y else (size_deep, size_along, size_up)
        model.box(where, size, mat)

    block(0, 0, 0, wide + 0.16, tall + 0.16, 0.05, p["log_dark"])
    for k in range(5):
        block(-wide / 2 + wide * (k + 0.5) / 5, 0, out * 0.04, wide / 5 - 0.012, tall, 0.04, rng.choice((p["plank"], p["plank"], p["plank_dark"])))
    block(0, tall * 0.5 + 0.06, out * 0.05, wide + 0.26, 0.09, 0.08, p["log_dark"])
    block(0, -tall * 0.5 - 0.06, out * 0.05, wide + 0.3, 0.09, 0.1, p["log_dark"])
    block(0, 0.02, out * 0.075, wide + 0.06, 0.07, 0.035, p["plank_dark"])


def _chimney(model, p, x, y, base, top):
    model.box((x, y, (base + top) / 2), (0.62, 0.62, top - base), p["stone_mid"])
    model.box((x, y, top - 0.1), (0.72, 0.72, 0.24), p["stone_dark"])
    model.box((x, y, top + 0.03), (0.42, 0.42, 0.08), p["shadow"])


def _firewood(model, p, rng, x, y0, base, rows=3, count=5):
    for row in range(rows):
        for k in range(count - row):
            y = y0 + 0.1 * row + k * 0.2
            z = base + 0.09 + row * 0.17
            model.cylinder((x, y, z), (x + 0.5 * (1 if x > 0 else -1), y + 0.01, z), 0.09, 0.085, rng.choice((p["wood_drift"], p["log"])), segments=6)


def _house_collision(name, hx, hy, top, rx, ey, ez, rz):
    kit.collision_box(name, (0, 0, top / 2), (2 * hx + 0.4, 2 * hy + 0.4, top))
    _roof_collision(name, rx, ey, ez, rz)


# ---- houses


def village_house_a():
    """A log cottage under a turf roof with flowers in it, a porch over its door and firewood
    at the gable. About 8 m long."""
    p = palette()
    rng = random.Random(201)
    hx, hy, base, top, rx, ey, ez, rz = 3.3, 2.3, 0.45, 2.45, 3.85, 3.05, 2.32, 4.0
    model = kit.Model("VillageHouseA")
    _footing(model, p, rng, hx, hy, base)
    _log_walls(model, p, rng, hx, hy, base, top, rz, ey, ez)
    _turf_roof(model, p, rng, rx, ey, ez, rz)
    wall = hy + 0.16
    _door(model, p, rng, -wall, base, x=-0.7)
    _shutter(model, p, rng, (1.5, -wall, 1.55), True)
    _shutter(model, p, rng, (0.8, wall, 1.55), True)
    _shutter(model, p, rng, (hx + 0.16, 0.0, 1.55), False)
    # A porch of two posts and a little sod roof.
    for x in (-1.5, 0.1):
        model.cylinder((x, -wall - 1.05, 0.0), (x, -wall - 1.05, 2.0), 0.075, 0.065, p["bark"], segments=6)
    model.slab([(-1.8, -wall - 1.3, 1.98), (0.4, -wall - 1.3, 1.98), (0.4, -wall + 0.1, 2.55), (-1.8, -wall + 0.1, 2.55)], 0.12, p["turf_dark"])
    _chimney(model, p, -2.1, 0.5, 2.3, 4.5)
    _firewood(model, p, rng, -hx - 0.32, -1.1, 0.1)
    model.finish()
    _house_collision("VillageHouseA", hx, hy, top, rx, ey, ez, rz)


def village_house_b():
    """A long plank house under a hay roof, boards crossing above its gables in carved beast
    heads, with a bench along the wall. About 10 m long."""
    p = palette()
    rng = random.Random(202)
    hx, hy, base, top, rx, ey, ez, rz = 4.5, 2.4, 0.42, 2.4, 5.0, 3.15, 2.25, 4.75
    model = kit.Model("VillageHouseB")
    _footing(model, p, rng, hx, hy, base)
    _plank_walls(model, p, rng, hx, hy, base, top, rz - 0.15)
    _thatch(model, p, rng, rx, ey, ez, rz)
    _growth(model, p, rng, rx, ey, ez, rz, 6, blades=4)
    wall = hy + 0.04
    _door(model, p, rng, -wall, base, x=0.9)
    for x in (-2.6, -0.7, 2.9):
        _shutter(model, p, rng, (x, -wall, 1.5), True)
    for x in (-2.0, 2.0):
        _shutter(model, p, rng, (x, wall, 1.5), True)
    for x in (-rx - 0.04, rx + 0.04):
        for side in (-1, 1):
            y, z = _slope_point(side, -0.02, ey, ez, rz)
            tip = (x, -side * 0.5, rz + 0.62)
            model.cylinder((x, y, z + 0.1), tip, 0.06, 0.05, p["log_dark"], segments=5)
            model.sphere(tip, 0.1, p["log_dark"], scale=(0.7, 1.5, 0.8), segments=6, rings=4)
    model.box((-1.6, -wall - 0.42, 0.42), (2.4, 0.34, 0.07), p["plank"])
    for x in (-2.6, -0.6):
        model.box((x, -wall - 0.42, 0.2), (0.1, 0.3, 0.4), p["log_dark"])
    _chimney(model, p, 2.6, -0.3, 2.3, 5.2)
    model.finish()
    _house_collision("VillageHouseB", hx, hy, top, rx, ey, ez, rz)


def village_house_c():
    """A small cottage of logs below and boards in the gable, under old hay, with a lean-to
    of firewood against its end. About 7 m long."""
    p = palette()
    rng = random.Random(203)
    hx, hy, base, top, rx, ey, ez, rz = 2.7, 2.1, 0.4, 2.3, 3.2, 2.8, 2.15, 4.45
    model = kit.Model("VillageHouseC")
    _footing(model, p, rng, hx, hy, base)
    _log_walls(model, p, rng, hx, hy, base, top, rz, ey, ez)
    _thatch(model, p, rng, rx, ey, ez, rz)
    _growth(model, p, rng, rx, ey, ez, rz, 9, blades=5)
    wall = hy + 0.16
    _door(model, p, rng, -wall, base, x=0.6)
    _shutter(model, p, rng, (-1.2, -wall, 1.5), True)
    _shutter(model, p, rng, (-hx - 0.16, 0.0, 1.5), False)
    _shutter(model, p, rng, (0.0, wall, 1.5), True)
    # The lean-to.
    for y in (-1.5, 1.5):
        model.cylinder((hx + 1.3, y, 0.0), (hx + 1.3, y, 1.55), 0.06, 0.055, p["bark"], segments=5)
    model.slab([(hx + 1.55, -1.75, 1.5), (hx + 1.55, 1.75, 1.5), (hx + 0.1, 1.75, 2.15), (hx + 0.1, -1.75, 2.15)], 0.08, p["plank_dark"])
    for row in range(5):
        for k in range(9 - row):
            y = -1.2 + 0.14 * row + k * 0.28
            z = 0.14 + row * 0.24
            model.cylinder((hx + 0.35, y, z), (hx + 1.1, y, z), 0.13, 0.125, rng.choice((p["wood_drift"], p["log"], p["log_dark"])), segments=6)
    _chimney(model, p, -1.5, 0.6, 2.3, 4.6)
    model.finish()
    _house_collision("VillageHouseC", hx, hy, top, rx, ey, ez, rz)
    kit.collision_box("VillageHouseCLean", (hx + 0.8, 0, 0.75), (1.1, 3.2, 1.5))


def village_loft():
    """A storehouse raised on stone staddles against the rats, its upper storey jutting out
    over the lower, under a shingle roof with a stair of a split log. About 5.7 m tall."""
    p = palette()
    rng = random.Random(204)
    model = kit.Model("VillageLoft")
    hx, hy = 1.8, 1.55
    for x in (-hx, 0.0, hx):
        for y in (-hy, hy):
            model.cylinder((x, y, 0.0), (x, y, 0.5), 0.25, 0.16, p["stone_mid"], segments=7)
            model.cylinder((x, y, 0.5), (x, y, 0.58), 0.32, 0.32, p["stone_light"], segments=7)
    for y in (-hy, hy):
        model.cylinder((-hx - 0.3, y, 0.7), (hx + 0.3, y, 0.7), 0.13, 0.13, p["log_dark"], segments=6)
    # The lower storey, of logs.
    for k in range(7):
        z = 0.88 + k * 0.25
        for side in (-1, 1):
            model.cylinder((-hx - 0.2, side * hy, z), (hx + 0.2, side * hy, z), 0.13, 0.125, rng.choice((p["log"], p["log_dark"])), segments=6)
            model.cylinder((side * hx, -hy - 0.2, z + 0.12), (side * hx, hy + 0.2, z + 0.12), 0.13, 0.125, rng.choice((p["log"], p["log_dark"])), segments=6)
    model.box((0, 0, 1.75), (2 * hx - 0.06, 2 * hy - 0.06, 1.8), p["log_dark"])
    # The upper storey juts out on beams, in boards.
    for x in (-1.6, -0.5, 0.5, 1.6):
        model.cylinder((x, -hy - 0.65, 2.68), (x, hy + 0.65, 2.68), 0.08, 0.08, p["bark"], segments=5)
    ux, uy = hx + 0.45, hy + 0.55
    _roof_top = 3.95
    model.box((0, 0, 3.3), (2 * ux, 2 * uy, 1.1), p["log_dark"])
    wide = 0.26
    for side in (-1, 1):
        for k in range(int(2 * ux / wide)):
            model.box((-ux + wide * (k + 0.5), side * uy, 3.3), (wide - 0.02, 0.05, 1.14), p[rng.choice(("plank", "plank_dark"))])
        for k in range(int(2 * uy / wide)):
            y = -uy + wide * (k + 0.5)
            high = 5.3 - (5.3 - 3.85) * abs(y) / uy
            model.box((side * ux, y, (2.76 + high) / 2), (0.05, wide - 0.02, high - 2.76), p[rng.choice(("plank", "plank_dark"))])
    rx, ey, ez, rz = ux + 0.4, uy + 0.55, 3.72, 5.6
    _gable_roof(model, rng, rx, ey, ez, rz, 9, int(rx * 5), (p["shingle_a"], p["shingle_b"], p["shingle_b"], p["shingle_c"]), thick=0.09)
    model.cylinder((-rx - 0.04, 0, rz + 0.03), (rx + 0.04, 0, rz + 0.03), 0.08, 0.08, p["tar"], segments=5)
    _growth(model, p, rng, rx, ey, ez, rz, 4, blades=3)
    # Its door and stair: a log with steps cut in it.
    _door(model, p, rng, -hy - 0.17, 0.82, wide=0.9, tall=1.55, x=0.7, steps=False)
    model.cylinder((0.7, -hy - 2.0, 0.2), (0.7, -hy - 0.3, 0.84), 0.2, 0.18, p["log_dark"], segments=6)
    for k in range(4):
        t = (k + 0.5) / 4
        model.box((0.7, -hy - 2.0 + 1.7 * t, 0.2 + 0.64 * t + 0.2), (0.46, 0.2, 0.06), p["plank_dark"])
    model.finish()
    kit.collision_box("VillageLoft", (0, 0, 2.35), (2 * ux + 0.1, 2 * uy + 0.1, 4.7))
    kit.collision_slab("VillageLoftStep", (0.7, -hy - 2.1, 0.0), (0.7, -hy - 0.2, 0.95), 0.6, 0.2)


def village_smithy():
    """A smithy: logs at the back, open at the front under a deep shingled roof on posts,
    with a stone forge and its embers, an anvil on a stump, and a water barrel. About 7 m."""
    p = palette()
    rng = random.Random(205)
    hx, hy = 3.0, 2.3
    model = kit.Model("VillageSmithy")
    rx, ey, ez, rz = hx + 0.5, hy + 0.65, 2.2, 4.25
    # Back and end walls, the front open.
    for k in range(8):
        z = 0.14 + k * 0.26
        model.cylinder((-hx - 0.2, hy, z), (hx + 0.2, hy, z), 0.14, 0.13, rng.choice((p["log"], p["log_dark"])), segments=6)
        for side in (-1, 1):
            model.cylinder((side * hx, -0.2, z + 0.13), (side * hx, hy + 0.2, z + 0.13), 0.14, 0.13, rng.choice((p["log"], p["log_dark"])), segments=6)
    for x in (-hx, -1.0, 1.0, hx):
        model.cylinder((x, -hy, 0.0), (x, -hy, 2.32), 0.11, 0.1, p["bark"], segments=6)
    model.cylinder((-hx - 0.2, -hy, 2.32), (hx + 0.2, -hy, 2.32), 0.12, 0.12, p["log_dark"], segments=6)
    model.cylinder((-hx - 0.2, 0.0, 2.4), (hx + 0.2, 0.0, 2.4), 0.1, 0.1, p["log_dark"], segments=6)
    _gable_roof(model, rng, rx, ey, ez, rz, 8, int(rx * 5), (p["shingle_a"], p["shingle_a"], p["shingle_b"], p["shingle_c"]), thick=0.09)
    for side in (-1, 1):
        for k in range(int(2 * hy / 0.27)):
            y = -hy + 0.27 * (k + 0.5)
            high = rz - (rz - ez) * abs(y) / ey - 0.14
            model.box((side * hx, y, (2.3 + high) / 2), (0.05, 0.25, high - 2.3), p[rng.choice(("plank", "plank_dark"))])
    # The floor, the forge and its chimney.
    model.box((0, 0, 0.03), (2 * hx, 2 * hy, 0.06), p["soil"])
    model.box((-1.7, 1.2, 0.48), (1.6, 1.3, 0.96), p["stone_dark"])
    model.box((-1.7, 1.2, 0.97), (1.3, 1.0, 0.04), p["shadow"])
    for k in range(9):
        model.rock((-1.7 + rng.uniform(-0.45, 0.45), 1.2 + rng.uniform(-0.35, 0.35), 1.0), rng.uniform(0.05, 0.1), p["ember"], rng, scale=(1, 1, 0.5))
    model.box((-1.7, 1.55, 2.7), (1.0, 0.7, 3.5), p["stone_mid"])
    model.box((-1.7, 1.55, 4.55), (1.12, 0.82, 0.22), p["stone_dark"])
    # A pair of bellows, an anvil on a stump, a quench barrel and iron hung on the wall.
    model.lathe([(0.0, 0.0), (0.26, 0.12), (0.2, 0.24), (0.0, 0.3)], p["hide"] if "hide" in p else p["log_dark"], segments=7, centre=(-0.65, 1.4, 0.45))
    model.cylinder((0.5, -0.5, 0.0), (0.5, -0.5, 0.56), 0.3, 0.27, p["log_dark"], segments=8)
    model.box((0.5, -0.5, 0.64), (0.56, 0.2, 0.16), p["iron"])
    model.box((0.84, -0.5, 0.67), (0.24, 0.1, 0.09), p["iron"])
    model.lathe([(0.0, 0.0), (0.28, 0.02), (0.33, 0.35), (0.28, 0.72), (0.22, 0.72), (0.2, 0.62), (0.0, 0.62)], p["plank_dark"], segments=10, centre=(1.9, 0.9, 0.0))
    for k in range(4):
        x = 0.8 + k * 0.36
        model.cylinder((x, hy - 0.2, 1.9), (x, hy - 0.22, 1.1), 0.018, 0.018, p["iron"], segments=4)
    model.finish()
    kit.collision_box("VillageSmithyBack", (0, hy, 1.1), (2 * hx + 0.4, 0.3, 2.2))
    for n, x in enumerate((-hx, hx)):
        kit.collision_box(f"VillageSmithyEnd{n}", (x, hy / 2, 1.1), (0.3, hy + 0.2, 2.2))
    kit.collision_box("VillageSmithyForge", (-1.7, 1.2, 0.5), (1.6, 1.3, 1.0))
    for n, x in enumerate((-hx, -1.0, 1.0, hx)):
        kit.collision_cylinder(f"VillageSmithyPost{n}", (x, -hy, 0), (x, -hy, 2.3), 0.12)
    kit.collision_cylinder("VillageSmithyAnvil", (0.5, -0.5, 0), (0.5, -0.5, 0.75), 0.3)
    _roof_collision("VillageSmithy", rx, ey, ez, rz)


# ---- the church


def _beast(model, p, at, facing, size, droop=0.0):
    """A dragon's neck and head rising from a gable's end and curling out along `facing`."""
    x, y, z = at
    neck = [(x, y, z), (x + facing * size * 0.55, y, z + size * 0.42 - droop * 0.3), (x + facing * size * 1.05, y, z + size * 1.0 - droop), (x + facing * size * 1.55, y, z + size * 1.08 - droop * 1.4)]
    for a, b, ra, rb in zip(neck, neck[1:], (0.11, 0.09, 0.075), (0.09, 0.075, 0.06)):
        model.cylinder(a, b, ra * size * 1.4, rb * size * 1.4, p["tar"], segments=5)
    head = neck[-1]
    model.sphere(head, 0.16 * size, p["tar"], scale=(1.6, 0.8, 0.9), segments=6, rings=4)
    model.cylinder(head, (head[0] + facing * size * 0.45, head[1], head[2] - size * 0.06), 0.12 * size, 0.05 * size, p["tar_light"], segments=5)
    # Jaw, and a crest of sharp plates.
    model.cylinder((head[0], head[1], head[2] - 0.08 * size), (head[0] + facing * size * 0.34, head[1], head[2] - 0.2 * size), 0.07 * size, 0.02 * size, p["tar"], segments=4)
    for k in range(3):
        t = 0.25 + k * 0.25
        px = x + facing * size * 1.55 * t
        pz = z + size * 1.08 * t ** 0.8 - droop * t
        model.cylinder((px, y, pz), (px - facing * 0.14 * size, y, pz + 0.3 * size), 0.05 * size, 0.005, p["tar_light"], segments=4)


def _sun_wheel(model, p, at, radius):
    """A wheel of four spokes in a ring, an old sign of the sun, on a mast."""
    x, y, z = at
    segments = 14
    for k in range(segments):
        a, b = math.tau * k / segments, math.tau * (k + 1) / segments
        model.cylinder((x + math.cos(a) * radius, y, z + math.sin(a) * radius), (x + math.cos(b) * radius, y, z + math.sin(b) * radius), radius * 0.1, radius * 0.1, p["iron"], segments=4, caps=False)
    for k in range(2):
        a = 0.785 + k * math.pi / 2
        model.cylinder((x + math.cos(a) * radius, y, z + math.sin(a) * radius), (x - math.cos(a) * radius, y, z - math.sin(a) * radius), radius * 0.08, radius * 0.08, p["iron"], segments=4)


def _vine(model, p, rng, top, length, away, width=0.1):
    """A strand of creeper hanging down a wall, leaves along it."""
    x, y, z = top
    points = [(x, y, z)]
    for k in range(4):
        x += rng.uniform(-0.12, 0.12)
        y += rng.uniform(-0.12, 0.12)
        z -= length / 4
        points.append((x, y, z))
    tone = rng.choice((p["ivy"], p["ivy"], p["ivy_light"]))
    for a, b in zip(points, points[1:]):
        model.cylinder(a, b, 0.018, 0.014, p["bark"], segments=3, caps=False)
        for n in range(2):
            t = rng.random()
            leaf = (a[0] + (b[0] - a[0]) * t + away[0] * 0.06, a[1] + (b[1] - a[1]) * t + away[1] * 0.06, a[2] + (b[2] - a[2]) * t)
            model.sphere(leaf, width * rng.uniform(0.9, 1.5), tone, scale=(1.0, 1.0, 0.8), segments=4, rings=2)


def _creeper_patch(model, p, rng, at, size, scale=(1.5, 1.2, 0.5)):
    model.rock(at, size, rng.choice((p["ivy"], p["ivy_light"], p["moss"])), rng, scale=scale, roughness=0.22)


def nordic_church():
    """An old stave church in tarred wood, about 15 m tall: steep shingled roofs stepping up
    to a turret and spire, dragon heads on its gables and a sun wheel in place of a cross. The
    forest has been taking it back: moss and creeper over the shingles, a sapling in the skirt
    roof, shingles gone, one dragon sagging."""
    p = palette()
    rng = random.Random(210)
    model = kit.Model("NordicChurch")
    tones = (p["shingle_a"], p["shingle_a"], p["shingle_b"], p["shingle_b"], p["shingle_c"])
    # The sill of stones and the walkway's low outer wall.
    sx, sy = 5.1, 3.5
    model.box((0, 0, 0.2), (2 * sx + 0.3, 2 * sy + 0.3, 0.4), p["stone_dark"])
    for k in range(34):
        side = k % 4
        t = rng.uniform(-1.0, 1.0)
        x, y = {0: (t * sx, -sy - 0.1), 1: (t * sx, sy + 0.1), 2: (-sx - 0.1, t * sy), 3: (sx + 0.1, t * sy)}[side]
        if abs(x) < 1.1 and y < 0:
            continue
        model.rock((x, y, 0.16), rng.uniform(0.2, 0.34), rng.choice((p["stone_mid"], p["stone_dark"], p["moss"])), rng, scale=(1.3, 0.9, 0.8))
    wide = 0.3
    for s in (-1, 1):
        for k in range(int(2 * sx / wide)):
            x = -sx + wide * (k + 0.5)
            if s < 0 and abs(x) < 0.95:
                continue
            model.box((x, s * sy, 1.15), (wide - 0.03, 0.08, 1.5), rng.choice((p["tar"], p["tar"], p["tar_light"])))
        for k in range(int(2 * sy / wide)):
            model.box((s * sx, -sy + wide * (k + 0.5), 1.15), (0.08, wide - 0.03, 1.5), rng.choice((p["tar"], p["tar"], p["tar_light"])))
    # The tall nave of upright staves, with its round corner masts.
    nx, ny, top = 3.4, 2.2, 5.0
    model.box((0, 0, top / 2), (2 * nx - 0.1, 2 * ny - 0.1, top), p["shadow"])
    wide = 0.34
    for s in (-1, 1):
        for k in range(int(2 * nx / wide)):
            model.cylinder((-nx + wide * (k + 0.5), s * ny, 1.8), (-nx + wide * (k + 0.5), s * ny, top), wide * 0.55, wide * 0.5, rng.choice((p["tar"], p["tar_light"], p["tar"])), segments=5)
        for k in range(int(2 * ny / wide)):
            y = -ny + wide * (k + 0.5)
            model.cylinder((s * nx, y, 1.8), (s * nx, y, top + (ny - abs(y)) * 1.25), wide * 0.55, wide * 0.5, rng.choice((p["tar"], p["tar_light"], p["tar"])), segments=5)
    for x, y in ((-nx, -ny), (nx, -ny), (-nx, ny), (nx, ny)):
        model.cylinder((x, y, 0.4), (x, y, top + 0.3), 0.22, 0.19, p["tar_light"], segments=7)
    # A row of round windows, dark, under the eave.
    for s in (-1, 1):
        for x in (-2.2, 0.0, 2.2):
            model.cylinder((x, s * (ny - 0.1), 4.1), (x, s * (ny + 0.26), 4.1), 0.25, 0.25, p["shadow"], segments=8)
            model.cylinder((x, s * (ny + 0.22), 4.1), (x, s * (ny + 0.27), 4.1), 0.32, 0.32, p["carving"], segments=8, caps=False)
    # The skirt roof over the walkway, on all four sides.
    z_low, z_high = 1.72, 3.05
    ox, oy = sx + 0.42, sy + 0.42
    ix, iy = nx - 0.05, ny - 0.05
    _roof_plane(model, rng, (-ox, -oy, z_low), (ox, -oy, z_low), (ix, -iy, z_high), (-ix, -iy, z_high), 5, 14, tones, thick=0.09)
    _roof_plane(model, rng, (ox, oy, z_low), (-ox, oy, z_low), (-ix, iy, z_high), (ix, iy, z_high), 5, 14, tones, thick=0.09)
    _roof_plane(model, rng, (ox, -oy, z_low), (ox, oy, z_low), (ix, iy, z_high), (ix, -iy, z_high), 5, 9, tones, thick=0.09)
    _roof_plane(model, rng, (-ox, oy, z_low), (-ox, -oy, z_low), (-ix, -iy, z_high), (-ix, iy, z_high), 5, 9, tones, thick=0.09)
    # The steep main roof, the ridge along X, with its gables open to the staves.
    rx, ey, ez, rz = nx + 0.45, ny + 0.55, 4.72, 8.35
    _gable_roof(model, rng, rx, ey, ez, rz, 13, 14, tones, thick=0.1)
    model.cylinder((-rx - 0.05, 0, rz + 0.03), (rx + 0.05, 0, rz + 0.03), 0.1, 0.1, p["tar"], segments=5)
    for s in (-1, 1):
        for sign in (-1, 1):
            y, z = _slope_point(sign, -0.02, ey, ez, rz)
            model.cylinder((s * (rx + 0.04), y, z), (s * (rx + 0.04), 0, rz + 0.12), 0.1, 0.08, p["carving"], segments=5)
    # Beasts on the gables: the east one has sagged, its neck gone slack.
    _beast(model, p, (rx + 0.05, 0, rz + 0.05), 1, 1.55)
    _beast(model, p, (-rx - 0.05, 0, rz + 0.05), -1, 1.55, droop=0.75)
    # The turret on the ridge, its small roof, and the spire above.
    tx = 1.25
    model.box((0, 0, 8.55), (2 * tx, 2 * tx, 1.75), p["tar"])
    for s in (-1, 1):
        for k in range(7):
            at = -tx + 2 * tx * (k + 0.5) / 7
            model.box((at, s * tx, 8.6), (0.3, 0.05, 1.7), rng.choice((p["tar"], p["tar_light"])))
            model.box((s * tx, at, 8.6), (0.05, 0.3, 1.7), rng.choice((p["tar"], p["tar_light"])))
        model.box((0, s * (tx + 0.02), 8.9), (0.7, 0.05, 0.75), p["shadow"])
        model.box((s * (tx + 0.02), 0, 8.9), (0.05, 0.7, 0.75), p["shadow"])
    ox, iz, tz = tx + 0.55, 9.3, 10.35
    ix = tx - 0.45
    for a, b, c, d in (
        ((-ox, -ox, iz), (ox, -ox, iz), (ix, -ix, tz), (-ix, -ix, tz)),
        ((ox, ox, iz), (-ox, ox, iz), (-ix, ix, tz), (ix, ix, tz)),
        ((ox, -ox, iz), (ox, ox, iz), (ix, ix, tz), (ix, -ix, tz)),
        ((-ox, ox, iz), (-ox, -ox, iz), (-ix, -ix, tz), (-ix, ix, tz)),
    ):
        _roof_plane(model, rng, a, b, c, d, 3, 5, tones, thick=0.08)
    model.box((0, 0, 10.8), (2 * ix, 2 * ix, 1.0), p["tar"])
    ox, iz, tz = ix + 0.42, 11.2, 14.1
    for a, b, c, d in (
        ((-ox, -ox, iz), (ox, -ox, iz), (0.04, -0.04, tz), (-0.04, -0.04, tz)),
        ((ox, ox, iz), (-ox, ox, iz), (-0.04, 0.04, tz), (0.04, 0.04, tz)),
        ((ox, -ox, iz), (ox, ox, iz), (0.04, 0.04, tz), (0.04, -0.04, tz)),
        ((-ox, ox, iz), (-ox, -ox, iz), (-0.04, -0.04, tz), (-0.04, 0.04, tz)),
    ):
        _roof_plane(model, rng, a, b, c, d, 6, 3, tones, thick=0.07)
    model.cylinder((0, 0, 13.9), (0, 0, 14.9), 0.04, 0.03, p["iron"], segments=5)
    _sun_wheel(model, p, (0, 0, 15.25), 0.42)
    # The porch and its carved door, facing -Y: an arch of knotted beasts, no cross.
    py = -sy - 1.1
    for x in (-1.0, 1.0):
        model.cylinder((x, py - 0.2, 0.0), (x, py - 0.2, 2.1), 0.15, 0.13, p["tar_light"], segments=6)
    model.box((0, py - 0.2, 0.05), (2.6, 2.4, 0.1), p["stone_dark"])
    _roof_plane(model, rng, (-1.5, py - 0.65, 1.95), (0.0, py - 0.65, 3.1), (0.0, -sy + 0.2, 3.1), (-1.5, -sy + 0.2, 1.95), 5, 5, tones, thick=0.08)
    _roof_plane(model, rng, (0.0, py - 0.65, 3.1), (1.5, py - 0.65, 1.95), (1.5, -sy + 0.2, 1.95), (0.0, -sy + 0.2, 3.1), 5, 5, tones, thick=0.08)
    model.box((0, -sy - 0.04, 1.1), (1.5, 0.05, 2.1), p["shadow"])
    for k in range(5):
        model.box((-0.6 + k * 0.3, -sy - 0.09, 1.0), (0.27, 0.05, 1.9), rng.choice((p["plank_dark"], p["log_dark"])))
    for s in (-1, 1):
        points = [(s * 0.85, -sy - 0.13, 0.1), (s * 0.95, -sy - 0.13, 0.75), (s * 0.78, -sy - 0.13, 1.35), (s * 0.95, -sy - 0.13, 1.85), (s * 0.5, -sy - 0.13, 2.4), (0.0, -sy - 0.13, 2.55)]
        for a, b in zip(points, points[1:]):
            model.cylinder(a, b, 0.09, 0.08, p["carving"], segments=5)
        for z in (0.45, 1.05, 1.62):
            model.sphere((s * 0.86, -sy - 0.17, z), 0.11, p["carving"], scale=(1.3, 0.5, 1.0), segments=5, rings=3)
    _sun_wheel(model, p, (0, py - 0.68, 2.65), 0.26)
    # Overgrowth: moss sheets on the shingles, creeper over the walls, bushes at the foot and a
    # birch sapling that took root in the skirt roof.
    for k in range(26):
        side = rng.choice((-1, 1))
        _slope_patch(model, p["moss"] if k % 3 else p["ivy_light"], rng, side, rng.uniform(-rx * 0.85, rx * 0.85), rng.uniform(0.05, 0.9), ey, ez, rz, rng.uniform(0.4, 0.95), lift=0.24)
    for k in range(24):
        t = rng.uniform(0.05, 0.9)
        if k % 2:
            x = rng.choice((-1, 1)) * (sx + 0.42 - t * (sx + 0.42 - nx))
            y = rng.uniform(-sy, sy)
        else:
            x = rng.uniform(-sx, sx)
            y = rng.choice((-1, 1)) * (sy + 0.42 - t * (sy + 0.42 - ny))
        model.rock((x, y, z_low + t * (z_high - z_low) + 0.1), rng.uniform(0.34, 0.62), p["moss"] if k % 3 else p["ivy"], rng, scale=(1.3, 1.1, 0.42), roughness=0.16)
    _growth(model, p, rng, rx, ey, ez, rz, 9, blades=4)
    for k in range(20):
        side = k % 4
        t = rng.uniform(-0.95, 0.95)
        if side < 2:
            x, y = t * sx, (-1 if side == 0 else 1) * (sy + 0.1)
            if abs(x) < 1.3 and y < 0:
                continue
            away = (0.0, 1.0 if y > 0 else -1.0)
        else:
            x, y = (-1 if side == 2 else 1) * (sx + 0.1), t * sy
            away = (1.0 if x > 0 else -1.0, 0.0)
        _vine(model, p, rng, (x, y, rng.uniform(1.7, 2.1)), rng.uniform(1.0, 1.8), away)
    for s in (-1, 1):
        for k in range(5):
            _vine(model, p, rng, (rng.uniform(-rx * 0.7, rx * 0.7), s * (ey + 0.02), ez + 0.05), rng.uniform(0.7, 1.4), (0.0, s))
    for k in range(13):
        side = k % 4
        t = rng.uniform(-1.0, 1.0)
        x, y = {0: (t * sx, -sy - 0.62), 1: (t * sx, sy + 0.62), 2: (-sx - 0.62, t * sy), 3: (sx + 0.62, t * sy)}[side]
        if abs(x) < 1.6 and y < 0:
            continue
        model.rock((x, y, 0.32), rng.uniform(0.42, 0.7), rng.choice((p["leaf_deep"], p["ivy"], p["leaf_mid"])), rng, scale=(1.35, 1.0, 1.05), subdivisions=1, roughness=0.22)
    # The sapling.
    sapling = (3.5, 3.0, 2.0)
    model.cylinder(sapling, (3.65, 3.05, 4.3), 0.07, 0.025, p["birch_bark"], segments=5)
    for k in range(5):
        a = rng.uniform(0, math.tau)
        model.rock((3.65 + math.cos(a) * 0.4, 3.05 + math.sin(a) * 0.4, rng.uniform(3.5, 4.6)), rng.uniform(0.34, 0.48), p["leaf_light"], rng, scale=(1, 1, 0.82))
    # Where shingles have gone, on the roof's west end.
    for x, t_at in ((-2.35, 0.55), (-2.7, 0.24), (1.9, 0.72)):
        _slope_patch(model, p["shadow"], rng, -1, x, t_at, ey, ez, rz, 0.34, pieces=2, lift=0.25)
    model.finish()
    kit.collision_box("NordicChurchNave", (0, 0, 2.5), (2 * nx + 0.2, 2 * ny + 0.2, 5.0))
    kit.collision_box("NordicChurchSkirt", (0, 0, 1.15), (2 * sx + 0.3, 2 * sy + 0.3, 2.3))
    kit.collision_box("NordicChurchTurret", (0, 0, 9.3), (2 * tx + 0.2, 2 * tx + 0.2, 3.2))
    _roof_collision("NordicChurch", rx, ey, ez, rz)
    for x in (-1.0, 1.0):
        kit.collision_cylinder(f"NordicChurchPorch{x:+.0f}", (x, py - 0.2, 0), (x, py - 0.2, 2.1), 0.17)


# ---- the farm


def farm_shed():
    """A small plank shed under a turf-patched lean roof, its door ajar on the dark, with a
    scythe and a rake against the wall. About 3.3 m long."""
    p = palette()
    rng = random.Random(220)
    model = kit.Model("FarmShed")
    hx, hy, base = 1.6, 1.25, 0.14
    high, low = 2.5, 1.85
    model.box((0, 0, base / 2), (2 * hx + 0.2, 2 * hy + 0.2, base), p["stone_dark"])
    model.box((0, 0, (base + low) / 2), (2 * hx - 0.04, 2 * hy - 0.04, low - base), p["log_dark"])
    wide = 0.25
    for side in (-1, 1):
        z_top = high if side < 0 else low
        for k in range(int(2 * hx / wide)):
            x = -hx + wide * (k + 0.5)
            if side < 0 and abs(x - 0.55) < 0.48:
                continue
            model.box((x, side * hy, (base + z_top) / 2), (wide - 0.02, 0.05, z_top - base), p[rng.choice(("plank", "plank_dark"))])
        for k in range(int(2 * hy / wide)):
            y = -hy + wide * (k + 0.5)
            here = high + (low - high) * (y + hy) / (2 * hy)
            model.box((side * hx, y, (base + here) / 2), (0.05, wide - 0.02, here - base), p[rng.choice(("plank", "plank_dark"))])
    for x, y in ((-hx, -hy), (hx, -hy), (-hx, hy), (hx, hy)):
        model.cylinder((x, y, 0), (x, y, high if y < 0 else low), 0.075, 0.065, p["bark"], segments=5)
    # The door stands ajar on the dark inside.
    model.box((0.55, -hy + 0.02, (base + high - 0.2) / 2 + 0.05), (0.96, 0.03, high - 0.3), p["shadow"])
    door = 0.92
    model.box((0.1 - 0.1, -hy - 0.38, 1.05), (0.06, door * 0.86, 1.85), p["plank_dark"], rotation_z=0.55)
    # The lean roof.
    rx = hx + 0.35
    _roof_plane(model, rng, (rx, hy + 0.32, low - 0.08), (-rx, hy + 0.32, low - 0.08), (-rx, -hy - 0.32, high + 0.12), (rx, -hy - 0.32, high + 0.12), 5, 8, (p["plank_dark"], p["shingle_b"], p["shingle_c"]), thick=0.07)
    for k in range(4):
        model.rock((rng.uniform(-rx * 0.8, rx * 0.8), rng.uniform(-hy * 0.8, hy * 0.8), 2.3), rng.uniform(0.25, 0.45), rng.choice((p["moss"], p["turf"])), rng, scale=(1.4, 1.1, 0.26), roughness=0.14)
    # The scythe, the rake and a bucket.
    model.cylinder((-1.0, -hy - 0.5, 0.0), (-0.92, -hy - 0.08, 1.75), 0.022, 0.018, p["wood_drift"], segments=4)
    model.slab([(-0.9, -hy - 0.1, 1.72), (-0.45, -hy - 0.1, 1.5), (-0.45, -hy - 0.06, 1.5), (-0.9, -hy - 0.06, 1.8)], 0.015, p["iron"])
    model.cylinder((-0.3, -hy - 0.42, 0.0), (-0.26, -hy - 0.08, 1.55), 0.018, 0.016, p["wood_drift"], segments=4)
    model.box((-0.26, -hy - 0.1, 1.55), (0.42, 0.05, 0.05), p["plank_dark"])
    model.lathe([(0.0, 0.0), (0.14, 0.01), (0.17, 0.26), (0.15, 0.26), (0.13, 0.05), (0.0, 0.05)], p["plank"], segments=8, centre=(-1.55, -hy - 0.36, 0.0))
    model.finish()
    kit.collision_box("FarmShed", (0, 0, 1.2), (2 * hx + 0.1, 2 * hy + 0.1, 2.4))


def water_trough():
    """A trough hollowed from one log, on two blocks, with dark water in it. About 2 m."""
    p = palette()
    model = kit.Model("WaterTrough")
    for x in (-0.65, 0.65):
        model.box((x, 0, 0.1), (0.2, 0.62, 0.2), p["log_dark"])
    model.cylinder((-1.0, 0, 0.38), (1.0, 0, 0.38), 0.25, 0.24, p["log"], segments=8)
    model.box((0, 0, 0.58), (1.84, 0.34, 0.04), p["water_dark"])
    model.finish()
    kit.collision_box("WaterTrough", (0, 0, 0.3), (2.0, 0.56, 0.6))


def crop_patch():
    """A clump of ripening barley for the farm's strips: pale stalks and heavy heads."""
    p = palette()
    rng = random.Random(222)
    model = kit.Model("CropPatch")
    for k in range(13):
        base = (rng.uniform(-0.28, 0.28), rng.uniform(-0.28, 0.28), 0.0)
        tall = rng.uniform(0.62, 0.86)
        angle = rng.uniform(0, math.tau)
        model.blade(base, angle, tall, 0.04, 0.22, p["hay_dark"] if k % 3 else p["leaf_light"], segments=2)
    for k in range(6):
        angle = rng.uniform(0, math.tau)
        model.sphere((math.cos(angle) * 0.22, math.sin(angle) * 0.22, rng.uniform(0.64, 0.8)), 0.04, p["hay"], scale=(0.7, 0.7, 1.7), segments=4, rings=2)
    model.finish()


# ---- about the village


def village_well():
    """The village's well: a ring of stone, a roof of shingles on two posts, a windlass, a
    rope and a bucket. About 3 m tall."""
    p = palette()
    rng = random.Random(230)
    model = kit.Model("VillageWell")
    for ring in range(3):
        count = 11
        z = 0.15 + ring * 0.22
        for k in range(count):
            a = math.tau * (k + ring * 0.5) / count
            model.rock((math.cos(a) * 0.86, math.sin(a) * 0.86, z), rng.uniform(0.17, 0.23), rng.choice((p["stone_mid"], p["stone_dark"], p["stone_light"])), rng, scale=(1.05, 0.85, 0.72), roughness=0.14)
    model.cylinder((0, 0, 0.05), (0, 0, 0.5), 0.72, 0.72, p["shadow"], segments=10)
    model.cylinder((0, 0, 0.5), (0, 0, 0.52), 0.68, 0.68, p["water_dark"], segments=10)
    for side in (-1, 1):
        model.cylinder((side * 1.05, 0, 0.0), (side * 1.02, 0, 2.28), 0.09, 0.08, p["log_dark"], segments=6)
    model.cylinder((-1.2, 0, 1.46), (1.2, 0, 1.46), 0.075, 0.075, p["log"], segments=6)
    model.cylinder((1.2, 0, 1.46), (1.25, 0.3, 1.46), 0.025, 0.025, p["iron"], segments=4)
    model.cylinder((1.25, 0.3, 1.46), (1.25, 0.3, 1.22), 0.025, 0.025, p["iron"], segments=4)
    model.cylinder((0, 0, 1.46), (0, 0, 0.92), 0.012, 0.012, p["hay_dark"], segments=3)
    model.lathe([(0.0, 0.66), (0.13, 0.66), (0.17, 0.92), (0.15, 0.92), (0.0, 0.7)], p["plank_dark"], segments=8)
    _gable_roof(model, rng, 1.4, 1.05, 2.0, 2.92, 4, 5, (p["shingle_a"], p["shingle_b"], p["shingle_c"]), thick=0.07)
    model.cylinder((-1.45, 0, 2.94), (1.45, 0, 2.94), 0.07, 0.06, p["tar"], segments=5)
    model.rock((0.5, -0.4, 2.45), 0.3, p["moss"], rng, scale=(1.4, 1.0, 0.25), roughness=0.12)
    model.finish()
    kit.collision_cylinder("VillageWell", (0, 0, 0), (0, 0, 0.75), 1.02, segments=10)
    _roof_collision("VillageWell", 1.4, 1.05, 2.0, 2.92)


def rune_stone():
    """A tall standing stone carved with a ribbon of runes, about 2.5 m, leaning a little,
    lichen on its shoulder. They stand in pairs on the way up to the church."""
    p = palette()
    rng = random.Random(231)
    model = kit.Model("RuneStone")
    # A tall slab narrowing to its shoulder, of lumps stacked on one another.
    for z, wide, deep, tone in ((0.42, 1.12, 0.56, "stone_dark"), (1.2, 1.02, 0.5, "stone_mid"), (1.92, 0.76, 0.42, "stone_mid")):
        model.rock((z * 0.03, 0.0, z), 0.5, p[tone], rng, scale=(wide, deep, 1.0), subdivisions=2, roughness=0.08)
    model.rock((0.06, 0.0, 2.3), 0.3, p["stone_mid"], rng, scale=(1.1, 0.7, 0.8), roughness=0.12)
    # The band of runes and its ring, on the front.
    y = -0.28
    for k in range(9):
        z = 0.52 + k * 0.19
        x = 0.28 - z * 0.05
        model.box((-x, y, z), (0.03, 0.02, 0.15), p["rune"])
        model.box((x, y, z), (0.03, 0.02, 0.15), p["rune"])
        model.box((-x + 0.09, y, z + rng.uniform(-0.03, 0.03)), (0.09, 0.02, 0.025), p["rune"], rotation_z=0.0)
        model.box((x - 0.09, y, z + rng.uniform(-0.03, 0.03)), (0.09, 0.02, 0.025), p["rune"])
    segments = 12
    for k in range(segments):
        a, b = math.tau * k / segments, math.tau * (k + 1) / segments
        model.cylinder((0.05 + math.cos(a) * 0.14, y, 1.3 + math.sin(a) * 0.14), (0.05 + math.cos(b) * 0.14, y, 1.3 + math.sin(b) * 0.14), 0.014, 0.014, p["rune"], segments=3, caps=False)
    model.rock((-0.22, 0.05, 1.95), 0.28, p["moss"], rng, scale=(1.3, 0.8, 0.5), roughness=0.14)
    model.rock((0.3, -0.12, 0.2), 0.34, p["moss"], rng, scale=(1.3, 0.8, 0.4), roughness=0.14)
    model.finish()
    kit.collision_box("RuneStone", (0, 0, 1.2), (1.2, 0.6, 2.4))


def market_stall():
    """A stall on the square: a plank counter under a striped awning, baskets and a crate. About
    3 m long."""
    p = palette()
    rng = random.Random(232)
    model = kit.Model("MarketStall")
    for x in (-1.45, 1.45):
        for y in (-0.65, 0.65):
            model.cylinder((x, y, 0.0), (x, y, 2.3 if y > 0 else 1.95), 0.055, 0.05, p["bark"], segments=5)
    model.box((0, -0.25, 0.86), (2.9, 0.9, 0.06), p["plank"])
    for x in (-1.2, -0.6, 0.0, 0.6, 1.2):
        model.box((x, -0.68, 0.44), (0.56, 0.04, 0.8), p["plank_dark"])
    stripes = 8
    for k in range(stripes):
        x0 = -1.65 + 3.3 * k / stripes
        x1 = -1.65 + 3.3 * (k + 1) / stripes
        tone = p["cloth"] if k % 2 else p["cloth_pale"]
        model.slab([(x0, -1.0, 1.86), (x1, -1.0, 1.86), (x1, 0.8, 2.36), (x0, 0.8, 2.36)], 0.02, tone)
        model.box(((x0 + x1) / 2, -1.0, 1.75), (x1 - x0 - 0.01, 0.015, 0.2), tone)
    for x, tone in ((-0.9, "petal_red"), (0.1, "leaf_light"), (0.95, "hay")):
        model.lathe([(0.0, 0.89), (0.2, 0.9), (0.27, 1.04), (0.24, 1.05), (0.0, 0.96)], p["plank"], segments=8, centre=(x, -0.2, 0))
        for n in range(5):
            model.sphere((x + rng.uniform(-0.13, 0.13), -0.2 + rng.uniform(-0.13, 0.13), 1.04), 0.07, p[tone], segments=5, rings=3)
    model.box((1.0, 0.4, 0.26), (0.6, 0.6, 0.5), p["plank_dark"], rotation_z=0.3)
    model.finish()
    kit.collision_box("MarketStall", (0, -0.25, 0.46), (3.0, 0.95, 0.92))
    for n, x in enumerate((-1.45, 1.45)):
        kit.collision_cylinder(f"MarketStallPost{n}", (x, 0.65, 0), (x, 0.65, 2.3), 0.07)


def hand_cart():
    """A two-wheeled hand cart tipped forward on its shafts, sacks in it. About 2.8 m."""
    p = palette()
    rng = random.Random(233)
    model = kit.Model("HandCart")
    for side in (-1, 1):
        y = side * 0.72
        segments = 12
        for k in range(segments):
            a, b = math.tau * k / segments, math.tau * (k + 1) / segments
            model.cylinder((math.cos(a) * 0.52, y, 0.54 + math.sin(a) * 0.52), (math.cos(b) * 0.52, y, 0.54 + math.sin(b) * 0.52), 0.05, 0.05, p["log_dark"], segments=4, caps=False)
        for k in range(4):
            a = math.pi * k / 4
            model.cylinder((math.cos(a) * 0.5, y, 0.54 + math.sin(a) * 0.5), (-math.cos(a) * 0.5, y, 0.54 - math.sin(a) * 0.5), 0.026, 0.026, p["plank_dark"], segments=4)
    model.cylinder((0, -0.8, 0.54), (0, 0.8, 0.54), 0.05, 0.05, p["log_dark"], segments=6)
    tilt = 0.34
    def lift(x):
        return 0.76 - x * tilt
    for y in (-0.56, -0.28, 0.0, 0.28, 0.56):
        model.slab([(-0.75, y - 0.13, lift(-0.75)), (0.8, y - 0.13, lift(0.8)), (0.8, y + 0.13, lift(0.8)), (-0.75, y + 0.13, lift(-0.75))], 0.04, p["plank"])
    for side in (-1, 1):
        model.cylinder((-0.8, side * 0.45, lift(-0.8)), (1.95, side * 0.34, 0.04), 0.04, 0.03, p["log"], segments=5)
        model.slab([(-0.75, side * 0.68 - 0.03, lift(-0.75) + 0.34), (0.8, side * 0.68 - 0.03, lift(0.8) + 0.34), (0.8, side * 0.68 + 0.03, lift(0.8) + 0.34), (-0.75, side * 0.68 + 0.03, lift(-0.75) + 0.34)], 0.34, p["plank_dark"])
    for x, y in ((-0.35, -0.22), (0.2, 0.28), (-0.3, 0.32)):
        model.rock((x, y, lift(x) + 0.16), 0.26, p["cloth_pale"], rng, scale=(1.2, 0.95, 0.85), roughness=0.08)
    model.finish()
    kit.collision_box("HandCart", (0.1, 0, 0.6), (1.7, 1.5, 1.2))


def garden_bed():
    """A kitchen garden behind a low wattle edge: rows of leeks, cabbages and herbs in dark
    soil. About 3 x 2 m."""
    p = palette()
    rng = random.Random(234)
    model = kit.Model("GardenBed")
    model.rock((0, 0, 0.03), 1.0, p["soil"], rng, scale=(1.5, 0.95, 0.09), subdivisions=2, roughness=0.06)
    for k in range(10):
        x = -1.4 + k * 0.31
        for y in (-0.95, 0.95):
            model.cylinder((x, y, 0.0), (x, y, 0.3), 0.022, 0.018, p["bark"], segments=4)
    for side in (-1, 1):
        model.cylinder((-1.45, side * 0.95, 0.22), (1.45, side * 0.95, 0.22), 0.02, 0.02, p["wood_drift"], segments=4)
    for row, y in enumerate((-0.55, 0.0, 0.55)):
        for k in range(8):
            x = -1.15 + k * 0.33 + rng.uniform(-0.03, 0.03)
            if row == 1:
                model.rock((x, y, 0.15), 0.14, p["leaf_light"], rng, scale=(1.0, 1.0, 0.72), roughness=0.14)
            elif row == 0:
                for n in range(3):
                    model.blade((x, y, 0.05), rng.uniform(0, math.tau), 0.36, 0.05, 0.3, p["leaf_mid"], segments=2)
            else:
                for n in range(3):
                    model.blade((x, y, 0.05), rng.uniform(0, math.tau), 0.26, 0.05, 0.5, p["leaf_deep"], segments=2)
                model.sphere((x, y, 0.28), 0.04, p["petal_violet"], segments=4, rings=2)
    model.finish()


def village_bench():
    """A plank laid across two stumps, worn pale in the middle. About 1.8 m."""
    p = palette()
    model = kit.Model("VillageBench")
    for x in (-0.65, 0.65):
        model.cylinder((x, 0, 0.0), (x, 0, 0.42), 0.17, 0.15, p["log_dark"], segments=7)
    model.box((0, 0, 0.45), (1.84, 0.34, 0.07), p["wood_drift"])
    model.finish()
    kit.collision_box("VillageBench", (0, 0, 0.24), (1.8, 0.36, 0.48))


def clothes_line():
    """A line between two forked poles with a few things drying on it. About 4 m."""
    p = palette()
    rng = random.Random(236)
    model = kit.Model("ClothesLine")
    for x in (-2.0, 2.0):
        model.cylinder((x, 0, 0), (x, 0, 2.0), 0.05, 0.04, p["bark"], segments=5)
        for s in (-1, 1):
            model.cylinder((x, 0, 1.92), (x, s * 0.13, 2.2), 0.024, 0.016, p["bark"], segments=4)
    model.cylinder((-2.0, 0, 2.0), (0, 0, 1.86), 0.009, 0.009, p["hay_dark"], segments=3)
    model.cylinder((0, 0, 1.86), (2.0, 0, 2.0), 0.009, 0.009, p["hay_dark"], segments=3)
    for x, wide, tall, tone in ((-1.2, 0.72, 0.95, "cloth_pale"), (-0.2, 0.55, 0.7, "cloth"), (0.72, 0.8, 1.05, "cloth_pale")):
        z = 1.86 + 0.14 * abs(x) / 2.0
        model.slab([(x - wide / 2, -0.008, z), (x + wide / 2, -0.008, z), (x + wide / 2, 0.008, z), (x - wide / 2, 0.008, z)], tall, p[tone])
    model.finish()
    kit.collision_cylinder("ClothesLineA", (-2.0, 0, 0), (-2.0, 0, 2.0), 0.08)
    kit.collision_cylinder("ClothesLineB", (2.0, 0, 0), (2.0, 0, 2.0), 0.08)


BUILDERS = {fn.__name__: fn for fn in (
    village_house_a, village_house_b, village_house_c, village_loft, village_smithy, nordic_church,
    farm_shed, water_trough, crop_patch, village_well, rune_stone, market_stall, hand_cart, garden_bed,
    village_bench, clothes_line,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
