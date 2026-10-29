"""<Name>: <one or two sentences on what it is>. Brief: "<the author's
brief, verbatim>". <What is placeholder.> Build: npm run models -- <slug>

Template for /asset-design. Copy to tools/blender/assets/<slug>.py.
Metres, Z up, base at Z = 0, front toward -Y.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import kit  # noqa: E402

SLUG = "<slug>"


def build():
    wood = kit.material("Wood", (0.42, 0.29, 0.18), roughness=0.85)
    model = kit.Model("<PascalName>")
    model.box((0, 0, 0.4), (0.8, 0.5, 0.8), wood)
    model.finish()
    kit.collision_box("<PascalName>", (0, 0, 0.4), (0.8, 0.5, 0.8))


def main():
    kit.clear_scene()
    build()
    path = kit.export(SLUG)
    kit.report(SLUG, path)


if __name__ == "__main__":
    main()
