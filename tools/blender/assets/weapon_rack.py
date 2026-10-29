"""Weapon rack: a long oak rack under a small shingled roof, a plank back
wall hung with painted round and tower shields, and spears standing in front
of them between two rails. Brief: "weaponry rack 4m width 3m tall,
containing some spears and shields behind them". Everything beyond the size,
spears and shields is placeholder. Build: npm run models -- weapon_rack

Metres, Z up, base at Z = 0, front toward -Y.
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit  # noqa: E402

SLUG = "weapon_rack"
WIDTH = 4.0
POST_HEIGHT = 2.7
BACK_Y = 0.22
SHIELD_Y = 0.15
SPEAR_Y = -0.08
RAIL_Y = -0.15


def frame(model, oak, dark, iron, shingle):
    half = WIDTH / 2
    for x in (-half + 0.08, 0.0, half - 0.08):
        model.box((x, 0.05, POST_HEIGHT / 2), (0.16, 0.5, POST_HEIGHT), oak)
        model.box((x, 0.05, 0.06), (0.24, 0.6, 0.12), dark)
    # Back wall of planks, with iron bands.
    planks = 13
    for k in range(planks):
        x = -half + 0.16 + (WIDTH - 0.32) * (k + 0.5) / planks
        tone = oak if k % 2 else dark
        model.box((x, BACK_Y, 1.45), ((WIDTH - 0.32) / planks - 0.01, 0.05, 2.3), tone)
    for z in (0.6, 2.3):
        model.box((0, BACK_Y - 0.03, z), (WIDTH - 0.3, 0.02, 0.06), iron)
    # Base plank the spears stand on, and the two rails holding them.
    model.box((0, -0.05, 0.2), (WIDTH, 0.4, 0.08), dark)
    for z in (0.42, 2.34):
        model.box((0, RAIL_Y, z), (WIDTH - 0.1, 0.07, 0.1), oak)
    # Top beam and a small roof of shingles, pitched toward the front.
    model.box((0, 0.05, POST_HEIGHT + 0.06), (WIDTH + 0.2, 0.55, 0.12), dark)
    for row in range(4):
        y = 0.36 - row * 0.17
        z = POST_HEIGHT + 0.24 - row * 0.045
        for k in range(16):
            x = -WIDTH / 2 - 0.1 + (WIDTH + 0.2) * (k + 0.5) / 16
            model.box((x, y, z), ((WIDTH + 0.2) / 16 - 0.015, 0.28, 0.04), shingle)
    model.box((0, 0.4, POST_HEIGHT + 0.2), (WIDTH + 0.2, 0.1, 0.18), dark)


def round_shield(model, x, z, radius, face, iron, stripe=None):
    back = (x, SHIELD_Y + 0.02, z)
    model.cylinder(back, (x, SHIELD_Y - 0.02, z), radius, radius, iron, segments=16)
    model.cylinder((x, SHIELD_Y - 0.02, z), (x, SHIELD_Y - 0.04, z), radius - 0.04, radius - 0.04, face, segments=16)
    if stripe is not None:
        model.box((x, SHIELD_Y - 0.045, z), (radius * 1.8, 0.01, 0.1), stripe)
        model.box((x, SHIELD_Y - 0.045, z), (0.1, 0.01, radius * 1.8), stripe)
    model.sphere((x, SHIELD_Y - 0.05, z), 0.08, iron, scale=(1, 0.6, 1), segments=8, rings=5)
    model.box((x, BACK_Y - 0.04, z + radius - 0.05), (0.04, 0.06, 0.04), iron)


def tower_shield(model, x, z, face, iron, stripe):
    model.box((x, SHIELD_Y, z), (0.62, 0.04, 1.05), iron)
    model.box((x, SHIELD_Y - 0.025, z), (0.54, 0.02, 0.97), face)
    model.box((x, SHIELD_Y - 0.04, z), (0.1, 0.01, 0.97), stripe)
    model.sphere((x, SHIELD_Y - 0.05, z), 0.07, iron, scale=(1, 0.6, 1), segments=8, rings=5)


def spear(model, x, lean, shaft, iron, rng):
    foot = (x, SPEAR_Y, 0.24)
    length = 2.0 + rng.uniform(-0.15, 0.15)
    tip = (x + math.sin(lean) * length, SPEAR_Y + 0.02, 0.24 + math.cos(lean) * length)
    model.cylinder(foot, tip, 0.022, 0.018, shaft, segments=6)
    direction = [(tip[i] - foot[i]) / length for i in range(3)]
    socket = tuple(tip[i] + direction[i] * 0.06 for i in range(3))
    point = tuple(tip[i] + direction[i] * 0.34 for i in range(3))
    model.cylinder(tip, socket, 0.024, 0.03, iron, segments=6)
    model.cylinder(socket, point, 0.045, 0.0, iron, segments=4)
    model.cylinder((x, SPEAR_Y, 0.16), foot, 0.02, 0.022, iron, segments=6)


def build():
    rng = random.Random(7)
    oak = kit.material("Oak", (0.45, 0.31, 0.19), roughness=0.85)
    dark = kit.material("DarkOak", (0.3, 0.2, 0.13), roughness=0.9)
    iron = kit.material("Iron", (0.36, 0.36, 0.38), roughness=0.45, metallic=0.8)
    shingle = kit.material("Shingle", (0.34, 0.27, 0.22), roughness=0.95)
    shaft = kit.material("Ash", (0.62, 0.48, 0.32), roughness=0.8)
    red = kit.material("ShieldRed", (0.62, 0.14, 0.12))
    blue = kit.material("ShieldBlue", (0.16, 0.26, 0.5))
    ochre = kit.material("ShieldOchre", (0.78, 0.58, 0.2))
    green = kit.material("ShieldGreen", (0.2, 0.38, 0.22))
    cream = kit.material("Cream", (0.88, 0.82, 0.68))

    model = kit.Model("WeaponRack")
    frame(model, oak, dark, iron, shingle)
    round_shield(model, -1.45, 1.75, 0.42, red, iron, cream)
    tower_shield(model, -0.62, 1.55, blue, iron, ochre)
    round_shield(model, 0.55, 1.9, 0.4, ochre, iron)
    round_shield(model, 1.4, 1.55, 0.38, green, iron, cream)
    round_shield(model, 0.95, 0.95, 0.3, blue, iron)
    round_shield(model, -1.2, 0.85, 0.32, cream, iron, red)
    for k in range(11):
        x = -1.75 + 3.5 * k / 10 + rng.uniform(-0.05, 0.05)
        spear(model, x, rng.uniform(-0.05, 0.05), shaft, iron, rng)
    model.finish()
    kit.collision_box("WeaponRack", (0, 0.05, 1.5), (WIDTH, 0.65, 3.0))


def main():
    kit.clear_scene()
    build()
    path = kit.export(SLUG)
    kit.report(SLUG, path)


if __name__ == "__main__":
    main()
