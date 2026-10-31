"""FallenAlder: An alder fallen from the bank into the lake, roots in the air, about 6 m long. Part of the riverside family (tools/blender/riverside.py).
Brief: "decorate surroundings of lake with our assets and if needed generate more.". Everything beyond that is placeholder.
Build: npm run models -- fallen_alder

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import riverside  # noqa: E402

if __name__ == "__main__":
    riverside.make("fallen_alder")
