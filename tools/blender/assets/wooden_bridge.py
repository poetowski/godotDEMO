"""WoodenBridge: A curved log bridge, 21 m long, with small fences and columns in the water. Part of the riverside family (tools/blender/riverside.py).
Brief: "generate new asset in blender. it is wooden curven bridge with small fences, some logs might be missing, few columns in the water.". Everything beyond that is placeholder.
Build: npm run models -- wooden_bridge

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import riverside  # noqa: E402

if __name__ == "__main__":
    riverside.make("wooden_bridge")
