"""MilitaryTent: A medieval army's pavilion: a round wall of weathered canvas, a conical roof on a stout pole with a red crown and red seams, a scalloped red valance, its door flaps tied back on the dark, guy ropes to pegs and a pennant on top. About 7 m across and 5.5 m tall. Reads from -Y. Part of the south bank family (tools/blender/southbank.py).
Brief: "cover R6 - F20 and F19 with bushes and some tall poplars. also put white poplars on D20 C20. on D19 put a new medieval military tent. put some rocks and foliage around. also on surrounding sectors, f.e. E18. create new assets in blender if needed and for some diversity. you can also create some other decortive assets on ground founable near rivers or forests." Everything beyond that is placeholder.
Build: npm run models -- military_tent

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import southbank  # noqa: E402

if __name__ == "__main__":
    southbank.make("military_tent")
