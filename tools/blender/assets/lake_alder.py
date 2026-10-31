"""LakeAlder: A full-grown alder standing back from the lake's shore, about 6.5 m tall. Part of the riverside family (tools/blender/riverside.py).
Brief: "decorate surroundings of lake with our assets and if needed generate more.". Everything beyond that is placeholder.
Build: npm run models -- lake_alder

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import riverside  # noqa: E402

if __name__ == "__main__":
    riverside.make("lake_alder")
