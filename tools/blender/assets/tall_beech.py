"""TallBeech: A tall beech, about 15 m, with a long smooth grey trunk. Part of the woodland family (tools/blender/woodland.py).
Brief: "also generate some new trees variations and some bigger trees maybe as well.". Everything beyond that is placeholder.
Build: npm run models -- tall_beech

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import woodland  # noqa: E402

if __name__ == "__main__":
    woodland.make("tall_beech")
