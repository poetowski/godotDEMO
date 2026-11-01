"""FieldCairn: Stones cleared from a field and heaped at its edge, lichen on the old ones, grass at the foot. About 2.4 m across. Part of the homestead family (tools/blender/homestead.py).
Brief: "put farm house in H9 rotated with open doors to south. then design a farm space by fences at H8 and maybe a bit to G8 and G9. further new farms can be with broken fence or even somewhere without fence. generate new assets in blender. will emoty places around with rocks, foliage etc." and "you can even design a sign Welcome to Aiwik and place it before entrance to village from the bridge site road" (Aiwyk is the right spelling). Everything beyond that is placeholder.
Build: npm run models -- field_cairn

Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import homestead  # noqa: E402

if __name__ == "__main__":
    homestead.make("field_cairn")
