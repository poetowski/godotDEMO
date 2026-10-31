"""LanternPost: A lantern on a wooden post, about 2.2 m. Its light is NightLight, in the game. Part of the riverside family (tools/blender/riverside.py).
Brief: "also generate lantern asset in blender which emits some light during night and create few variants you can put them near bridge.". Everything beyond that is placeholder.
Build: npm run models -- lantern_post

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import riverside  # noqa: E402

if __name__ == "__main__":
    riverside.make("lantern_post")
