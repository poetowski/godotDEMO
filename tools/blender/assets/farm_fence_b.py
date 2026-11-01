"""FarmFenceB: A low woven hurdle of rods round stakes, 2.4 m long. Part of the farmstead family (tools/blender/farmstead.py).
Brief: "and some low medieval wooden primitive fences.". Everything beyond that is placeholder.
Build: npm run models -- farm_fence_b

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import farmstead  # noqa: E402

if __name__ == "__main__":
    farmstead.make("farm_fence_b")
