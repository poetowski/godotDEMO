"""Alchemist's column: a ~2 m stand of medieval alchemy glassware. A dark
wooden column on a stone plinth carries three round brass-bound shelves of
flasks and stoppered bottles of glowing potions; a copper alembic on top
feeds pipes down from flask to flask, ending in a big round flask over a
small burner of glowing coals. Brief: "alchemist column system medieval
flasks, whole object size around 2m". Look, layout and colours are
placeholders. Build: npm run models -- alchemist_column
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit  # noqa: E402

SLUG = "alchemist_column"
HEIGHT = 2.0
# (height, radius) of each shelf, bottom to top.
SHELVES = [(0.8, 0.34), (1.18, 0.29), (1.5, 0.23)]
POTIONS = [
    ((0.35, 0.85, 0.35), (0.3, 1.0, 0.35)),   # green
    ((0.62, 0.3, 0.88), (0.7, 0.35, 1.0)),    # violet
    ((0.95, 0.62, 0.18), (1.0, 0.65, 0.2)),   # amber
    ((0.85, 0.18, 0.2), (1.0, 0.25, 0.25)),   # red
    ((0.25, 0.55, 0.95), (0.3, 0.6, 1.0)),    # blue
]


def flask_profile(kind, size):
    """(radius, height) points from the bottom up, for a flask `size` tall."""
    s = size
    if kind == "round":
        return [(0.0, 0.0), (0.18 * s, 0.02 * s), (0.3 * s, 0.12 * s), (0.33 * s, 0.26 * s), (0.28 * s, 0.42 * s),
                (0.12 * s, 0.55 * s), (0.08 * s, 0.6 * s), (0.08 * s, 0.92 * s), (0.11 * s, 0.96 * s), (0.1 * s, 1.0 * s)]
    if kind == "cone":
        return [(0.0, 0.0), (0.3 * s, 0.01 * s), (0.32 * s, 0.06 * s), (0.12 * s, 0.6 * s), (0.08 * s, 0.68 * s),
                (0.08 * s, 0.92 * s), (0.1 * s, 1.0 * s)]
    # A tall bottle with shoulders.
    return [(0.0, 0.0), (0.16 * s, 0.01 * s), (0.17 * s, 0.05 * s), (0.17 * s, 0.6 * s), (0.12 * s, 0.7 * s),
            (0.06 * s, 0.76 * s), (0.06 * s, 0.95 * s), (0.075 * s, 1.0 * s)]


def liquid_profile(profile, fill):
    """The liquid inside a flask: the profile shrunk a little, cut at `fill`
    of the glass's height."""
    top = profile[-1][1] * fill
    inner = []
    for (r0, h0), (r1, h1) in zip(profile, profile[1:]):
        if h0 > top:
            break
        inner.append((max(r0 * 0.88, 0.0), h0 + 0.004))
        if h1 > top:
            t = (top - h0) / max(h1 - h0, 1e-6)
            inner.append(((r0 + (r1 - r0) * t) * 0.88, top))
            break
    return inner


def add_flask(model, glass, cork, at, kind, size, potion, fill, stopper):
    profile = flask_profile(kind, size)
    model.lathe(profile, glass, segments=12, centre=at)
    inner = liquid_profile(profile, fill)
    if len(inner) >= 2:
        model.lathe(inner, potion, segments=12, centre=(at[0], at[1], at[2]))
    if stopper:
        neck = profile[-1]
        model.cylinder((at[0], at[1], at[2] + neck[1] - 0.01), (at[0], at[1], at[2] + neck[1] + 0.03),
                       neck[0] * 0.9, neck[0] * 1.05, cork, segments=8)
    return profile[-1][1]


def build():
    rng = random.Random(7)
    stone = kit.material("Stone", (0.5, 0.48, 0.45), roughness=0.9)
    wood = kit.material("DarkWood", (0.3, 0.2, 0.13), roughness=0.85)
    brass = kit.material("Brass", (0.78, 0.6, 0.28), roughness=0.4, metallic=0.85)
    copper = kit.material("Copper", (0.74, 0.42, 0.26), roughness=0.35, metallic=0.9)
    iron = kit.material("Iron", (0.22, 0.22, 0.24), roughness=0.6, metallic=0.7)
    glass = kit.material("Glass", (0.85, 0.93, 0.95), roughness=0.08, alpha=0.32)
    cork = kit.material("Cork", (0.62, 0.48, 0.32), roughness=0.95)
    coals = kit.material("Coals", (0.9, 0.35, 0.1), roughness=0.9, emission=(1.0, 0.4, 0.1), emission_strength=3.0)
    potions = [kit.material("Potion%d" % k, base, roughness=0.2, emission=glow, emission_strength=0.8) for k, (base, glow) in enumerate(POTIONS)]

    model = kit.Model("AlchemistColumn")
    # Plinth: an octagonal stone step and a smaller one on it.
    model.cylinder((0, 0, 0), (0, 0, 0.1), 0.42, 0.4, stone, segments=8)
    model.cylinder((0, 0, 0.1), (0, 0, 0.16), 0.3, 0.28, stone, segments=8)
    # The column, with brass rings.
    model.cylinder((0, 0, 0.16), (0, 0, 1.82), 0.055, 0.045, wood, segments=8)
    for z in (0.3, 0.9, 1.3, 1.7):
        model.cylinder((0, 0, z - 0.015), (0, 0, z + 0.015), 0.065, 0.065, brass, segments=8)
    # Shelves: wooden discs with a brass rim, a little lip to hold the glass.
    for height, radius in SHELVES:
        model.cylinder((0, 0, height - 0.03), (0, 0, height), radius, radius, wood, segments=14)
        model.cylinder((0, 0, height), (0, 0, height + 0.025), radius + 0.005, radius + 0.005, brass, segments=14, caps=False)
        # Three brackets under each shelf.
        for k in range(3):
            angle = math.tau * k / 3 + 0.4
            tip = (math.cos(angle) * radius * 0.7, math.sin(angle) * radius * 0.7, height - 0.03)
            model.tube([(math.cos(angle) * 0.05, math.sin(angle) * 0.05, height - 0.16), tip], 0.012, brass, segments=5)
    # Glassware on the shelves, around the column.
    flask_tops = []
    for tier, (height, radius) in enumerate(SHELVES):
        count = 5 - tier
        for k in range(count):
            angle = math.tau * (k + 0.5 * tier) / count
            reach = radius * rng.uniform(0.58, 0.72)
            at = (math.cos(angle) * reach, math.sin(angle) * reach, height)
            kind = ("round", "cone", "bottle")[(k + tier) % 3]
            size = rng.uniform(0.16, 0.24) if kind != "bottle" else rng.uniform(0.2, 0.28)
            # Smaller glass on the top shelf, under the alembic.
            size *= 0.8 if tier == len(SHELVES) - 1 else 1.0
            potion = potions[(k * 2 + tier) % len(potions)]
            top = add_flask(model, glass, cork, at, kind, size, potion, rng.uniform(0.35, 0.6), kind == "bottle")
            flask_tops.append((at[0], at[1], at[2] + top))
    # The alembic: a copper pot and its domed head on top of the column, a
    # beak pointing out and down.
    model.cylinder((0, 0, 1.82), (0, 0, 1.86), 0.09, 0.1, copper, segments=12)
    model.lathe([(0.1, 0.0), (0.13, 0.04), (0.13, 0.1), (0.09, 0.16), (0.03, 0.2), (0.0, 0.21)], copper, segments=12, centre=(0, 0, 1.86))
    beak_start = (0.1, 0.0, 1.98)
    beak_end = (0.3, 0.0, 1.9)
    model.cylinder(beak_start, beak_end, 0.025, 0.012, copper, segments=6)
    # Pipes down the column from the beak, through a flask on each shelf.
    first_top = min(flask_tops[-2:], key=lambda p: (p[0] - beak_end[0]) ** 2 + (p[1] - beak_end[1]) ** 2)
    model.tube([beak_end, (beak_end[0] + 0.02, beak_end[1], first_top[2] + 0.08), (first_top[0], first_top[1], first_top[2] + 0.06), first_top], 0.008, copper)
    middle_top = flask_tops[5]
    model.tube([first_top, (first_top[0] * 1.15, first_top[1] * 1.15, middle_top[2] + 0.12), (middle_top[0], middle_top[1], middle_top[2] + 0.05), middle_top], 0.008, copper)
    # The big flask over the burner on the plinth, fed from the lowest shelf.
    burner_at = (0.0, -0.24, 0.16)
    model.cylinder(burner_at, (burner_at[0], burner_at[1], 0.22), 0.07, 0.09, iron, segments=8)
    for k in range(6):
        angle = math.tau * k / 6
        model.sphere((burner_at[0] + math.cos(angle) * 0.04, burner_at[1] + math.sin(angle) * 0.04, 0.225), 0.025, coals, segments=6, rings=4)
    for k in range(3):
        angle = math.tau * k / 3
        foot = (burner_at[0] + math.cos(angle) * 0.1, burner_at[1] + math.sin(angle) * 0.1)
        model.tube([(foot[0], foot[1], 0.16), (foot[0] * 0.8 + burner_at[0] * 0.2, foot[1] * 0.8 + burner_at[1] * 0.2, 0.3)], 0.008, iron, segments=4)
    big_at = (burner_at[0], burner_at[1], 0.3)
    big_top = add_flask(model, glass, cork, big_at, "round", 0.3, potions[0], 0.45, False)
    low_top = flask_tops[0]
    model.tube([middle_top, (middle_top[0], middle_top[1], low_top[2] + 0.1), (big_at[0], big_at[1], big_at[2] + big_top + 0.05), (big_at[0], big_at[1], big_at[2] + big_top)], 0.008, copper)
    model.finish()
    kit.collision_cylinder("AlchemistColumn", (0, 0, 0), (0, 0, HEIGHT), 0.38)


def main():
    kit.clear_scene()
    build()
    path = kit.export(SLUG)
    kit.report(SLUG, path)


if __name__ == "__main__":
    main()
