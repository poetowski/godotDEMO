"""VillageHouseC: A small cottage of logs below and boards in the gable, under old hay, with a lean-to Part of the village family (tools/blender/village.py).
Brief: "create assets of village houses in blender, also create one overgrown church, not christian but little nordic. put some decorations around the village ... put a farm with fences and small shed in J8". Everything beyond that is placeholder.
Build: npm run models -- village_house_c

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import village  # noqa: E402

if __name__ == "__main__":
    village.make("village_house_c")
