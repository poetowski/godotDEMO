"""MeadowGrassA: A low clump of the field's grass. Part of the farmstead family (tools/blender/farmstead.py).
Brief: "create few more assets to diversify, like some flowers ambient. or moss or some big boulder.". Everything beyond that is placeholder.
Build: npm run models -- meadow_grass_a

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import farmstead  # noqa: E402

if __name__ == "__main__":
    farmstead.make("meadow_grass_a")
