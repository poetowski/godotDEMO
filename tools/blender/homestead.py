"""The homestead family: the farms round Aiwyk, the village in the middle of R1. A working farm with
its doors open, a barn, a poor old house going to ruin behind a broken fence, a turf croft that
never had a fence, the fence's broken lengths, the sign on the road in, and the rocks and weeds of
the fields between them. It's built from the village family's walls, roofs and palette, so it reads
as the same people. Each asset is a small script in tools/blender/assets/ that calls make(<slug>).
Colours are sRGB. The kinds and shapes are placeholders until the author says otherwise
(docs/world/regions/R1/art.md).
"""
import math
import random

import farmstead
import kit
import village


def palette():
    """The village palette and what the farms add."""
    p = village.palette()
    m = kit.material
    p.update({
        "room": m("FarmRoom", (0.17, 0.13, 0.10), roughness=1.0),
        "floor": m("FarmFloor", (0.30, 0.23, 0.16), roughness=1.0),
        "lichen": m("Lichen", (0.62, 0.64, 0.42), roughness=1.0),
        "thistle": m("Thistle", (0.56, 0.27, 0.58), roughness=0.8),
        "berry": m("Berry", (0.15, 0.08, 0.14), roughness=0.5),
        "elder_flower": m("ElderFlower", (0.88, 0.85, 0.66), roughness=0.9),
        "dock": m("DockSeed", (0.50, 0.26, 0.13), roughness=1.0),
    })
    return p


# ---- walls with a way in


def _open_log_walls(model, p, rng, hx, hy, base, top, ridge, ey, ez, gap, gap_top, radius=0.14, past=0.22):
    """Log walls with a real doorway in the front, gap metres either side of the middle and up to
    gap_top: logs cross at the corners and stop at the door, and a room lies behind it."""
    step = radius * 1.85
    # The room: floor, ceiling, and thin dark walls just inside the logs.
    model.box((0, 0, base + 0.02), (2 * hx - 0.1, 2 * hy - 0.1, 0.04), p["floor"])
    model.box((0, 0, top - 0.03), (2 * hx - 0.1, 2 * hy - 0.1, 0.06), p["room"])
    model.box((0, hy - 0.1, (base + top) / 2), (2 * hx - 0.1, 0.08, top - base), p["room"])
    for side in (-1, 1):
        model.box((side * (hx - 0.1), 0, (base + top) / 2), (0.08, 2 * hy - 0.1, top - base), p["room"])
    for side in (-1, 1):
        model.box((side * (gap + (hx - gap) / 2), -hy + 0.1, (base + top) / 2), (hx - gap, 0.08, top - base), p["room"])
    model.box((0, -hy + 0.1, (gap_top + top) / 2), (2 * gap, 0.08, top - gap_top), p["room"])
    z = base + radius
    while z < top:
        tone = lambda: rng.choice((p["log"], p["log"], p["log_dark"]))
        model.cylinder((-hx - past, hy, z), (hx + past, hy, z), radius, radius * rng.uniform(0.92, 1.0), tone(), segments=6)
        if z < gap_top:
            for side in (-1, 1):
                model.cylinder((side * gap, -hy, z), (side * (hx + past), -hy, z), radius, radius * rng.uniform(0.92, 1.0), tone(), segments=6)
        else:
            model.cylinder((-hx - past, -hy, z), (hx + past, -hy, z), radius, radius * rng.uniform(0.92, 1.0), tone(), segments=6)
        for side in (-1, 1):
            model.cylinder((side * hx, -hy - past, z + step / 2), (side * hx, hy + past, z + step / 2), radius, radius * rng.uniform(0.92, 1.0), tone(), segments=6)
        z += step
    z = top + step / 2
    while True:
        half = ey * (ridge - 0.28 - z) / (ridge - ez)
        if half < 0.12:
            break
        half = min(half, hy)
        for side in (-1, 1):
            model.cylinder((side * hx, -half, z), (side * hx, half, z), radius, radius, rng.choice((p["log"], p["log_dark"])), segments=6)
        z += step


def _door_leaf(model, p, rng, hinge, along, wide, tall, swing, boards=3):
    """A door's leaf hung at hinge = (x, y, z), swung out from the wall. along is +1 when it would
    close toward +X. Planks and two ledges, turned swing radians from shut toward -Y."""
    dx, dy = along * math.cos(swing), -math.sin(swing)
    angle = math.atan2(dy, dx)
    board = wide / boards
    for k in range(boards):
        t = board * (k + 0.5)
        model.box((hinge[0] + dx * t, hinge[1] + dy * t, hinge[2] + tall / 2), (board - 0.012, 0.05, tall), rng.choice((p["plank"], p["plank_dark"])), rotation_z=angle)
    for z in (0.32, tall - 0.32):
        model.box((hinge[0] + dx * wide / 2 + dy * 0.0, hinge[1] + dy * wide / 2, hinge[2] + z), (wide - 0.04, 0.085, 0.11), p["plank_dark"], rotation_z=angle)


def _door_frame(model, p, y, base, gap, gap_top):
    for x in (-gap - 0.05, gap + 0.05):
        model.cylinder((x, y, base), (x, y, gap_top + 0.1), 0.085, 0.075, p["bark"], segments=6)
    model.cylinder((-gap - 0.2, y, gap_top + 0.1), (gap + 0.2, y, gap_top + 0.1), 0.09, 0.09, p["bark"], segments=6)


def _steps(model, p, y, base, wide):
    model.box((0, y - 0.3, base * 0.74), (wide + 0.3, 0.6, base * 0.52), p["stone_mid"])
    model.box((0, y - 0.82, base * 0.3), (wide + 0.6, 0.55, base * 0.6), p["stone_dark"])


def _open_shutter(model, p, rng, at, wide=0.74, tall=0.82):
    """A window on a wall facing -Y with its two shutters thrown back, dark glass-less inside."""
    model.box((at[0], at[1] - 0.02, at[2]), (wide + 0.14, 0.05, tall + 0.14), p["log_dark"])
    model.box((at[0], at[1] - 0.05, at[2]), (wide, 0.04, tall), p["shadow"])
    model.box((at[0], at[1] - 0.12, at[2] - tall / 2 - 0.06), (wide + 0.3, 0.16, 0.08), p["log_dark"])
    for side in (-1, 1):
        for k in range(3):
            x = at[0] + side * (wide / 2 + 0.07 + wide / 6 * (k + 0.5))
            model.box((x, at[1] - 0.09, at[2]), (wide / 6 - 0.01, 0.04, tall), rng.choice((p["plank"], p["plank_dark"])))


# ---- houses


def farmhouse_open():
    """A log farmhouse with both leaves of its door standing wide on a room you can see into: a
    hearth with embers at the back, a table and a bench. Hay roof, one window's shutters thrown
    back, a bench by the door. About 8 m long."""
    p = palette()
    rng = random.Random(301)
    hx, hy, base, top, rx, ey, ez, rz = 3.3, 2.4, 0.5, 2.7, 3.85, 3.15, 2.42, 4.7
    gap, gap_top = 0.72, base + 2.0
    model = kit.Model("FarmhouseOpen")
    # A footing with the stones gathered round it, but open at the door.
    for k in range(34):
        side = k % 4
        t = rng.uniform(-1.0, 1.0)
        x, y = {0: (t * hx, -hy - 0.22), 1: (t * hx, hy + 0.22), 2: (-hx - 0.22, t * hy), 3: (hx + 0.22, t * hy)}[side]
        if side == 0 and abs(x) < 1.0:
            continue
        model.rock((x, y, rng.uniform(0.1, 0.2)), rng.uniform(0.15, 0.26), rng.choice((p["stone_mid"], p["stone_light"], p["stone_dark"])), rng, scale=(1.3, 0.8, 0.8))
    model.box((0, 0, base / 2), (2 * hx + 0.4, 2 * hy + 0.4, base), p["stone_dark"])
    _open_log_walls(model, p, rng, hx, hy, base, top, rz, ey, ez, gap, gap_top)
    village._thatch(model, p, rng, rx, ey, ez, rz)
    village._growth(model, p, rng, rx, ey, ez, rz, 7, blades=4)
    wall = hy + 0.16
    _door_frame(model, p, -wall + 0.02, base, gap, gap_top)
    for side, along in ((-1, 1), (1, -1)):
        _door_leaf(model, p, rng, (side * gap, -wall, base + 0.03), along, gap, 1.94, 1.3)
    _steps(model, p, -wall, base, 2 * gap)
    # Inside: the hearth and its embers on the back wall, a table, a bench, a barrel.
    model.box((-0.5, hy - 0.5, base + 0.42), (1.3, 0.7, 0.84), p["stone_mid"])
    model.box((-0.5, hy - 0.45, base + 0.5), (0.8, 0.55, 0.5), p["shadow"])
    for k in range(7):
        model.rock((-0.5 + rng.uniform(-0.28, 0.28), hy - 0.5 + rng.uniform(-0.15, 0.1), base + 0.3), rng.uniform(0.05, 0.09), p["ember"], rng, scale=(1, 1, 0.5))
    model.box((0.9, 0.35, base + 0.74), (1.3, 0.72, 0.06), p["plank"])
    for x in (0.4, 1.4):
        model.box((x, 0.35, base + 0.36), (0.09, 0.6, 0.72), p["log_dark"])
    model.box((0.9, -0.3, base + 0.42), (1.2, 0.26, 0.05), p["plank_dark"])
    model.lathe([(0.0, 0.0), (0.26, 0.02), (0.31, 0.38), (0.26, 0.74), (0.0, 0.74)], p["plank_dark"], segments=9, centre=(-2.2, 1.3, base + 0.04))
    # Windows, a chimney, the bench and firewood along the front.
    _open_shutter(model, p, rng, (2.05, -wall, 1.75))
    village._shutter(model, p, rng, (-2.05, -wall, 1.75), True)
    village._shutter(model, p, rng, (0.0, wall, 1.75), True)
    village._shutter(model, p, rng, (hx + 0.16, 0.0, 1.7), False)
    village._chimney(model, p, -0.5, hy - 0.5, 2.5, 5.35)
    model.box((-2.05, -wall - 0.45, 0.46), (1.7, 0.32, 0.07), p["wood_drift"])
    for x in (-2.75, -1.35):
        model.box((x, -wall - 0.45, 0.22), (0.12, 0.28, 0.44), p["log_dark"])
    village._firewood(model, p, rng, hx + 0.32, -1.2, 0.1)
    model.finish()
    kit.collision_box("FarmhouseOpen", (0, 0, top / 2), (2 * hx + 0.4, 2 * hy + 0.4, top))
    village._roof_collision("FarmhouseOpen", rx, ey, ez, rz)


def farm_barn():
    """A long plank barn on a low stone footing, its big doors thrown open on hay stacked to the
    rafters, a shingled roof gone mossy and a hoist beam over the door. About 9.5 m long."""
    p = palette()
    rng = random.Random(302)
    hx, hy, top, rx, ey, ez, rz = 4.3, 2.8, 3.1, 4.8, 3.5, 2.95, 6.1
    gap, gap_top = 1.35, 2.75
    model = kit.Model("FarmBarn")
    model.box((0, 0, 0.1), (2 * hx + 0.3, 2 * hy + 0.3, 0.2), p["stone_dark"])
    model.box((0, 0, 0.22), (2 * hx - 0.1, 2 * hy - 0.1, 0.05), p["soil"])
    wide = 0.31
    tones = ("plank", "plank_dark", "plank", "log")
    # The room's dark lining, with the doorway open in it.
    model.box((0, hy - 0.06, top / 2), (2 * hx - 0.1, 0.06, top), p["room"])
    for side in (-1, 1):
        model.box((side * (hx - 0.06), 0, top / 2), (0.06, 2 * hy - 0.1, top), p["room"])
        model.box((side * (gap + (hx - gap) / 2), -hy + 0.06, top / 2), (hx - gap, 0.06, top), p["room"])
    model.box((0, 0, top - 0.02), (2 * hx - 0.1, 2 * hy - 0.1, 0.05), p["room"])
    for k in range(int(2 * hx / wide)):
        x = -hx + wide * (k + 0.5)
        model.box((x, hy, top / 2 + 0.1), (wide - 0.02, 0.06, top), p[rng.choice(tones)])
        if abs(x) > gap:
            model.box((x, -hy, top / 2 + 0.1), (wide - 0.02, 0.06, top), p[rng.choice(tones)])
        else:
            model.box((x, -hy, (gap_top + top) / 2 + 0.1), (wide - 0.02, 0.06, top - gap_top), p[rng.choice(tones)])
    for side in (-1, 1):
        for k in range(int(2 * hy / wide)):
            y = -hy + wide * (k + 0.5)
            high = rz - (rz - top) * abs(y) / hy - 0.16
            model.box((side * hx, y, (0.1 + high) / 2), (0.06, wide - 0.02, high - 0.1), p[rng.choice(tones)])
    for x, y in ((-hx, -hy), (hx, -hy), (-hx, hy), (hx, hy)):
        model.cylinder((x, y, 0.0), (x, y, top + 0.1), 0.11, 0.09, p["bark"], segments=6)
    _door_frame(model, p, -hy - 0.03, 0.05, gap, gap_top)
    for side, along in ((-1, 1), (1, -1)):
        _door_leaf(model, p, rng, (side * gap, -hy - 0.05, 0.1), along, gap, 2.6, 1.42, boards=5)
    # Hay heaped inside, spilling a little to the sill.
    for k in range(9):
        model.rock((rng.uniform(-2.8, 2.8), rng.uniform(0.3, 2.0), rng.uniform(0.5, 1.8)), rng.uniform(0.75, 1.05), rng.choice((p["hay"], p["hay_dark"], p["hay_old"])), rng, scale=(1.3, 0.9, 0.9), roughness=0.16)
    for k in range(6):
        model.rock((rng.uniform(-1.1, 1.1), rng.uniform(-2.3, -0.7), 0.3), rng.uniform(0.18, 0.34), rng.choice((p["hay"], p["hay_dark"])), rng, scale=(1.5, 1.2, 0.45), roughness=0.14)
    # The roof, the hoist and a board over the door.
    shingles = (p["shingle_a"], p["shingle_b"], p["shingle_b"], p["shingle_c"])
    village._gable_roof(model, rng, rx, ey, ez, rz, 11, int(rx * 4), shingles, thick=0.09)
    model.cylinder((-rx - 0.04, 0, rz + 0.03), (rx + 0.04, 0, rz + 0.03), 0.09, 0.09, p["tar"], segments=5)
    for k in range(7):
        side = rng.choice((-1, 1))
        village._slope_patch(model, p["leaf_deep"] if k % 2 else p["moss"], rng, side, rng.uniform(-rx * 0.85, rx * 0.85), rng.uniform(0.02, 0.5), ey, ez, rz, rng.uniform(0.14, 0.3), pieces=4, lift=0.16)
    village._growth(model, p, rng, rx, ey, ez, rz, 4, blades=4)
    model.finish()
    kit.collision_box("FarmBarnBack", (0, hy, top / 2), (2 * hx + 0.3, 0.3, top))
    for n, side in enumerate((-1, 1)):
        kit.collision_box(f"FarmBarnEnd{n}", (side * hx, 0, top / 2), (0.3, 2 * hy + 0.3, top))
        kit.collision_box(f"FarmBarnFront{n}", (side * (gap + (hx - gap) / 2), -hy, top / 2), (hx - gap, 0.3, top))
    kit.collision_box("FarmBarnHay", (0, 1.2, 1.1), (6.6, 2.6, 2.2))
    village._roof_collision("FarmBarn", rx, ey, ez, rz)


def farmhouse_old():
    """A poor old house still just standing: its hay roof rotted through, bare rafters in the hole
    and boards nailed over the rest, one shutter hanging, the door half off its hinge, and nettles
    of moss climbing the logs. About 7.5 m long."""
    p = palette()
    rng = random.Random(303)
    hx, hy, base, top, rx, ey, ez, rz = 3.0, 2.25, 0.35, 2.35, 3.55, 2.95, 2.2, 4.25
    gap, gap_top = 0.55, base + 1.85
    model = kit.Model("FarmhouseOld")
    model.box((0, 0, base / 2), (2 * hx + 0.35, 2 * hy + 0.35, base), p["stone_dark"])
    _open_log_walls(model, p, rng, hx, hy, base, top, rz, ey, ez, gap, gap_top)
    # The north slope whole, in old hay. The south one lost a stretch at its east end.
    tones = (p["hay_old"], p["hay_old"], p["hay_dark"], p["moss"])
    village._roof_plane(model, rng, (rx, ey, ez), (-rx, ey, ez), (-rx, 0.0, rz), (rx, 0.0, rz), 7, 12, tones, thick=0.18)
    village._roof_plane(model, rng, (-rx, -ey, ez), (0.7, -ey, ez), (0.7, 0.0, rz), (-rx, 0.0, rz), 7, 8, tones, thick=0.18)
    village._roof_plane(model, rng, (0.7, -ey, ez), (rx, -ey, ez), (rx, -ey * 0.55, ez + (rz - ez) * 0.45), (0.7, -ey * 0.55, ez + (rz - ez) * 0.45), 3, 4, tones, thick=0.16)
    model.cylinder((-rx - 0.04, 0, rz + 0.05), (rx * 0.6, 0.02, rz - 0.04), 0.14, 0.14, p["hay_old"], segments=6)
    model.cylinder((rx * 0.6, 0.02, rz - 0.04), (rx + 0.04, 0, rz - 0.22), 0.09, 0.08, p["log_dark"], segments=5)
    # The hole: bare rafters, and the boards someone nailed across part of it.
    for x in (1.0, 1.75, 2.5, 3.2):
        y, z = village._slope_point(-1, 0.42, ey, ez, rz)
        model.cylinder((x, y, z), (x, 0.0, rz - 0.1), 0.05, 0.045, p["log_dark"], segments=5)
    for k, t in enumerate((0.5, 0.6, 0.7)):
        y, z = village._slope_point(-1, t, ey, ez, rz)
        model.box((1.45 + k * 0.08, y, z + 0.06), (1.35, 0.26, 0.04), p["wood_drift"] if k == 1 else p["plank"], rotation_z=0.05 * (k - 1))
    village._growth(model, p, rng, rx, ey, ez, rz, 9, blades=4)
    # The door: one leaf hanging off askew.
    wall = hy + 0.16
    _door_frame(model, p, -wall + 0.02, base, gap, gap_top)
    _door_leaf(model, p, rng, (-gap, -wall, base + 0.02), 1, 2 * gap - 0.1, 1.74, 0.55, boards=4)
    model.box((0, -wall - 0.42, base * 0.5), (1.3, 0.55, base), p["stone_dark"])
    # A shutter hanging by one hinge, the other window boarded.
    model.box((-1.85, -wall - 0.02, 1.5), (0.82, 0.05, 0.82), p["shadow"])
    model.box((-1.58, -wall - 0.08, 1.28), (0.36, 0.04, 0.8), p["plank_dark"], rotation_z=0.0)
    model.box((1.9, -wall - 0.02, 1.5), (0.82, 0.05, 0.82), p["shadow"])
    for z, turn in ((1.72, 0.04), (1.46, -0.05), (1.24, 0.08)):
        model.box((1.9, -wall - 0.07, z), (1.0, 0.03, 0.16), p["wood_drift"])
    village._chimney(model, p, -1.7, 0.6, 2.3, 3.9)
    for k in range(5):
        model.rock((-1.7 + rng.uniform(-1.3, 2.2), -wall - 0.25, 0.1), rng.uniform(0.14, 0.24), rng.choice((p["stone_mid"], p["moss"])), rng, scale=(1.3, 0.9, 0.6))
    # Creeper and moss taking the walls at the corners.
    for k in range(9):
        x = rng.choice((-1, 1)) * rng.uniform(1.6, hx)
        village._vine(model, p, rng, (x, -wall - 0.04, rng.uniform(1.7, 2.3)), rng.uniform(0.8, 1.5), (0.0, -1.0))
    model.finish()
    kit.collision_box("FarmhouseOld", (0, 0, top / 2), (2 * hx + 0.35, 2 * hy + 0.35, top))
    village._roof_collision("FarmhouseOld", rx, ey, ez, rz)


def croft_cottage():
    """A low croft of field stone under a thick turf roof that runs nearly to the ground, its low
    door open, peat and firewood stacked at its end. About 7 m long."""
    p = palette()
    rng = random.Random(304)
    hx, hy, top, rx, ey, ez, rz = 2.9, 2.0, 1.8, 3.4, 2.75, 1.5, 3.65
    gap, gap_top = 0.5, 1.72
    model = kit.Model("CroftCottage")
    model.box((0, 0, 0.03), (2 * hx - 0.3, 2 * hy - 0.3, 0.06), p["floor"])
    model.box((0, hy - 0.2, top / 2), (2 * hx, 0.3, top), p["room"])
    for side in (-1, 1):
        model.box((side * (hx - 0.1), 0, top / 2), (0.3, 2 * hy, top), p["room"])
        model.box((side * (gap + (hx - gap) / 2), -hy + 0.2, top / 2), (hx - gap, 0.3, top), p["room"])
    model.box((0, 0, top), (2 * hx, 2 * hy, 0.08), p["room"])
    # Courses of stone, smaller going up.
    stones = (p["stone_mid"], p["stone_dark"], p["stone_light"], p["stone_mid"])
    for course in range(6):
        z = 0.2 + course * 0.3
        size = 0.3 - course * 0.018
        count = int(4 * (hx + hy) / (size * 1.45))
        for k in range(count):
            along = (k + (course % 2) * 0.5) / count * 4 * (hx + hy)
            if along < 2 * hx:
                x, y, sx, sy = -hx + along, -hy, 1.4, 0.75
            elif along < 2 * (hx + hy):
                x, y, sx, sy = hx, -hy + along - 2 * hx, 0.75, 1.4
            elif along < 4 * hx + 2 * hy:
                x, y, sx, sy = hx - (along - 2 * hx - 2 * hy), hy, 1.4, 0.75
            else:
                x, y, sx, sy = -hx, hy - (along - 4 * hx - 2 * hy), 0.75, 1.4
            if y < -hy + 0.01 and abs(x) < gap + 0.12 and z < gap_top - 0.1:
                continue
            model.rock((x, y, z), size, rng.choice(stones), rng, scale=(sx, sy, 0.68), roughness=0.1)
    # The gables in boards, under the turf.
    for side in (-1, 1):
        for k in range(int(2 * hy / 0.3)):
            y = -hy + 0.3 * (k + 0.5)
            high = rz - (rz - top) * abs(y) / hy - 0.2
            model.box((side * hx, y, (top + high) / 2), (0.05, 0.28, max(high - top, 0.02)), p[rng.choice(("plank_dark", "log_dark"))])
    village._turf_roof(model, p, rng, rx, ey, ez, rz)
    _door_frame(model, p, -hy - 0.05, 0.0, gap, gap_top)
    _door_leaf(model, p, rng, (-gap, -hy - 0.08, 0.04), 1, 2 * gap, gap_top - 0.1, 1.2, boards=4)
    model.box((0, -hy - 0.45, 0.04), (1.3, 0.6, 0.08), p["stone_mid"])
    # Inside, an ember in the dark; outside, peat stacked at the east end and a chimney of stones.
    for k in range(5):
        model.rock((rng.uniform(-0.4, 0.4), hy - 0.75, 0.16), rng.uniform(0.05, 0.08), p["ember"], rng, scale=(1, 1, 0.5))
    model.box((0, hy - 0.72, 0.1), (1.1, 0.5, 0.05), p["stone_dark"])
    village._chimney(model, p, 1.5, 0.4, 2.3, 4.05)
    for row in range(5):
        for k in range(8 - row):
            model.box((hx + 0.6, -1.3 + row * 0.16 + k * 0.34, 0.1 + row * 0.2), (0.62, 0.32, 0.19), rng.choice((p["soil"], p["log_dark"], p["soil"])), rotation_z=rng.uniform(-0.08, 0.08))
    model.finish()
    kit.collision_box("CroftCottage", (0, 0, top / 2), (2 * hx + 0.3, 2 * hy + 0.3, top))
    kit.collision_box("CroftCottagePeat", (hx + 0.6, -0.1, 0.5), (0.75, 2.7, 1.0))
    village._roof_collision("CroftCottage", rx, ey, ez, rz)


# ---- about the yard


def chicken_coop():
    """A little plank coop on legs with a turf lid, a ramp up to its hatch and straw beneath.
    About 2 m long."""
    p = palette()
    rng = random.Random(310)
    model = kit.Model("ChickenCoop")
    hx, hy = 0.95, 0.72
    for x in (-hx + 0.08, hx - 0.08):
        for y in (-hy + 0.08, hy - 0.08):
            model.cylinder((x, y, 0.0), (x, y, 0.6), 0.05, 0.045, p["bark"], segments=5)
    model.box((0, 0, 1.0), (2 * hx - 0.04, 2 * hy - 0.04, 0.82), p["log_dark"])
    wide = 0.21
    for side in (-1, 1):
        for k in range(int(2 * hx / wide)):
            x = -hx + wide * (k + 0.5)
            if side < 0 and abs(x - 0.42) < 0.2:
                continue
            model.box((x, side * hy, 1.0), (wide - 0.018, 0.04, 0.84), p[rng.choice(("plank", "plank_dark", "wood_drift"))])
        for k in range(int(2 * hy / wide)):
            model.box((side * hx, -hy + wide * (k + 0.5), 1.0), (0.04, wide - 0.018, 0.84), p[rng.choice(("plank", "plank_dark"))])
    model.box((0.42, -hy - 0.01, 0.95), (0.38, 0.04, 0.46), p["shadow"])
    model.slab([(0.3, -hy - 1.25, 0.03), (0.54, -hy - 1.25, 0.03), (0.54, -hy, 0.72), (0.3, -hy, 0.72)], 0.03, p["plank_dark"])
    for k in range(5):
        t = (k + 0.5) / 5
        model.box((0.42, -hy - 1.25 * (1 - t), 0.04 + 0.7 * t), (0.24, 0.03, 0.03), p["bark"])
    village._gable_roof(model, rng, hx + 0.16, hy + 0.2, 1.36, 1.84, 3, 4, (p["turf"], p["turf_dark"], p["moss"]), thick=0.1)
    for k in range(7):
        model.rock((rng.uniform(-0.8, 0.8), rng.uniform(-0.7, 0.7), 0.03), rng.uniform(0.16, 0.26), rng.choice((p["hay"], p["hay_old"])), rng, scale=(1.6, 1.3, 0.16), roughness=0.08)
    model.finish()
    kit.collision_box("ChickenCoop", (0, 0, 0.8), (2 * hx + 0.1, 2 * hy + 0.1, 1.6))


def hay_rack():
    """A long drying rack of the old north: stakes with rails, the hay hung over them in sheaves
    to dry, a pair of crossed stakes bracing the ends. About 5 m long."""
    p = palette()
    rng = random.Random(311)
    model = kit.Model("HayRack")
    half = 2.5
    for x in (-half, -half / 2, 0.0, half / 2, half):
        model.cylinder((x, 0, 0), (x + rng.uniform(-0.03, 0.03), 0, 1.72), 0.055, 0.04, p["bark"], segments=5)
    for x, side in ((-half, -1), (half, 1)):
        model.cylinder((x + side * 0.7, 0.06, 0), (x, 0.03, 1.2), 0.04, 0.032, p["bark"], segments=4)
    for z in (0.56, 0.98, 1.4):
        model.cylinder((-half - 0.15, 0, z), (half + 0.15, 0, z + rng.uniform(-0.03, 0.03)), 0.022, 0.022, p["wood_drift"], segments=4)
    for z, tone_set in ((1.4, ("hay", "hay_dark")), (0.98, ("hay_dark", "hay_old"))):
        x = -half + 0.05
        while x < half - 0.15:
            wide = rng.uniform(0.13, 0.2)
            hang = rng.uniform(0.28, 0.46)
            for side in (-1, 1):
                model.slab([(x, side * 0.02, z + 0.05), (x + wide, side * 0.02, z + 0.05), (x + wide, side * 0.12, z - hang), (x, side * 0.12, z - hang)], 0.05, p[rng.choice(tone_set)])
            x += wide + rng.uniform(0.06, 0.2)
    model.finish()
    kit.collision_box("HayRack", (0, 0, 0.8), (2 * half + 0.1, 0.3, 1.6))


def chopping_block():
    """A broad chopping stump with an axe left in it, split logs round it and a scatter of chips."""
    p = palette()
    rng = random.Random(312)
    model = kit.Model("ChoppingBlock")
    model.cylinder((0, 0, 0), (0, 0, 0.56), 0.34, 0.3, p["log_dark"], segments=9)
    model.cylinder((0, 0, 0.56), (0, 0, 0.58), 0.28, 0.28, p["wood_drift"], segments=9)
    model.cylinder((0.05, 0, 0.58), (0.56, -0.08, 1.02), 0.021, 0.018, p["wood_drift"], segments=4)
    model.box((0.05, 0, 0.62), (0.22, 0.03, 0.12), p["iron"], rotation_z=-0.15)
    for k in range(6):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.55, 0.95)
        x, y = math.cos(a) * d, math.sin(a) * d
        b = rng.uniform(0, math.tau)
        model.cylinder((x, y, 0.07), (x + math.cos(b) * 0.38, y + math.sin(b) * 0.38, 0.07), 0.07, 0.065, rng.choice((p["wood_drift"], p["plank"])), segments=3)
    for k in range(16):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.35, 1.25)
        model.box((math.cos(a) * d, math.sin(a) * d, 0.012), (rng.uniform(0.05, 0.12), 0.035, 0.016), p["plank"], rotation_z=rng.uniform(0, 3.1))
    model.finish()
    kit.collision_cylinder("ChoppingBlock", (0, 0, 0), (0, 0, 0.58), 0.34)


def old_plough():
    """A wooden ard left where it stopped, tipped on its share, grass coming up through it. About
    2.6 m long."""
    p = palette()
    rng = random.Random(313)
    model = kit.Model("OldPlough")
    model.cylinder((-1.0, 0, 0.06), (1.55, 0.08, 0.5), 0.05, 0.035, p["wood_drift"], segments=5)
    model.cylinder((-0.62, 0, 0.1), (-0.95, 0.03, 0.92), 0.04, 0.028, p["log_dark"], segments=5)
    model.cylinder((-1.0, 0, 0.92), (-0.86, 0.02, 0.95), 0.025, 0.02, p["wood_drift"], segments=4)
    model.cylinder((-0.92, 0, 0.14), (-1.3, 0, 0.03), 0.055, 0.02, p["iron"], segments=4)
    model.cylinder((-0.3, 0, 0.17), (-0.72, 0, 0.1), 0.035, 0.03, p["log"], segments=4)
    for k in range(14):
        model.blade((rng.uniform(-0.8, 0.8), rng.uniform(-0.25, 0.25), 0.0), rng.uniform(0, math.tau), rng.uniform(0.25, 0.48), 0.05, 0.4, rng.choice((p["leaf_mid"], p["leaf_light"], p["leaf_dry"])), segments=2)
    model.finish()
    kit.collision_box("OldPlough", (0.1, 0, 0.25), (2.5, 0.25, 0.5))


def field_cairn():
    """Stones cleared from a field and heaped at its edge, lichen on the old ones, grass at the
    foot. About 2.4 m across."""
    p = palette()
    rng = random.Random(314)
    model = kit.Model("FieldCairn")
    tones = (p["stone_mid"], p["stone_dark"], p["stone_light"], p["stone_mid"])
    for layer, (count, reach, z, size) in enumerate(((10, 1.05, 0.16, 0.3), (7, 0.66, 0.42, 0.28), (3, 0.28, 0.68, 0.25))):
        for k in range(count):
            a = math.tau * (k + rng.uniform(-0.2, 0.2)) / count
            d = reach * rng.uniform(0.78, 1.05)
            model.rock((math.cos(a) * d, math.sin(a) * d * 0.82, z), size * rng.uniform(0.85, 1.2), rng.choice(tones), rng, scale=(1.25, 0.95, 0.75), roughness=0.14)
    for k in range(4):
        a = rng.uniform(0, math.tau)
        model.rock((math.cos(a) * 0.55, math.sin(a) * 0.45, 0.5), 0.17, p["lichen"], rng, scale=(1.3, 1.0, 0.35), roughness=0.12)
    for k in range(10):
        a = rng.uniform(0, math.tau)
        model.blade((math.cos(a) * 1.25, math.sin(a) * 1.0, 0.0), a, rng.uniform(0.28, 0.5), 0.055, 0.4, rng.choice((p["leaf_mid"], p["leaf_light"], p["leaf_dry"])), segments=2)
    model.finish()
    kit.collision_cylinder("FieldCairn", (0, 0, 0), (0, 0, 0.75), 1.1, segments=8)


def aiwyk_sign():
    """The sign on the road in: a board on two forked posts on a heap of stones, under a little turf
    roof with a carved beast at each end, "WELCOME TO" and "AIWYK" cut and blackened in it in
    angular letters. Reads from -Y. About 2.8 m tall."""
    p = palette()
    rng = random.Random(320)
    model = kit.Model("AiwykSign")
    half = 1.15
    for x in (-half, half):
        model.cylinder((x, 0, 0), (x, 0, 2.36), 0.085, 0.07, p["log_dark"], segments=6)
        for k in range(8):
            a = rng.uniform(0, math.tau)
            model.rock((x + math.cos(a) * 0.32, math.sin(a) * 0.28, 0.1), rng.uniform(0.13, 0.22), rng.choice((p["stone_mid"], p["stone_dark"], p["stone_light"], p["moss"])), rng, scale=(1.2, 1.0, 0.7))
    # The board, of three planks, its ends cut to a point.
    for z, tall in ((1.92, 0.3), (1.6, 0.3), (1.28, 0.3)):
        model.box((0, 0, z), (2 * half + 0.1, 0.07, tall - 0.012), rng.choice((p["plank"], p["wood_drift"])))
    model.box((0, 0.045, 1.6), (2 * half + 0.2, 0.03, 0.08), p["log_dark"])
    _carve(model, p, "WELCOME TO", 1.87, 0.17, 0.021, -0.045)
    _carve(model, p, "AIWYK", 1.31, 0.36, 0.036, -0.045)
    # The roof.
    village._roof_plane(model, rng, (-half - 0.38, -0.42, 2.26), (half + 0.38, -0.42, 2.26), (half + 0.38, 0.0, 2.58), (-half - 0.38, 0.0, 2.58), 2, 5, (p["turf"], p["turf_dark"], p["moss"]), thick=0.1, lap=0.03)
    village._roof_plane(model, rng, (half + 0.38, 0.42, 2.26), (-half - 0.38, 0.42, 2.26), (-half - 0.38, 0.0, 2.58), (half + 0.38, 0.0, 2.58), 2, 5, (p["turf"], p["turf_dark"], p["moss"]), thick=0.1, lap=0.03)
    model.cylinder((-half - 0.4, 0, 2.6), (half + 0.4, 0, 2.6), 0.05, 0.05, p["log_dark"], segments=5)
    for facing in (-1, 1):
        village._beast(model, p, (facing * (half + 0.38), 0, 2.6), facing, 0.34)
    for x in (-half, half):
        for k in range(5):
            model.blade((x + rng.uniform(-0.45, 0.45), rng.uniform(-0.4, 0.4), 0.0), rng.uniform(0, math.tau), rng.uniform(0.3, 0.5), 0.06, 0.35, rng.choice((p["leaf_mid"], p["leaf_light"])), segments=2)
    model.finish()
    for n, x in enumerate((-half, half)):
        kit.collision_cylinder(f"AiwykSign{n}", (x, 0, 0), (x, 0, 2.4), 0.16)


# Stroke letters on a grid 1 wide and 1 tall, all straight cuts, as a knife makes them.
LETTERS = {
    "A": [[(0, 0), (0.5, 1), (1, 0)], [(0.22, 0.42), (0.78, 0.42)]],
    "C": [[(1, 0.85), (0.7, 1), (0.25, 1), (0, 0.7), (0, 0.3), (0.25, 0), (0.7, 0), (1, 0.15)]],
    "E": [[(1, 1), (0, 1), (0, 0), (1, 0)], [(0, 0.52), (0.72, 0.52)]],
    "I": [[(0.5, 0), (0.5, 1)]],
    "K": [[(0, 0), (0, 1)], [(1, 1), (0, 0.42)], [(0.3, 0.6), (1, 0)]],
    "L": [[(0, 1), (0, 0), (1, 0)]],
    "M": [[(0, 0), (0, 1), (0.5, 0.42), (1, 1), (1, 0)]],
    "O": [[(0.28, 0), (0.72, 0), (1, 0.3), (1, 0.7), (0.72, 1), (0.28, 1), (0, 0.7), (0, 0.3), (0.28, 0)]],
    "T": [[(0, 1), (1, 1)], [(0.5, 1), (0.5, 0)]],
    "W": [[(0, 1), (0.25, 0), (0.5, 0.62), (0.75, 0), (1, 1)]],
    "Y": [[(0, 1), (0.5, 0.5), (1, 1)], [(0.5, 0.5), (0.5, 0)]],
}
LETTER_WIDTHS = {"I": 0.4, "M": 1.15, "W": 1.25}


def _carve(model, p, text, z, tall, thick, y):
    """A line of text centred on x = 0, its foot at z, on a face at y looking toward -Y."""
    gap = 0.26
    total = 0.0
    for letter in text:
        total += (0.6 if letter == " " else LETTER_WIDTHS.get(letter, 0.8)) + gap
    x = -(total - gap) * tall / 2
    for letter in text:
        wide = 0.6 if letter == " " else LETTER_WIDTHS.get(letter, 0.8)
        for stroke in LETTERS.get(letter, []):
            for a, b in zip(stroke, stroke[1:]):
                # I's grid is squeezed the same as any other's.
                start = (x + a[0] * wide * tall, y, z + a[1] * tall)
                end = (x + b[0] * wide * tall, y, z + b[1] * tall)
                model.cylinder(start, end, thick, thick, p["rune"], segments=4)
        x += (wide + gap) * tall


# ---- the fence, broken


def farm_fence_down_a():
    """A length of the rail fence that's given up: one stake standing, the other snapped short, both
    rails down in the grass."""
    p = palette()
    rng = random.Random(330)
    model = kit.Model("FarmFenceDownA")
    half = farmstead.FENCE_LENGTH / 2
    farmstead._post(model, p, rng, -half + 0.03, lean=(0.08, 0.05))
    farmstead._post(model, p, rng, half - 0.03, tall=0.34)
    model.cylinder((half - 0.03, 0, 0.34), (half + 0.1, 0.12, 0.05), 0.04, 0.035, p["bark"], segments=5)
    farmstead._rail(model, p, rng, (-half + 0.02, 0.05, 0.62), (0.8, -0.28, 0.04), sag=0.02)
    farmstead._rail(model, p, rng, (-0.7, 0.3, 0.04), (half - 0.15, 0.1, 0.05), sag=0.0)
    for k in range(9):
        model.blade((rng.uniform(-half, half), rng.uniform(-0.28, 0.28), 0.0), rng.uniform(0, math.tau), rng.uniform(0.25, 0.5), 0.05, 0.4, rng.choice((p["leaf_mid"], p["leaf_light"], p["leaf_dry"])), segments=2)
    model.finish()
    kit.collision_cylinder("FarmFenceDownA", (-half + 0.03, 0, 0), (-half + 0.03, 0, 0.85), 0.09)


def farm_fence_down_b():
    """A length of the woven hurdle pushed over and sagging toward the ground, its stakes splayed."""
    p = palette()
    rng = random.Random(331)
    model = kit.Model("FarmFenceDownB")
    half = farmstead.FENCE_LENGTH / 2
    stakes = 7
    lean = 0.62
    tones = (p["wood_drift"], p["wood_drift"], p["log"], p["plank"])
    for k in range(stakes):
        x = -half + 0.05 + (2 * half - 0.1) * k / (stakes - 1)
        model.cylinder((x, 0, 0), (x + rng.uniform(-0.05, 0.05), lean + rng.uniform(-0.08, 0.08), 0.42), 0.026, 0.02, p["bark"], segments=4)
    z = 0.06
    while z < 0.4:
        y = lean * z / 0.42
        x0 = -half + 0.05
        for k in range(stakes - 1):
            x1 = x0 + (2 * half - 0.1) / (stakes - 1)
            sign = 1 if (k + int(z * 20)) % 2 else -1
            model.cylinder((x0, y + sign * 0.02, z + sign * 0.02), (x1, y - sign * 0.02, z - sign * 0.02), 0.019, 0.019, rng.choice(tones), segments=4)
            x0 = x1
        z += 0.055
    for x in (-half + 0.03, half - 0.03):
        farmstead._post(model, p, rng, x, tall=0.62, lean=(0.0, 0.14))
    for k in range(7):
        model.blade((rng.uniform(-half, half), rng.uniform(-0.2, 0.7), 0.0), rng.uniform(0, math.tau), rng.uniform(0.3, 0.55), 0.05, 0.4, rng.choice((p["leaf_mid"], p["leaf_light"])), segments=2)
    model.finish()


def farm_fence_stubs():
    """All that's left of a length: two stumps of stakes in the grass and a rail rotting between."""
    p = palette()
    rng = random.Random(332)
    model = kit.Model("FarmFenceStubs")
    half = farmstead.FENCE_LENGTH / 2
    farmstead._post(model, p, rng, -half + 0.2, tall=0.28, thick=0.06)
    farmstead._post(model, p, rng, half - 0.4, tall=0.46, thick=0.06)
    farmstead._rail(model, p, rng, (-0.5, 0.18, 0.04), (0.55, -0.1, 0.03), sag=0.0)
    model.rock((-0.1, 0.1, 0.03), 0.22, p["moss"], rng, scale=(1.8, 0.6, 0.2), roughness=0.1)
    for k in range(10):
        model.blade((rng.uniform(-half, half), rng.uniform(-0.25, 0.25), 0.0), rng.uniform(0, math.tau), rng.uniform(0.25, 0.5), 0.05, 0.4, rng.choice((p["leaf_mid"], p["leaf_light"], p["leaf_dry"])), segments=2)
    model.finish()


def farm_fence_gate():
    """A gate in the rail fence, standing open: two stout posts with a lintel of nothing, a gate of
    rails and a brace swung out on its hinge. As long as a length of fence."""
    p = palette()
    rng = random.Random(333)
    model = kit.Model("FarmFenceGate")
    half = farmstead.FENCE_LENGTH / 2
    for x in (-half + 0.05, half - 0.05):
        model.cylinder((x, 0, 0), (x, 0, 1.22), 0.1, 0.085, p["bark"], segments=6)
        model.sphere((x, 0, 1.24), 0.09, p["log_dark"], scale=(1, 1, 0.55), segments=6, rings=3)
    # Swung open away from -Y, nearly back along the fence's far side.
    hinge = (half - 0.05, 0.1)
    swing = math.radians(112)
    dx, dy = -math.cos(swing), math.sin(swing)
    wide = 2.1
    def at(t, z):
        return (hinge[0] + dx * t, hinge[1] + dy * t, z)
    for z in (0.28, 0.58, 0.88):
        model.cylinder(at(0.02, z), at(wide, z + rng.uniform(-0.03, 0.01)), 0.032, 0.028, p["wood_drift"], segments=5)
    model.cylinder(at(0.04, 0.2), at(0.04, 0.96), 0.04, 0.036, p["log_dark"], segments=5)
    model.cylinder(at(wide, 0.2), at(wide, 0.94), 0.04, 0.036, p["log_dark"], segments=5)
    model.cylinder(at(0.08, 0.26), at(wide - 0.05, 0.9), 0.028, 0.026, p["log"], segments=4)
    model.finish()
    for n, x in enumerate((-half + 0.05, half - 0.05)):
        kit.collision_cylinder(f"FarmFenceGate{n}", (x, 0, 0), (x, 0, 1.2), 0.12)


# ---- the fields between


def _field_rock(name, seed, parts, lichen=2):
    p = palette()
    rng = random.Random(seed)
    model = kit.Model(name)
    top = 0.0
    for x, y, z, r, scale, tone in parts:
        model.rock((x, y, z), r, p[tone], rng, scale=scale, subdivisions=2, roughness=0.16)
        top = max(top, z + r * scale[2])
    for k in range(lichen):
        x, y, z, r, scale, tone = rng.choice(parts)
        model.rock((x + rng.uniform(-r, r) * 0.4, y + rng.uniform(-r, r) * 0.4, z + r * scale[2] * 0.82), r * 0.42, p[rng.choice(("lichen", "moss"))], rng, scale=(1.3, 1.0, 0.24), roughness=0.1)
    for k in range(9):
        a = rng.uniform(0, math.tau)
        d = max(part[3] * part[4][0] for part in parts) * rng.uniform(0.85, 1.2)
        model.blade((math.cos(a) * d, math.sin(a) * d, 0.0), a, rng.uniform(0.2, 0.42), 0.05, 0.4, rng.choice((p["leaf_mid"], p["leaf_light"], p["leaf_dry"])), segments=2)
    model.finish()
    radius = max(abs(part[0]) + part[3] * part[4][0] for part in parts) * 0.85
    kit.collision_cylinder(name, (0, 0, 0), (0, 0, top), radius, segments=8)


def field_rock_a():
    """A long low back of grey rock breaking the turf, lichen along it."""
    _field_rock("FieldRockA", 340, [(0, 0, 0.14, 0.72, (1.6, 0.8, 0.5), "stone_mid"), (0.55, 0.12, 0.1, 0.42, (1.1, 0.9, 0.5), "stone_dark")])


def field_rock_b():
    """A squared block on end, as tall as a man's waist, with a smaller one at its foot."""
    _field_rock("FieldRockB", 341, [(0, 0, 0.5, 0.62, (0.85, 0.72, 0.95), "stone_light"), (0.62, -0.28, 0.14, 0.3, (1.1, 0.9, 0.7), "stone_dark")], lichen=3)


def field_rock_c():
    """Three stones lying together, a fallen group of the same grey."""
    _field_rock("FieldRockC", 342, [(-0.5, 0.1, 0.2, 0.42, (1.0, 0.85, 0.72), "stone_dark"), (0.25, -0.2, 0.28, 0.5, (1.05, 0.9, 0.78), "stone_mid"), (0.5, 0.48, 0.12, 0.28, (1.2, 0.9, 0.6), "stone_light")])


def _bush(model, p, rng, lumps, reach, high, tones):
    for k in range(lumps):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.0, reach)
        z = rng.uniform(high * 0.4, high)
        model.rock((math.cos(a) * d, math.sin(a) * d, z * (1.0 - d / reach * 0.45)), rng.uniform(0.32, 0.5), rng.choice(tones), rng, scale=(1.15, 1.05, 0.85), subdivisions=1, roughness=0.26)


def elder_bush():
    """An elder gone wild at a field's edge: arching stems, deep leaves, pale flat heads of
    flower. About 2.4 m tall."""
    p = palette()
    rng = random.Random(350)
    model = kit.Model("ElderBush")
    for k in range(6):
        a = rng.uniform(0, math.tau)
        model.cylinder((math.cos(a) * 0.12, math.sin(a) * 0.12, 0), (math.cos(a) * 0.72, math.sin(a) * 0.72, rng.uniform(1.3, 1.8)), 0.045, 0.02, p["bark"], segments=4)
    _bush(model, p, rng, 13, 1.0, 2.0, (p["leaf_deep"], p["leaf_mid"], p["leaf_deep"], p["ivy"]))
    for k in range(10):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.4, 1.15)
        model.sphere((math.cos(a) * d, math.sin(a) * d, rng.uniform(1.4, 2.35) - d * 0.3), rng.uniform(0.12, 0.17), p["elder_flower"], scale=(1.2, 1.2, 0.3), segments=6, rings=3)
    model.finish()


def bramble_thicket():
    """A low hump of bramble, arching canes through dark leaves and black fruit. About 2.6 m
    across and waist high."""
    p = palette()
    rng = random.Random(351)
    model = kit.Model("BrambleThicket")
    for k in range(9):
        a = rng.uniform(0, math.tau)
        out = rng.uniform(0.9, 1.45)
        points = [(math.cos(a) * 0.15, math.sin(a) * 0.15, 0.0), (math.cos(a) * out * 0.45, math.sin(a) * out * 0.45, rng.uniform(0.7, 1.0)), (math.cos(a) * out, math.sin(a) * out, 0.06)]
        for u, v in zip(points, points[1:]):
            model.cylinder(u, v, 0.022, 0.016, p["log_dark"], segments=3)
    _bush(model, p, rng, 12, 1.1, 0.72, (p["leaf_deep"], p["ivy"], p["leaf_deep"], p["leaf_mid"]))
    for k in range(26):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0.4, 1.3)
        model.sphere((math.cos(a) * d, math.sin(a) * d, rng.uniform(0.35, 1.0) * (1.25 - d * 0.6)), 0.04, p["berry"] if k % 4 else p["petal_red"], segments=4, rings=2)
    model.finish()


def thistle_patch():
    """A few tall thistles: stiff grey-green stems, spiny leaves, purple heads."""
    p = palette()
    rng = random.Random(352)
    model = kit.Model("ThistlePatch")
    for k in range(4):
        x, y = rng.uniform(-0.28, 0.28), rng.uniform(-0.28, 0.28)
        tall = rng.uniform(0.72, 1.05)
        model.cylinder((x, y, 0), (x + rng.uniform(-0.04, 0.04), y + rng.uniform(-0.04, 0.04), tall), 0.014, 0.01, p["leaf_mid"], segments=3, caps=False)
        for n in range(3):
            model.blade((x, y, tall * rng.uniform(0.08, 0.5)), rng.uniform(0, math.tau), rng.uniform(0.2, 0.32), 0.075, 1.2, rng.choice((p["leaf_mid"], p["leaf_deep"])), segments=2)
        model.sphere((x, y, tall), 0.045, p["leaf_deep"], scale=(1, 1, 1.15), segments=4, rings=2)
        model.sphere((x, y, tall + 0.05), 0.04, p["thistle"], scale=(1, 1, 0.75), segments=4, rings=2)
    model.finish()


def nettle_patch():
    """A stand of nettles, the sign of old dung and old houses."""
    p = palette()
    rng = random.Random(353)
    model = kit.Model("NettlePatch")
    for k in range(7):
        x, y = rng.uniform(-0.34, 0.34), rng.uniform(-0.34, 0.34)
        tall = rng.uniform(0.6, 0.95)
        model.cylinder((x, y, 0), (x, y, tall), 0.012, 0.007, p["leaf_deep"], segments=3, caps=False)
        for n in range(3):
            z = tall * (0.45 + n * 0.25)
            a = rng.uniform(0, math.tau)
            for side in (0.0, math.pi):
                model.blade((x, y, z), a + side, 0.14, 0.07, 1.3, p["leaf_deep"] if n else p["leaf_mid"], segments=2)
    model.finish()


def dock_weeds():
    """Docks gone to rust-red seed over broad low leaves, with white yarrow among them."""
    p = palette()
    rng = random.Random(354)
    model = kit.Model("DockWeeds")
    for k in range(3):
        x, y = rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25)
        tall = rng.uniform(0.75, 1.1)
        model.cylinder((x, y, 0), (x, y, tall), 0.012, 0.008, p["dock"], segments=3, caps=False)
        for n in range(5):
            model.sphere((x, y, tall * (0.62 + n * 0.09)), 0.035 - n * 0.003, p["dock"], scale=(1, 1, 1.5), segments=4, rings=2)
        for n in range(3):
            model.blade((x, y, 0.0), rng.uniform(0, math.tau), 0.34, 0.13, 1.0, p["leaf_mid"], segments=2)
    for k in range(3):
        x, y = rng.uniform(-0.38, 0.38), rng.uniform(-0.38, 0.38)
        tall = rng.uniform(0.42, 0.6)
        model.cylinder((x, y, 0), (x, y, tall), 0.008, 0.006, p["leaf_light"], segments=3, caps=False)
        model.sphere((x, y, tall), 0.075, p["petal_white"], scale=(1, 1, 0.28), segments=5, rings=2)
    model.finish()


BUILDERS = {fn.__name__: fn for fn in (
    farmhouse_open, farm_barn, farmhouse_old, croft_cottage, chicken_coop, hay_rack, chopping_block,
    old_plough, field_cairn, aiwyk_sign, farm_fence_down_a, farm_fence_down_b, farm_fence_stubs,
    farm_fence_gate, field_rock_a, field_rock_b, field_rock_c, elder_bush, bramble_thicket,
    thistle_patch, nettle_patch, dock_weeds,
)}


def make(slug):
    """Builds and exports one asset of the family."""
    kit.clear_scene()
    BUILDERS[slug]()
    path = kit.export(slug)
    kit.report(slug, path)
