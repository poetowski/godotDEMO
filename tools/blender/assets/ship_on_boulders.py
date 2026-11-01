"""ShipOnBoulders: A clinker longship thrown up on a heap of boulders and left there: heeled over, bow in the air, a hole stove in its low side with the ribs showing, the mast snapped and the torn sail hanging from the fallen yard, a dragon still on the stem. About 14 m long. Part of the shoreside family (tools/blender/shoreside.py).
Brief: "in region R1 in sectors A2 B2 C2 C3 D3 F3 F5 H4 H5 I6 j5 j6 add some wet dirt as ground. generate new assets in blender to fill this like near side items. you can put some fishing stuff there and nearby. stay consistent and creative, also put some rocks there and maybe some shipwreck or something and ship on boulders, some knife and hammers on ground." Everything beyond that is placeholder.
Build: npm run models -- ship_on_boulders

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import shoreside  # noqa: E402

if __name__ == "__main__":
    shoreside.make("ship_on_boulders")
