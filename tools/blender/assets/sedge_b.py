"""SedgeB: A fuller arching tuft of sedge, about 60 cm. Part of the riverside family (tools/blender/riverside.py).
Brief: "generate several variations of decorative assets which then place near water in R1, f.e. create several small stones, then some water lillies, some grass living near water, and some other objects". Everything beyond that is placeholder.
Build: npm run models -- sedge_b

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import riverside  # noqa: E402

if __name__ == "__main__":
    riverside.make("sedge_b")
