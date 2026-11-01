"""MossPatch: A low cushion of moss on the ground, about 1.2 m across. Part of the farmstead family (tools/blender/farmstead.py).
Brief: "create few more assets to diversify, like some flowers ambient. or moss or some big boulder.". Everything beyond that is placeholder.
Build: npm run models -- moss_patch

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import farmstead  # noqa: E402

if __name__ == "__main__":
    farmstead.make("moss_patch")
