"""The shoreside family: the wet banks of R1's river below Aiwyk, where the village fishes and where
old ships ended. A clinker longship stranded on boulders, the ribs of an older one, boats, a jetty,
racks of drying fish and nets, a smoke hut, the tools left lying, and what grows and gathers on wet
dirt. It's built from the village family's wood, tar, shingle and dragon heads, so the ships are
plainly the work of the people who raised the church. Each asset is a small script in
tools/blender/assets/ that calls make(<slug>). Colours are sRGB. The kinds and shapes are
placeholders until the author says otherwise (docs/world/regions/R1/art.md).
"""
import math
import random

import homestead
import kit
import village


def palette():
    """The homestead palette and what the shore adds."""
    p = homestead.palette()
    m = kit.material
    p.update({
        "wet_stone": m("WetStone", (0.23, 0.25, 0.26), roughness=0.35),
        "wet_stone_light": m("WetStoneLight", (0.33, 0.35, 0.35), roughness=0.45),
        "algae": m("Algae", (0.24, 0.33, 0.16), roughness=0.6),
        "silt": m("Silt", (0.29, 0.23, 0.16), roughness=0.9),
        "sea_wood": m("SeaWood", (0.45, 0.42, 0.36), roughness=0.95),
        "sea_wood_dark": m("SeaWoodDark", (0.27, 0.24, 0.20), roughness=0.95),
        "net": m("Net", (0.58, 0.53, 0.40), roughness=1.0),
        "net_dark": m("NetDark", (0.36, 0.33, 0.25), roughness=1.0),
        "rope": m("Rope", (0.55, 0.46, 0.30), roughness=1.0),
        "sail": m("Sail", (0.52, 0.34, 0.25), roughness=1.0),
        "sail_pale": m("SailPale", (0.66, 0.60, 0.47), roughness=1.0),
        "fish": m("Fish", (0.62, 0.66, 0.66), roughness=0.4),
        "fish_dry": m("FishDry", (0.66, 0.56, 0.38), roughness=0.8),
        "bone": m("Bone", (0.82, 0.79, 0.68), roughness=0.8),
        "steel": m("Steel", (0.46, 0.47, 0.48), roughness=0.4, metallic=0.6),
        "cork": m("Cork", (0.70, 0.55, 0.33), roughness=1.0),
        "butterbur": m("Butterbur", (0.26, 0.42, 0.20), roughness=0.75),
        "rush": m("Rush", (0.30, 0.42, 0.20), roughness=0.85),
        "rush_tip": m("RushTip", (0.50, 0.37, 0.20), roughness=0.9),
    })
    return p


# ---- hulls


def _skin(model, mat, a, b, c, d, thick, centre):
    """A plank from four corners, thick toward the hull's middle, facing away from it."""
    ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    vx, vy, vz = d[0] - a[0], d[1] - a[1], d[2] - a[2]
    n = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
    size = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2)
    if size < 1e-6:
        return
    n = (n[0] / size, n[1] / size, n[2] / size)
    middle = [(a[k] + c[k]) / 2 for k in range(3)]
    outward = sum((middle[k] - centre[k]) * n[k] for k in range(3))
    if outward < 0:
        a, b, c, d = d, c, b, a
        n = (-n[0], -n[1], -n[2])
    outer = [model.bm.verts.new(q) for q in (a, b, c, d)]
    inner = [model.bm.verts.new((q[0] - n[0] * thick, q[1] - n[1] * thick, q[2] - n[2] * thick)) for q in (a, b, c, d)]
    model.bm.faces.new(outer)
    model.bm.faces.new(list(reversed(inner)))
    for k in range(4):
        after = (k + 1) % 4
        model.bm.faces.new((outer[k], inner[k], inner[after], outer[after]))
    model._paint(outer + inner, mat)


class Hull:
    """A clinker hull along X, its middle at x = 0. `place` turns its points to where the wreck
    lies; left as it is, the keel runs along z = 0."""

    def __init__(self, length, beam, depth, rise, place=None, strakes=6, stations=14):
        self.length, self.beam, self.depth, self.rise = length, beam, depth, rise
        self.place = place or (lambda q: q)
        self.strakes, self.stations = strakes, stations

    def local(self, t, s, side):
        """t runs 0 to 1 stem to stern, s 0 to 1 keel to gunwale."""
        bend = abs(2.0 * t - 1.0)
        wide = self.beam * (1.0 - bend ** 2.3)
        top = self.depth + self.rise * bend ** 3.0
        keel = 0.32 * self.depth * bend ** 2.5
        return ((t - 0.5) * self.length, side * wide * math.sin(s * math.pi / 2) ** 0.8, keel + (top - keel) * (1.0 - math.cos(s * math.pi / 2)) ** 0.85)

    def at(self, t, s, side):
        return self.place(self.local(t, s, side))

    def planks(self, model, tones, rng, skip=None, thick=0.05):
        centre = self.place((0.0, 0.0, self.depth * 0.8))
        for side in (-1, 1):
            for strake in range(self.strakes):
                # A plank runs long in one tone, and now and then a mended one is let in.
                tone = rng.choice(tones)
                s0, s1 = strake / self.strakes, (strake + 1.12) / self.strakes
                for k in range(self.stations):
                    if skip and skip(k, strake, side):
                        continue
                    t0, t1 = k / self.stations, (k + 1) / self.stations
                    # Each strake laps out over the one beneath: clinker.
                    out = 1.05
                    a, b = self.local(t0, s0, side), self.local(t1, s0, side)
                    c, d = self.local(t1, min(s1, 1.0), side), self.local(t0, min(s1, 1.0), side)
                    a, b = (a[0], a[1] * out, a[2]), (b[0], b[1] * out, b[2])
                    _skin(model, rng.choice(tones) if rng.random() < 0.12 else tone, self.place(a), self.place(b), self.place(c), self.place(d), thick, centre)

    def ribs(self, model, mat, rng, every=2, skip=None, radius=0.05):
        for k in range(1, self.stations, every):
            if skip and skip(k):
                continue
            t = k / self.stations
            for side in (-1, 1):
                points = [self.at(t, n / 4, side) for n in range(5)]
                for a, b in zip(points, points[1:]):
                    model.cylinder(a, b, radius, radius * 0.9, mat, segments=4)

    def keel(self, model, mat, radius=0.09):
        points = [self.at(k / self.stations, 0.0, 1) for k in range(self.stations + 1)]
        for a, b in zip(points, points[1:]):
            model.cylinder(a, b, radius, radius, mat, segments=5)

    def stem(self, model, mat, end, radius=0.08, curl=0.7):
        """The post rising from the keel at one end (0 or 1), curling over at its top."""
        t = float(end)
        sign = -1.0 if end == 0 else 1.0
        top = self.local(t, 1.0, 1)
        points = [(top[0], 0.0, self.depth * 0.32), (top[0] + sign * 0.14, 0.0, top[2] * 0.6), (top[0] + sign * 0.3, 0.0, top[2] + 0.16), (top[0] + sign * (0.3 + curl * 0.8), 0.0, top[2] + curl)]
        placed = [self.place(q) for q in points]
        for a, b in zip(placed, placed[1:]):
            model.cylinder(a, b, radius, radius * 0.82, mat, segments=5)
        return placed[-1]


def _turn(roll, pitch, lift, x=0.0, y=0.0):
    """Heels a point by roll about X, tips it by pitch about Y, then sets it down."""
    cr, sr, cp, sp = math.cos(roll), math.sin(roll), math.cos(pitch), math.sin(pitch)

    def place(q):
        y1, z1 = q[1] * cr - q[2] * sr, q[1] * sr + q[2] * cr
        x2, z2 = q[0] * cp + z1 * sp, -q[0] * sp + z1 * cp
        return (x2 + x, y1 + y, z2 + lift)
    return place


def _wet_rock(model, p, rng, at, radius, scale=(1.2, 1.0, 0.8), algae=True):
    model.rock(at, radius, rng.choice((p["wet_stone"], p["wet_stone"], p["wet_stone_light"])), rng, scale=scale, subdivisions=2, roughness=0.16)
    if algae:
        top = at[2] + radius * scale[2] * 0.68
        model.rock((at[0] + rng.uniform(-0.2, 0.2) * radius, at[1] + rng.uniform(-0.2, 0.2) * radius, top), radius * 0.62, p["algae"], rng, scale=(scale[0], scale[1], 0.28), roughness=0.12)


def _dragon(model, p, at, facing, size):
    """A carved head on the end of a stem post, looking along facing on X. Built like the
    church's beasts."""
    x, y, z = at
    model.sphere((x, y, z), 0.16 * size, p["tar"], scale=(1.7, 0.75, 0.9), segments=6, rings=4)
    model.cylinder((x, y, z), (x + facing * size * 0.5, y, z - size * 0.05), 0.12 * size, 0.045 * size, p["tar_light"], segments=5)
    model.cylinder((x, y, z - 0.09 * size), (x + facing * size * 0.36, y, z - 0.22 * size), 0.07 * size, 0.02 * size, p["tar"], segments=4)
    for k in range(3):
        model.cylinder((x - facing * k * 0.12 * size, y, z + 0.1 * size), (x - facing * (k * 0.12 + 0.14) * size, y, z + 0.42 * size), 0.05 * size, 0.005, p["tar_light"], segments=4)


def ship_on_boulders():
    """A clinker longship thrown up on a heap of boulders and left there: heeled over, bow in the
    air, a hole stove in its low side with the ribs showing, the mast snapped and the torn sail
    hanging from the fallen yard, a dragon still on the stem. About 14 m long."""
    p = palette()
    rng = random.Random(401)
    model = kit.Model("ShipOnBoulders")
    roll, pitch, lift = math.radians(-13), math.radians(-7), 1.5
    place = _turn(roll, pitch, lift)
    hull = Hull(12.6, 1.95, 1.5, 1.5, place, strakes=7, stations=20)
    hole = lambda k, strake, side: side < 0 and 8 <= k <= 11 and 1 <= strake <= 4 and not (k == 11 and strake == 4)
    tones = (p["tar"], p["tar"], p["tar_light"], p["sea_wood_dark"], p["sea_wood_dark"])
    hull.planks(model, tones, rng, skip=hole)
    hull.keel(model, p["tar"])
    hull.ribs(model, p["sea_wood_dark"], rng)
    # The dark of the hold behind the hole, and the bottom boards.
    model.box(place((0.0, 0.0, 0.46)), (10.0, 2.0, 0.05), p["room"])
    # The stem with its dragon, and the stern's plain curl.
    head = hull.stem(model, p["tar"], 1, curl=0.75)
    _dragon(model, p, head, 1, 1.4)
    hull.stem(model, p["tar"], 0, curl=0.5)
    # Thwarts, some gone.
    for k in (2, 3, 5, 7, 8, 10):
        x = (k / 11 - 0.5) * 9.4
        wide = 1.75 * (1.0 - abs(2.0 * (k / 11) - 1.0) ** 2.3)
        a, b = place((x, -wide, 1.05)), place((x, wide, 1.05))
        model.cylinder(a, b, 0.05, 0.05, p["sea_wood"], segments=4)
    # The snapped mast, the fallen yard across the gunwale, the sail hanging in rags.
    foot, stump = place((0.4, 0.0, 0.5)), place((0.5, 0.05, 2.75))
    model.cylinder(foot, stump, 0.14, 0.12, p["tar_light"], segments=7)
    for k in range(5):
        a = k * math.tau / 5
        model.cylinder(stump, (stump[0] + math.cos(a) * 0.14, stump[1] + math.sin(a) * 0.14, stump[2] + rng.uniform(0.15, 0.4)), 0.05, 0.005, p["sea_wood"], segments=3)
    yard_a = place((-3.1, -3.2, 1.42))
    yard_b = place((2.7, 1.6, 2.1))
    model.cylinder(yard_a, yard_b, 0.075, 0.06, p["sea_wood_dark"], segments=6)
    for k in range(7):
        t0, t1 = k / 7, (k + 0.82) / 7
        if k == 4:
            continue
        p0 = [yard_a[n] + (yard_b[n] - yard_a[n]) * t0 for n in range(3)]
        p1 = [yard_a[n] + (yard_b[n] - yard_a[n]) * t1 for n in range(3)]
        drop = rng.uniform(0.6, 1.25)
        tone = p["sail"] if k % 2 else p["sail_pale"]
        _skin(model, tone, p0, p1, (p1[0] + 0.05, p1[1] - 0.2, max(p1[2] - drop, 0.3)), (p0[0] - 0.05, p0[1] - 0.2, max(p0[2] - drop * rng.uniform(0.7, 1.0), 0.3)), 0.02, (p0[0], p0[1] + 2.0, p0[2]))
    # Rigging gone slack, and an oar still shipped.
    for a, b in ((stump, hull.at(0.72, 1.0, -1)), (stump, hull.at(0.3, 1.0, 1))):
        model.cylinder(a, b, 0.016, 0.016, p["rope"], segments=3, caps=False)
    model.cylinder(hull.at(0.36, 1.0, -1), (hull.at(0.36, 1.0, -1)[0] - 0.3, -3.3, 0.5), 0.03, 0.026, p["sea_wood"], segments=4)
    # The boulders it lies on, and those it knocked aside.
    for x, y, z, r, s in ((-3.6, 0.4, 0.5, 1.45, (1.25, 1.1, 0.72)), (-0.8, -1.2, 0.5, 1.4, (1.3, 1.05, 0.68)), (2.1, 0.8, 0.8, 1.6, (1.2, 1.0, 0.7)), (4.6, 0.1, 0.9, 1.5, (1.05, 0.95, 0.9)), (0.8, 1.9, 0.3, 1.0, (1.1, 1.0, 0.7)), (-2.6, -2.5, 0.2, 0.75, (1.2, 1.0, 0.7)), (6.1, -1.3, 0.2, 0.8, (1.1, 1.0, 0.8)), (-5.4, 1.4, 0.15, 0.7, (1.2, 0.9, 0.7))):
        _wet_rock(model, p, rng, (x, y, z), r, s)
    # Weed and moss where it's sat for years.
    for k in range(9):
        t = rng.uniform(0.1, 0.8)
        side = rng.choice((-1, 1))
        q = hull.at(t, rng.uniform(0.05, 0.4), side)
        model.rock(q, rng.uniform(0.18, 0.34), p["algae"] if k % 2 else p["moss"], rng, scale=(1.5, 0.5, 0.8), roughness=0.14)
    model.finish()
    kit.collision_cylinder("ShipOnBouldersRockA", (-3.2, 0.4, 0), (-3.2, 0.4, 1.3), 1.6)
    kit.collision_cylinder("ShipOnBouldersRockB", (2.1, 0.8, 0), (2.1, 0.8, 1.5), 1.7)
    kit.collision_box("ShipOnBouldersHull", (0.0, 0.1, 2.0), (12.0, 3.5, 1.8))


def wreck_ribs():
    """What's left of an older ship, sunk to its bilge in the silt: a keel, pairs of ribs curving up
    like a whale's, a few strakes still on one side. About 11 m long."""
    p = palette()
    rng = random.Random(402)
    model = kit.Model("WreckRibs")
    place = _turn(math.radians(7), math.radians(2), 0.13)
    hull = Hull(10.6, 1.9, 1.75, 0.9, place, strakes=6, stations=14)
    keep = lambda k, strake, side: not (side > 0 and strake < 3 and 3 <= k <= 8 and (k + strake) % 5)
    hull.planks(model, (p["sea_wood_dark"], p["sea_wood"], p["sea_wood_dark"]), rng, skip=keep)
    gone = {3, 11}
    for k in range(1, 14):
        if k in gone:
            continue
        t = k / 14
        for side in (-1, 1):
            if (k == 5 and side < 0) or (k == 9 and side > 0):
                top = 2
            else:
                top = 4 if rng.random() > 0.25 else 3
            points = [hull.at(t, n / 4, side) for n in range(top + 1)]
            for a, b in zip(points, points[1:]):
                model.cylinder(a, b, 0.085, 0.07, p["sea_wood"] if k % 2 else p["sea_wood_dark"], segments=5)
    hull.keel(model, p["sea_wood_dark"], radius=0.12)
    hull.stem(model, p["sea_wood_dark"], 1, radius=0.1, curl=0.35)
    # Rushes come up through it, and low humps of silt lie against the keel.
    for k in range(7):
        x = -4.6 + k * 1.5 + rng.uniform(-0.3, 0.3)
        model.rock((x, rng.uniform(-0.4, 0.4), 0.0), rng.uniform(0.3, 0.5), p["silt"], rng, scale=(1.5, 1.0, 0.3), roughness=0.14)
    for k in range(22):
        model.blade((rng.uniform(-5.0, 5.0), rng.uniform(-2.2, 2.2), 0.05), rng.uniform(0, math.tau), rng.uniform(0.4, 0.85), 0.05, 0.3, rng.choice((p["rush"], p["algae"], p["leaf_dry"])), segments=2)
    model.finish()
    kit.collision_box("WreckRibsSilt", (0, 0, 0.3), (10.0, 0.5, 0.6))


def wreck_stern():
    """A ship's broken-off stern lying on its side, planks sprung at the break, its post in the air,
    a boulder holding it down. About 4.5 m long."""
    p = palette()
    rng = random.Random(403)
    model = kit.Model("WreckStern")
    place = _turn(math.radians(38), math.radians(5), 0.55, x=-2.8)
    hull = Hull(11.0, 1.8, 1.45, 1.3, place, strakes=6, stations=20)
    cut = lambda k, strake, side: k < 15 + (strake % 3) - (1 if side < 0 else 0) or (side > 0 and strake == 3 and k == 17)
    hull.planks(model, (p["tar"], p["tar_light"], p["sea_wood_dark"]), rng, skip=cut)
    for k in (15, 17, 19):
        t = k / 20
        for side in (-1, 1):
            points = [hull.at(t, n / 4, side) for n in range(5)]
            for a, b in zip(points, points[1:]):
                model.cylinder(a, b, 0.05, 0.045, p["sea_wood_dark"], segments=4)
    keel = [hull.at(k / 20, 0.0, 1) for k in range(14, 21)]
    for a, b in zip(keel, keel[1:]):
        model.cylinder(a, b, 0.09, 0.09, p["tar"], segments=5)
    hull.stem(model, p["tar"], 1, curl=0.5)
    _wet_rock(model, p, rng, (0.6, 1.35, 0.2), 0.8, (1.2, 1.0, 0.75))
    _wet_rock(model, p, rng, (2.2, -1.2, 0.1), 0.5, (1.2, 1.0, 0.7))
    for k in range(9):
        model.blade((rng.uniform(-1.5, 2.5), rng.uniform(-1.5, 1.5), 0.0), rng.uniform(0, math.tau), rng.uniform(0.35, 0.7), 0.05, 0.3, rng.choice((p["rush"], p["algae"])), segments=2)
    model.finish()
    kit.collision_box("WreckStern", (0.8, 0, 0.8), (3.2, 2.2, 1.6))


def _boat(model, p, rng, place, tones):
    hull = Hull(4.4, 0.72, 0.56, 0.3, place, strakes=4, stations=10)
    hull.planks(model, tones, rng, thick=0.035)
    hull.keel(model, p["sea_wood_dark"], radius=0.05)
    hull.ribs(model, p["sea_wood_dark"], rng, radius=0.024)
    hull.stem(model, p["sea_wood_dark"], 1, radius=0.045, curl=0.2)
    hull.stem(model, p["sea_wood_dark"], 0, radius=0.045, curl=0.2)
    return hull


def rowboat_beached():
    """A clinker rowing boat pulled up on the mud and leaning on its bilge, oars across the thwarts,
    a heap of net in the stern and a stone on a rope for an anchor. About 4.6 m long."""
    p = palette()
    rng = random.Random(404)
    model = kit.Model("RowboatBeached")
    place = _turn(math.radians(11), math.radians(-3), 0.06)
    hull = _boat(model, p, rng, place, (p["sea_wood"], p["plank"], p["sea_wood"], p["plank_dark"]))
    model.box(place((0, 0, 0.14)), (3.2, 0.72, 0.03), p["sea_wood_dark"])
    for x in (-0.9, 0.5):
        model.cylinder(place((x, -0.6, 0.42)), place((x, 0.6, 0.42)), 0.04, 0.04, p["plank"], segments=4)
    for y in (-0.2, 0.18):
        model.cylinder(place((-1.7, y, 0.5)), place((1.4, y + 0.1, 0.5)), 0.022, 0.018, p["wood_drift"], segments=4)
        model.box(place((1.55, y + 0.1, 0.49)), (0.42, 0.12, 0.018), p["wood_drift"])
    for k in range(5):
        model.rock(place((-1.25 + rng.uniform(-0.25, 0.25), rng.uniform(-0.2, 0.2), 0.27)), rng.uniform(0.17, 0.25), p["net"], rng, scale=(1.3, 1.1, 0.55), roughness=0.14)
    bow = hull.at(1.0, 1.0, 1)
    model.cylinder(bow, (bow[0] + 1.1, 0.3, 0.05), 0.012, 0.012, p["rope"], segments=3, caps=False)
    _wet_rock(model, p, rng, (bow[0] + 1.15, 0.3, 0.1), 0.15, (1.2, 1.0, 0.8), algae=False)
    model.finish()
    kit.collision_box("RowboatBeached", (0, 0, 0.35), (4.4, 1.3, 0.7))


def rowboat_upturned():
    """A boat turned over on two logs for mending, its bottom tarred in patches, one plank out and a
    new pale one waiting. About 4.6 m long."""
    p = palette()
    rng = random.Random(405)
    model = kit.Model("RowboatUpturned")

    def place(q):
        return (q[0], -q[1], 1.02 - q[2] * 1.0)
    hull = Hull(4.4, 0.72, 0.56, 0.0, place, strakes=4, stations=10)
    hull.planks(model, (p["tar"], p["tar_light"], p["sea_wood_dark"], p["tar"]), rng, skip=lambda k, strake, side: side > 0 and strake == 2 and k in (4, 5), thick=0.035)
    hull.keel(model, p["sea_wood_dark"], radius=0.05)
    hull.ribs(model, p["sea_wood_dark"], rng, radius=0.024)
    model.box((0.1, 0, 0.44), (3.4, 1.1, 0.06), p["shadow"])
    for x in (-1.2, 1.2):
        model.cylinder((x, -0.95, 0.14), (x, 0.95, 0.14), 0.15, 0.14, p["log_dark"], segments=6)
    model.box((0.7, 1.5, 0.05), (2.2, 0.16, 0.035), p["plank"], rotation_z=0.12)
    model.finish()
    kit.collision_box("RowboatUpturned", (0, 0, 0.55), (4.3, 1.5, 1.05))


def fishing_jetty():
    """A plain jetty of split planks on driven posts, running out along -Y, one plank missing, a
    mooring post at its head with rope wound round it. 10 m long. Its origin is at the posts' feet,
    the deck 3.6 m above them, so they reach the river's bed."""
    p = palette()
    rng = random.Random(406)
    model = kit.Model("FishingJetty")
    half, deck = 5.0, 3.6
    y = -half
    while y < half:
        wide = rng.uniform(0.22, 0.3)
        if abs(y + 1.6) > 0.16:
            model.box((rng.uniform(-0.04, 0.04), y + wide / 2, deck), (1.75 + rng.uniform(-0.1, 0.12), wide - 0.02, 0.05), p[rng.choice(("sea_wood", "plank", "plank_dark", "sea_wood"))], rotation_z=rng.uniform(-0.012, 0.012))
        y += wide
    for side in (-1, 1):
        model.cylinder((side * 0.72, -half, deck - 0.07), (side * 0.72, half, deck - 0.07), 0.07, 0.07, p["sea_wood_dark"], segments=5)
        for k in range(5):
            py = -half + 0.2 + k * (2 * half - 0.4) / 4
            model.cylinder((side * 0.8, py, 0.0), (side * 0.8, py, deck + (0.45 if k == 0 else 0.1)), 0.095, 0.08, p["sea_wood_dark"], segments=6)
    model.cylinder((0.86, -half + 0.2, deck + 0.28), (0.74, -half + 0.2, deck + 0.28), 0.14, 0.14, p["rope"], segments=7)
    model.cylinder((0.8, -half + 0.2, deck + 0.28), (1.1, -half - 0.6, deck - 0.7), 0.012, 0.012, p["rope"], segments=3, caps=False)
    model.finish()
    kit.collision_box("FishingJetty", (0, 0, deck - 0.1), (1.9, 2 * half, 0.2))


# ---- the catch


def _fish(model, p, at, angle, length, tone="fish", hang=False):
    """A fish, lying along angle, or hung by its tail if hang."""
    if hang:
        x, y, z = at
        model.sphere((x, y, z - length * 0.5), length * 0.5, p[tone], scale=(0.26, 0.12, 1.0), segments=5, rings=4)
        model.slab([(x - 0.05, y - 0.012, z), (x + 0.05, y - 0.012, z), (x + 0.05, y + 0.012, z), (x - 0.05, y + 0.012, z)], 0.07, p[tone])
        return
    dx, dy = math.cos(angle), math.sin(angle)
    x, y, z = at
    model.sphere((x, y, z), length * 0.5, p[tone], scale=(1.0, 0.24, 0.17), segments=6, rings=4) if abs(dy) < 0.01 else model.sphere((x, y, z), length * 0.28, p[tone], scale=(1.0, 1.0, 0.3), segments=6, rings=4)
    model.cylinder((x - dx * length * 0.4, y - dy * length * 0.4, z), (x - dx * length * 0.64, y - dy * length * 0.64, z), length * 0.05, length * 0.13, p[tone], segments=3)


def fish_rack():
    """A tall drying rack of poles with split fish hung by the tail in rows, the old northern way.
    About 4 m long."""
    p = palette()
    rng = random.Random(410)
    model = kit.Model("FishRack")
    half = 2.0
    for x in (-half, half):
        for y in (-0.5, 0.5):
            model.cylinder((x, y * 1.2, 0), (x, y * 0.08, 2.32), 0.05, 0.04, p["bark"], segments=5)
    model.cylinder((-half - 0.15, 0, 2.28), (half + 0.15, 0, 2.28), 0.045, 0.04, p["sea_wood"], segments=5)
    for z, y in ((1.95, -0.2), (1.95, 0.2)):
        model.cylinder((-half, y, z), (half, y, z), 0.022, 0.022, p["sea_wood"], segments=4)
        x = -half + 0.14
        while x < half - 0.1:
            _fish(model, p, (x, y, z), 0.0, rng.uniform(0.5, 0.72), rng.choice(("fish_dry", "fish_dry", "fish")), hang=True)
            x += rng.uniform(0.2, 0.3)
    model.finish()
    for n, x in enumerate((-half, half)):
        kit.collision_cylinder(f"FishRack{n}", (x, 0, 0), (x, 0, 2.3), 0.12)


def net_rack():
    """Nets hung to dry and for mending over a long rail on forked poles, with cork floats along
    the top. About 4.5 m long."""
    p = palette()
    rng = random.Random(411)
    model = kit.Model("NetRack")
    half = 2.25
    for x in (-half, 0.0, half):
        model.cylinder((x, 0, 0), (x, 0, 1.92), 0.05, 0.04, p["bark"], segments=5)
        for s in (-1, 1):
            model.cylinder((x, 0, 1.84), (x, s * 0.13, 2.1), 0.022, 0.015, p["bark"], segments=4)
    model.cylinder((-half - 0.1, 0, 1.96), (half + 0.1, 0, 1.96), 0.03, 0.03, p["sea_wood"], segments=4)
    # The mesh: crossed cords, not a sheet, so you see through it.
    for k in range(25):
        x = -half + 0.08 + (2 * half - 0.16) * k / 24
        base = rng.uniform(0.2, 0.7)
        out = 0.42
        if 9 <= k <= 12:
            base = 1.05
        model.cylinder((x, 0.0, 1.96), (x + 0.42, out * (1.96 - base) / 1.7, base), 0.007, 0.007, p["net"], segments=3, caps=False)
        model.cylinder((x, 0.0, 1.96), (x - 0.42, out * (1.96 - base) / 1.7, base), 0.007, 0.007, p["net"], segments=3, caps=False)
    for z, y in ((1.6, 0.09), (1.25, 0.18), (0.9, 0.27), (0.55, 0.35)):
        model.cylinder((-half + 0.1, y, z), (half - 0.1, y, z + rng.uniform(-0.03, 0.03)), 0.006, 0.006, p["net_dark"], segments=3, caps=False)
    for k in range(9):
        x = -half + 0.3 + k * 0.48
        model.sphere((x, 0.04, 1.88), 0.06, p["cork"], scale=(1.5, 1, 0.8), segments=5, rings=3)
    for k in range(6):
        model.rock((rng.uniform(-half, half), 0.48, 0.1), rng.uniform(0.1, 0.18), p["net_dark"], rng, scale=(1.5, 1.0, 0.5), roughness=0.14)
    model.finish()
    for n, x in enumerate((-half, half)):
        kit.collision_cylinder(f"NetRack{n}", (x, 0, 0), (x, 0, 1.9), 0.1)


def net_heap():
    """A wet heap of net dumped on the ground, floats and a stone sinker showing. About 2 m across."""
    p = palette()
    rng = random.Random(412)
    model = kit.Model("NetHeap")
    for k in range(9):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.0, 0.62)
        model.rock((math.cos(a) * d, math.sin(a) * d, 0.1 + (0.62 - d) * 0.28), rng.uniform(0.22, 0.38), rng.choice((p["net"], p["net_dark"], p["net"])), rng, scale=(1.3, 1.1, 0.55), subdivisions=1, roughness=0.2)
    for k in range(16):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.35, 0.95)
        b = rng.uniform(0, math.tau)
        model.cylinder((math.cos(a) * d, math.sin(a) * d, 0.2 * (1 - d)), (math.cos(a) * d + math.cos(b) * 0.45, math.sin(a) * d + math.sin(b) * 0.45, 0.03), 0.008, 0.008, p["net"], segments=3, caps=False)
    for k in range(6):
        a = rng.uniform(0, math.tau)
        model.sphere((math.cos(a) * 0.7, math.sin(a) * 0.7, 0.13), 0.065, p["cork"], scale=(1.5, 1.0, 0.8), segments=5, rings=3)
    model.rock((0.75, -0.5, 0.08), 0.12, p["wet_stone_light"], rng, scale=(1.3, 1.0, 0.7))
    model.finish()


def fish_creels():
    """Three wicker creels set down together, one tipped over and spilling its fish on the mud, a
    lid beside it."""
    p = palette()
    rng = random.Random(413)
    model = kit.Model("FishCreels")
    for x, y, wide, tall in ((-0.4, 0.15, 0.32, 0.52), (0.3, 0.35, 0.27, 0.42)):
        model.lathe([(0.0, 0.0), (wide * 0.85, 0.01), (wide, tall * 0.55), (wide * 0.72, tall), (wide * 0.62, tall), (wide * 0.6, tall * 0.8), (0.0, tall * 0.8)], p["plank_dark"], segments=9, centre=(x, y, 0))
        for k in range(4):
            z = tall * (0.15 + k * 0.2)
            model.lathe([(wide * (0.92 + 0.08 * math.sin(k)), z), (wide * (0.97 + 0.05 * math.sin(k)), z + 0.03)], p["hay_old"], segments=9, centre=(x, y, 0))
    model.cylinder((-0.65, 0.15, 0.48), (-0.15, 0.15, 0.48), 0.015, 0.015, p["bark"], segments=3)
    # The tipped one, lying on its side, and what fell out.
    model.cylinder((0.55, -0.4, 0.22), (0.05, -0.55, 0.22), 0.16, 0.25, p["plank_dark"], segments=9)
    model.cylinder((0.06, -0.55, 0.22), (0.03, -0.56, 0.22), 0.2, 0.2, p["shadow"], segments=9, caps=True)
    for x, y, a in ((-0.3, -0.62, 0.0), (-0.55, -0.4, 0.0), (-0.45, -0.85, 0.0), (-0.8, -0.65, 0.0)):
        _fish(model, p, (x, y, 0.04), a, rng.uniform(0.3, 0.42))
    model.cylinder((0.7, -0.1, 0.02), (0.7, -0.1, 0.05), 0.26, 0.26, p["hay_old"], segments=9)
    model.finish()
    kit.collision_cylinder("FishCreels", (-0.1, 0.2, 0), (-0.1, 0.2, 0.5), 0.5, segments=8)


def fish_traps():
    """Long wicker eel traps stacked to dry, and one on its own with a rope. About 2 m long."""
    p = palette()
    rng = random.Random(414)
    model = kit.Model("FishTraps")
    for x, y, z in ((-0.1, -0.22, 0.17), (-0.05, 0.22, 0.17), (0.0, 0.0, 0.46)):
        a, b = (x - 0.9, y, z), (x + 0.75, y, z)
        for k in range(8):
            t0, t1 = k / 8, (k + 1) / 8
            r0, r1 = 0.17 * (1 - t0 * 0.75), 0.17 * (1 - t1 * 0.75)
            model.cylinder((a[0] + (b[0] - a[0]) * t0, y, z), (a[0] + (b[0] - a[0]) * t1, y, z), r0, r1, p["hay_old"] if k % 2 else p["plank_dark"], segments=7, caps=False)
        model.cylinder((a[0] - 0.01, y, z), (a[0] + 0.03, y, z), 0.15, 0.15, p["shadow"], segments=7)
    model.finish()
    kit.collision_box("FishTraps", (0, 0, 0.3), (1.8, 0.75, 0.6))


def gutting_table():
    """A slab of plank on stumps, scaled and stained, a knife stuck in it, fish on it and a bucket of
    heads under it. About 2 m long."""
    p = palette()
    rng = random.Random(415)
    model = kit.Model("GuttingTable")
    for x in (-0.72, 0.72):
        model.cylinder((x, 0, 0), (x, 0, 0.72), 0.2, 0.17, p["log_dark"], segments=7)
    for y, tone in ((-0.24, "sea_wood"), (0.0, "plank"), (0.24, "sea_wood")):
        model.box((0, y, 0.76), (2.1, 0.23, 0.07), p[tone])
    for x, y in ((-0.5, -0.12), (0.05, 0.16), (0.42, -0.2)):
        _fish(model, p, (x, y, 0.82), 0.0, rng.uniform(0.42, 0.56))
    # The knife, point down in the wood.
    model.slab([(0.72, 0.1, 0.96), (0.76, 0.1, 0.96), (0.76, 0.112, 0.96), (0.72, 0.112, 0.96)], 0.17, p["steel"])
    model.cylinder((0.74, 0.106, 0.96), (0.74, 0.106, 1.1), 0.018, 0.022, p["log_dark"], segments=5)
    model.lathe([(0.0, 0.0), (0.2, 0.01), (0.24, 0.3), (0.21, 0.3), (0.0, 0.05)], p["plank_dark"], segments=9, centre=(-0.05, 0.05, 0))
    for k in range(4):
        model.sphere((-0.05 + rng.uniform(-0.1, 0.1), 0.05 + rng.uniform(-0.1, 0.1), 0.26), 0.06, p["fish"], scale=(1.2, 0.8, 0.8), segments=5, rings=3)
    model.finish()
    kit.collision_box("GuttingTable", (0, 0, 0.4), (2.1, 0.7, 0.8))


def smoke_hut():
    """A squat smoke hut of tarred planks under turf, smoke-black round its open door, split fish on
    rods inside over a bed of embers. About 3 m long."""
    p = palette()
    rng = random.Random(416)
    model = kit.Model("SmokeHut")
    hx, hy, top, rx, ey, ez, rz = 1.45, 1.2, 1.7, 1.75, 1.6, 1.58, 2.7
    gap = 0.46
    model.box((0, 0, 0.03), (2 * hx, 2 * hy, 0.06), p["shadow"])
    model.box((0, hy - 0.05, top / 2), (2 * hx, 0.06, top), p["room"])
    wide = 0.24
    for side in (-1, 1):
        model.box((side * (hx - 0.05), 0, top / 2), (0.06, 2 * hy, top), p["room"])
        for k in range(int(2 * hy / wide)):
            y = -hy + wide * (k + 0.5)
            high = rz - (rz - top) * abs(y) / hy - 0.12
            model.box((side * hx, y, high / 2), (0.05, wide - 0.015, high), p[rng.choice(("tar", "tar_light"))])
    for k in range(int(2 * hx / wide)):
        x = -hx + wide * (k + 0.5)
        model.box((x, hy, top / 2), (wide - 0.015, 0.05, top), p[rng.choice(("tar", "tar_light"))])
        if abs(x) > gap:
            model.box((x, -hy, top / 2), (wide - 0.015, 0.05, top), p[rng.choice(("tar", "tar_light"))])
    model.box((0, -hy, 1.55), (2 * gap + 0.1, 0.05, 0.3), p["tar"])
    # Sod too thin for the lumps of a house's turf, on a small roof.
    village._gable_roof(model, rng, rx, ey, ez, rz, 3, 4, (p["turf"], p["turf"], p["turf_dark"]), thick=0.16)
    model.cylinder((-rx - 0.03, 0, rz + 0.02), (rx + 0.03, 0, rz + 0.02), 0.07, 0.07, p["log_dark"], segments=5)
    village._growth(model, p, rng, rx, ey, ez, rz, 3, blades=4, flowers=True)
    homestead._door_leaf(model, p, rng, (-gap, -hy - 0.03, 0.04), 1, 2 * gap, 1.34, 1.35, boards=3)
    for x in (-0.55, -0.1, 0.5):
        model.rock((x, 0.3, 0.1), 0.12, p["ember"], rng, scale=(1, 1, 0.5))
    for y in (-0.3, 0.25):
        model.cylinder((-hx + 0.1, y, 1.42), (hx - 0.1, y, 1.42), 0.015, 0.015, p["sea_wood"], segments=3)
        for k in range(6):
            _fish(model, p, (-1.0 + k * 0.4, y, 1.42), 0.0, 0.46, "fish_dry", hang=True)
    model.finish()
    kit.collision_box("SmokeHutBack", (0, hy, top / 2), (2 * hx, 0.2, top))
    for n, side in enumerate((-1, 1)):
        kit.collision_box(f"SmokeHutEnd{n}", (side * hx, 0, top / 2), (0.2, 2 * hy, top))
        kit.collision_box(f"SmokeHutFront{n}", (side * (gap + (hx - gap) / 2), -hy, top / 2), (hx - gap, 0.2, top))
    village._roof_collision("SmokeHut", rx, ey, ez, rz)


# ---- tools left lying


def _churned(model, p, seed, wide):
    """A low hump of churned mud for a small tool to lie on, so the ground doesn't swallow it."""
    model.rock((0, 0, 0), wide, p["silt"], random.Random(seed), scale=(1.5, 0.8, 0.17), roughness=0.1)


def ground_knife():
    """A big single-edged knife, a seax, left on the mud, its blade a little bent. About 50 cm."""
    p = palette()
    model = kit.Model("GroundKnife")
    _churned(model, p, 420, 0.32)
    model.slab([(-0.02, -0.038, 0.11), (0.3, -0.05, 0.1), (0.36, 0.0, 0.1), (-0.02, 0.038, 0.11)], 0.016, p["steel"])
    model.cylinder((-0.2, 0, 0.1), (-0.02, 0, 0.104), 0.028, 0.032, p["log_dark"], segments=6)
    model.cylinder((-0.022, 0, 0.104), (-0.008, 0, 0.104), 0.046, 0.046, p["iron"], segments=6)
    model.finish()


def ground_hammer_a():
    """A shipwright's mallet of one piece of oak, a long handle and a heavy round head, on the mud.
    About 60 cm."""
    p = palette()
    model = kit.Model("GroundHammerA")
    _churned(model, p, 421, 0.36)
    model.cylinder((-0.34, 0, 0.1), (0.2, 0, 0.13), 0.024, 0.028, p["plank"], segments=5)
    model.cylinder((0.2, -0.13, 0.15), (0.2, 0.13, 0.15), 0.08, 0.08, p["plank_dark"], segments=8)
    for y in (-0.11, 0.11):
        model.cylinder((0.2, y - 0.012, 0.15), (0.2, y + 0.012, 0.15), 0.085, 0.085, p["iron"], segments=8)
    model.finish()


def ground_hammer_b():
    """An iron hammer and a scatter of ship's clench nails round it. About 40 cm."""
    p = palette()
    rng = random.Random(422)
    model = kit.Model("GroundHammerB")
    model.cylinder((-0.22, 0, 0.02), (0.13, 0, 0.03), 0.016, 0.018, p["wood_drift"], segments=5)
    model.box((0.15, 0, 0.035), (0.04, 0.17, 0.05), p["iron"])
    model.cylinder((0.15, 0.08, 0.035), (0.15, 0.12, 0.035), 0.027, 0.027, p["iron"], segments=6)
    model.cylinder((0.15, -0.08, 0.035), (0.15, -0.14, 0.033), 0.022, 0.006, p["iron"], segments=4)
    for k in range(9):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.2, 0.42)
        x, y = math.cos(a) * d, math.sin(a) * d
        b = rng.uniform(0, math.tau)
        model.cylinder((x, y, 0.008), (x + math.cos(b) * 0.05, y + math.sin(b) * 0.05, 0.008), 0.005, 0.003, p["iron"], segments=3)
    model.finish()


def shipwright_tools():
    """A mending place left in a hurry: an adze sunk in a baulk, a tar pot on dead coals, a bundle of
    oakum and two new planks on trestles. About 3 m long."""
    p = palette()
    rng = random.Random(423)
    model = kit.Model("ShipwrightTools")
    for x in (-1.0, 1.0):
        for s in (-1, 1):
            model.cylinder((x + s * 0.24, -0.25, 0), (x, -0.25, 0.68), 0.035, 0.03, p["bark"], segments=4)
            model.cylinder((x + s * 0.24, 0.25, 0), (x, 0.25, 0.68), 0.035, 0.03, p["bark"], segments=4)
        model.cylinder((x, -0.27, 0.68), (x, 0.27, 0.68), 0.04, 0.04, p["log_dark"], segments=4)
    for y in (-0.14, 0.14):
        model.box((rng.uniform(-0.1, 0.1), y, 0.74), (3.0, 0.24, 0.04), p["plank"])
    model.cylinder((-1.0, 1.0, 0.12), (1.0, 1.05, 0.12), 0.14, 0.13, p["sea_wood_dark"], segments=6)
    model.box((0.25, 1.02, 0.28), (0.03, 0.12, 0.08), p["steel"])
    model.cylinder((0.25, 1.02, 0.3), (0.72, 1.0, 0.58), 0.016, 0.014, p["wood_drift"], segments=4)
    # The tar pot.
    model.lathe([(0.0, 0.14), (0.17, 0.15), (0.21, 0.32), (0.18, 0.42), (0.16, 0.42), (0.0, 0.36)], p["iron"], segments=9, centre=(-1.0, -1.1, 0))
    model.cylinder((-1.0, -1.1, 0.36), (-1.0, -1.1, 0.38), 0.155, 0.155, p["shadow"], segments=9)
    for k in range(3):
        a = k * math.tau / 3
        model.rock((-1.0 + math.cos(a) * 0.2, -1.1 + math.sin(a) * 0.2, 0.08), 0.1, p["wet_stone"], rng, scale=(1, 1, 0.9))
    model.cylinder((-1.0, -1.1, 0.34), (-0.68, -1.05, 0.82), 0.012, 0.012, p["bark"], segments=3)
    # The oakum.
    for k in range(4):
        model.rock((0.75 + rng.uniform(-0.2, 0.2), -1.05 + rng.uniform(-0.15, 0.15), 0.1), 0.17, p["hay_old"], rng, scale=(1.3, 1.0, 0.6), roughness=0.16)
    model.finish()
    kit.collision_box("ShipwrightTools", (0, 0, 0.38), (2.3, 0.7, 0.76))


def fish_bones():
    """A heap of backbones and heads with a clam shell or two, where the fish were cleaned."""
    p = palette()
    rng = random.Random(424)
    model = kit.Model("FishBones")
    for k in range(5):
        a = rng.uniform(0, math.tau)
        x, y = rng.uniform(-0.36, 0.36), rng.uniform(-0.36, 0.36)
        dx, dy = math.cos(a), math.sin(a)
        model.cylinder((x, y, 0.015), (x + dx * 0.34, y + dy * 0.34, 0.015), 0.008, 0.005, p["bone"], segments=3)
        for n in range(4):
            t = 0.05 + n * 0.08
            px, py = x + dx * t, y + dy * t
            model.cylinder((px - dy * 0.05, py + dx * 0.05, 0.012), (px + dy * 0.05, py - dx * 0.05, 0.012), 0.004, 0.004, p["bone"], segments=3, caps=False)
        model.sphere((x, y, 0.03), 0.036, p["bone"], scale=(1.2, 0.8, 0.7), segments=5, rings=3)
    for k in range(6):
        model.sphere((rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5), 0.012), 0.03, p["wet_stone_light"] if k % 2 else p["bone"], scale=(1.1, 1.0, 0.35), segments=5, rings=3)
    model.finish()


# ---- what lies and grows on wet dirt


def wet_boulder_a():
    """A dark river boulder with a tide line of weed round its foot. About 2.4 m across."""
    p = palette()
    rng = random.Random(430)
    model = kit.Model("WetBoulderA")
    _wet_rock(model, p, rng, (0, 0, 0.42), 0.95, (1.25, 0.98, 0.85))
    for k in range(10):
        a = k * math.tau / 10 + rng.uniform(-0.2, 0.2)
        model.rock((math.cos(a) * 1.06, math.sin(a) * 0.84, 0.07), rng.uniform(0.14, 0.26), p["algae"], rng, scale=(1.3, 1.0, 0.4), roughness=0.14)
    model.finish()
    kit.collision_cylinder("WetBoulderA", (0, 0, 0), (0, 0, 1.1), 1.0, segments=8)


def wet_boulder_b():
    """A long split boulder lying half in the mud, a smaller one against it. About 3 m long."""
    p = palette()
    rng = random.Random(431)
    model = kit.Model("WetBoulderB")
    _wet_rock(model, p, rng, (-0.4, 0, 0.22), 0.86, (1.5, 0.82, 0.68))
    _wet_rock(model, p, rng, (0.95, 0.2, 0.2), 0.68, (1.2, 0.85, 0.72))
    _wet_rock(model, p, rng, (0.4, -0.75, 0.05), 0.34, (1.3, 1.0, 0.6), algae=False)
    model.finish()
    kit.collision_box("WetBoulderB", (0.1, 0, 0.45), (2.7, 1.3, 0.9))


def mud_rushes():
    """A tussock of soft rush for wet ground: stiff dark blades and brown flower tufts near their
    tips."""
    p = palette()
    rng = random.Random(432)
    model = kit.Model("MudRushes")
    for k in range(13):
        angle = rng.uniform(0, math.tau)
        base = (rng.uniform(-0.1, 0.1), rng.uniform(-0.1, 0.1), 0.0)
        tall = rng.uniform(0.5, 0.78)
        model.blade(base, angle, tall, 0.022, 0.14, p["rush"] if k % 4 else p["leaf_deep"], segments=2)
        if k % 3 == 0:
            model.sphere((base[0] + math.cos(angle) * 0.03, base[1] + math.sin(angle) * 0.03, tall * 0.72), 0.024, p["rush_tip"], scale=(1, 1, 1.5), segments=4, rings=2)
    model.finish()


def butterbur():
    """Butterbur: big round leaves on short stalks, wider than a hand can span, crowding the wet."""
    p = palette()
    rng = random.Random(433)
    model = kit.Model("Butterbur")
    for k in range(6):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.08, 0.34)
        x, y = math.cos(a) * d, math.sin(a) * d
        z = rng.uniform(0.28, 0.52)
        model.cylinder((x * 0.3, y * 0.3, 0), (x, y, z), 0.012, 0.009, p["leaf_light"], segments=3, caps=False)
        model.pad((x, y, z), rng.uniform(0.17, 0.26), p["butterbur"] if k % 3 else p["leaf_mid"], notch=0.4, segments=9)
    model.finish()


def sunk_stones():
    """A few wet stones sunk to their shoulders in the mud."""
    p = palette()
    rng = random.Random(434)
    model = kit.Model("SunkStones")
    for k in range(4):
        model.rock((rng.uniform(-0.35, 0.35), rng.uniform(-0.3, 0.3), 0.0), rng.uniform(0.09, 0.2), rng.choice((p["wet_stone"], p["wet_stone_light"])), rng, scale=(1.3, 1.0, 0.7), roughness=0.2)
    model.finish()


def flotsam_line():
    """What the river leaves at its highest: a wrack of dead reed, twigs and a shell, in a line."""
    p = palette()
    rng = random.Random(435)
    model = kit.Model("FlotsamLine")
    for k in range(18):
        x = rng.uniform(-0.8, 0.8)
        y = rng.uniform(-0.12, 0.12) + math.sin(x * 3.0) * 0.1
        a = rng.uniform(-0.5, 0.5)
        long = rng.uniform(0.1, 0.32)
        model.cylinder((x, y, 0.012), (x + math.cos(a) * long, y + math.sin(a) * long, 0.018), 0.007, 0.005, rng.choice((p["leaf_dry"], p["sea_wood"], p["hay_old"], p["log_dark"])), segments=3, caps=False)
    for k in range(3):
        model.sphere((rng.uniform(-0.6, 0.6), rng.uniform(-0.12, 0.12), 0.012), 0.03, p["bone"], scale=(1.1, 1.0, 0.35), segments=5, rings=3)
    model.finish()


def wet_puddle():
    """A shallow puddle lying on wet dirt, dark and shining. About 1.6 m across."""
    p = palette()
    rng = random.Random(436)
    model = kit.Model("WetPuddle")
    for k in range(4):
        a = k * math.tau / 4 + rng.uniform(-0.3, 0.3)
        model.pad((math.cos(a) * 0.32, math.sin(a) * 0.22, 0.016), rng.uniform(0.32, 0.46), p["water_dark"], notch=0.0, segments=10)
    model.finish()


BUILDERS = {fn.__name__: fn for fn in (
    ship_on_boulders, wreck_ribs, wreck_stern, rowboat_beached, rowboat_upturned, fishing_jetty,
    fish_rack, net_rack, net_heap, fish_creels, fish_traps, gutting_table, smoke_hut, ground_knife,
    ground_hammer_a, ground_hammer_b, shipwright_tools, fish_bones, wet_boulder_a, wet_boulder_b,
    mud_rushes, butterbur, sunk_stones, flotsam_line, wet_puddle,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
