"""Farmhouse: A small log farmhouse, 7 x 5 m and about 5 m to its chimney, shuttered, under a roof of hay with grass in it. Part of the farmstead family (tools/blender/farmstead.py).
Brief: "this place his for  a farm house small from wood with closed widows and some grass and hay on roof.". Everything beyond that is placeholder.
Build: npm run models -- farmhouse

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import farmstead  # noqa: E402

if __name__ == "__main__":
    farmstead.make("farmhouse")
