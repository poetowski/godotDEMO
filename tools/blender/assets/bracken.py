"""Bracken: A knee-high clump of bracken, some of it gone brown. Part of the wildwood family (tools/blender/wildwood.py).
Brief: "generate forest in R8 west from orchard ... generate more trees in blender and place them in R8 up to western cliff, put there some rocks. in R8 sector R3 and R2 i want to have semi abandoned camp with campfire, generate assets in blender and then place them there.". Everything beyond that is placeholder.
Build: npm run models -- bracken

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import wildwood  # noqa: E402

if __name__ == "__main__":
    wildwood.make("bracken")
