"""NetHeap: A wet heap of net dumped on the ground, floats and a stone sinker showing. About 2 m across. Part of the shoreside family (tools/blender/shoreside.py).
Brief: "in region R1 in sectors A2 B2 C2 C3 D3 F3 F5 H4 H5 I6 j5 j6 add some wet dirt as ground. generate new assets in blender to fill this like near side items. you can put some fishing stuff there and nearby. stay consistent and creative, also put some rocks there and maybe some shipwreck or something and ship on boulders, some knife and hammers on ground." Everything beyond that is placeholder.
Build: npm run models -- net_heap

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import shoreside  # noqa: E402

if __name__ == "__main__":
    shoreside.make("net_heap")
