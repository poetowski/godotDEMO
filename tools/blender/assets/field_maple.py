"""FieldMaple: A round field maple, about 8 m, warm yellow-green. Part of the woodland family (tools/blender/woodland.py).
Brief: "also generate some new trees variations and some bigger trees maybe as well.". Everything beyond that is placeholder.
Build: npm run models -- field_maple

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import woodland  # noqa: E402

if __name__ == "__main__":
    woodland.make("field_maple")
