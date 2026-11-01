"""HayStack: A stack of hay round a pole, about 2.2 m. Part of the farmstead family (tools/blender/farmstead.py).
Brief: "create few more assets to diversify, like some flowers ambient. or moss or some big boulder.". Everything beyond that is placeholder.
Build: npm run models -- hay_stack

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import farmstead  # noqa: E402

if __name__ == "__main__":
    farmstead.make("hay_stack")
