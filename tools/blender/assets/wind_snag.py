"""WindSnag: A bleached dead tree on the ravine's rim, bent by the wind, about 4.5 m tall. Part of the riverside family (tools/blender/riverside.py).
Brief: "use decorative skill, extend river and make waterfall into ravine on west. decorate surrounding of river and its delta before waterfall. create new assets in blender if needed.". Everything beyond that is placeholder.
Build: npm run models -- wind_snag

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import riverside  # noqa: E402

if __name__ == "__main__":
    riverside.make("wind_snag")
