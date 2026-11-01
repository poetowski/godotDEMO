"""GardenBed: A kitchen garden behind a low wattle edge: rows of leeks, cabbages and herbs in dark Part of the village family (tools/blender/village.py).
Brief: "create assets of village houses in blender, also create one overgrown church, not christian but little nordic. put some decorations around the village ... put a farm with fences and small shed in J8". Everything beyond that is placeholder.
Build: npm run models -- garden_bed

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import village  # noqa: E402

if __name__ == "__main__":
    village.make("garden_bed")
