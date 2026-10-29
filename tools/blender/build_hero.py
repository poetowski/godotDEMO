"""Builds the hero: a low-poly body skinned to a humanoid skeleton, and its
animations, exported to assets/models/hero/hero.glb. Run it through
`npm run models`, which starts Blender headless with factory settings:

    blender --background --factory-startup --python tools/blender/build_hero.py

Bones use the names of Godot's SkeletonProfileHumanoid, so animations made
elsewhere (bought, Mixamo) can be retargeted onto the hero later. The body
faces -Y here, +Z after export (glTF), and the player turns it to face -Z.
Every bone is rolled so that rotating it about its own X axis pitches it
forward (limbs swing forward, the spine bows); see `pose()` for the other
axes. Look and motion are placeholders.
"""
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUTPUT = os.path.join(ROOT, "assets", "models", "hero", "hero.glb")
FPS = 30

# The colours the hero had as primitives (sRGB), kept so it looks the same.
COLORS = {
    "Tunic": (0.18, 0.42, 0.30),
    "Trousers": (0.36, 0.27, 0.20),
    "Skin": (0.92, 0.74, 0.60),
    "Hair": (0.30, 0.19, 0.10),
    "Leather": (0.24, 0.15, 0.09),
    "Eye": (0.08, 0.08, 0.10),
}
MATERIALS = list(COLORS)

# name: (head, tail, parent, connected). Left is +X (the body faces -Y).
SHOULDER_X = 0.30
HIP_X = 0.11
BONES = {
    "Root": ((0, 0, 0), (0, 0, 0.2), None, False),
    "Hips": ((0, 0, 0.86), (0, 0, 1.0), "Root", False),
    "Spine": ((0, 0, 1.0), (0, 0, 1.18), "Hips", True),
    "Chest": ((0, 0, 1.18), (0, 0, 1.42), "Spine", True),
    "Neck": ((0, 0, 1.42), (0, 0, 1.52), "Chest", True),
    "Head": ((0, 0, 1.52), (0, 0, 1.86), "Neck", True),
}
for side, sign in (("Left", 1.0), ("Right", -1.0)):
    x = SHOULDER_X * sign
    BONES.update({
        f"{side}Shoulder": ((0.06 * sign, 0, 1.38), (x, 0, 1.41), "Chest", False),
        f"{side}UpperArm": ((x, 0, 1.41), (x, 0, 1.13), f"{side}Shoulder", True),
        f"{side}LowerArm": ((x, 0, 1.13), (x, 0, 0.88), f"{side}UpperArm", True),
        f"{side}Hand": ((x, 0, 0.88), (x, 0, 0.78), f"{side}LowerArm", True),
        f"{side}UpperLeg": ((HIP_X * sign, 0, 0.84), (HIP_X * sign, 0, 0.46), "Hips", False),
        f"{side}LowerLeg": ((HIP_X * sign, 0, 0.46), (HIP_X * sign, 0, 0.10), f"{side}UpperLeg", True),
        f"{side}Foot": ((HIP_X * sign, 0, 0.10), (HIP_X * sign, -0.12, 0.03), f"{side}LowerLeg", True),
        f"{side}Toes": ((HIP_X * sign, -0.12, 0.03), (HIP_X * sign, -0.19, 0.03), f"{side}Foot", True),
    })


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def smoothstep(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS


def make_materials():
    made = []
    for name in MATERIALS:
        material = bpy.data.materials.new(name)
        linear = tuple(srgb_to_linear(c) for c in COLORS[name])
        material.diffuse_color = (*linear, 1.0)
        if material.node_tree is None:
            material.use_nodes = True
        bsdf = material.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (*linear, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.4 if name == "Eye" else 0.85
        made.append(material)
    return made


# --- The body -------------------------------------------------------------

class Body:
    """One bmesh for the whole body. Every part adds a primitive, colours its
    faces and weights its vertices to bones."""

    def __init__(self):
        self.bm = bmesh.new()
        self.deform = self.bm.verts.layers.deform.verify()
        self.groups = list(BONES)

    def add(self, verts, material, weigh):
        """`weigh(co)` gives {bone: weight} for a vertex position."""
        faces = set()
        for vert in verts:
            for bone, weight in weigh(vert.co).items():
                if weight > 0.0:
                    vert[self.deform][self.groups.index(bone)] = weight
            faces.update(vert.link_faces)
        for face in faces:
            face.material_index = MATERIALS.index(material)

    def cylinder(self, bottom, top, r_bottom, r_top, material, weigh, segments=8, squash=1.0):
        bottom, top = Vector(bottom), Vector(top)
        axis = top - bottom
        rotation = axis.normalized().to_track_quat("Z", "Y").to_matrix().to_4x4()
        matrix = Matrix.Translation((bottom + top) / 2) @ rotation @ Matrix.Diagonal((1.0, squash, 1.0, 1.0))
        # A ring every 4 cm along the length, so a part spanning a joint can
        # bend there instead of stretching straight from end to end.
        steps = max(1, round(axis.length / 0.04))
        rings = []
        for step in range(steps + 1):
            t = step / steps
            radius = r_bottom + (r_top - r_bottom) * t
            ring = []
            for k in range(segments):
                angle = math.tau * k / segments
                local = Vector((math.cos(angle) * radius, math.sin(angle) * radius, (t - 0.5) * axis.length))
                ring.append(self.bm.verts.new(matrix @ local))
            rings.append(ring)
        for lower, upper in zip(rings, rings[1:]):
            for k in range(segments):
                self.bm.faces.new((lower[k], lower[(k + 1) % segments], upper[(k + 1) % segments], upper[k]))
        self.bm.faces.new(list(reversed(rings[0])))
        self.bm.faces.new(rings[-1])
        self.add([v for ring in rings for v in ring], material, weigh)

    def sphere(self, centre, radius, material, weigh, scale=(1, 1, 1), segments=8, rings=6):
        matrix = Matrix.Translation(centre) @ Matrix.Diagonal((*scale, 1.0))
        made = bmesh.ops.create_uvsphere(self.bm, u_segments=segments, v_segments=rings, radius=radius, matrix=matrix)
        self.add(made["verts"], material, weigh)

    def box(self, centre, size, material, weigh):
        matrix = Matrix.Translation(centre) @ Matrix.Diagonal((*size, 1.0))
        made = bmesh.ops.create_cube(self.bm, size=1.0, matrix=matrix)
        self.add(made["verts"], material, weigh)


def only(bone):
    return lambda co: {bone: 1.0}


def along_z(*joints):
    """Weights a part spanning several bones stacked along Z. `joints` are
    (upper bone, lower bone, z of the joint) from the top down; vertices
    within 4 cm of a joint are shared, so the joint bends smoothly."""
    def weigh(co):
        weights = {}
        remaining = 1.0
        for upper, _lower, z in joints:
            below = 1.0 - smoothstep(z - 0.04, z + 0.04, co.z)
            weights[upper] = weights.get(upper, 0.0) + remaining * (1.0 - below)
            remaining *= below
        last = joints[-1][1]
        weights[last] = weights.get(last, 0.0) + remaining
        return weights
    return weigh


def build_body():
    body = Body()
    trunk = along_z(("Chest", "Spine", 1.2), ("Spine", "Hips", 1.0))
    body.cylinder((0, 0, 0.84), (0, 0, 1.47), 0.2, 0.23, "Tunic", trunk, segments=10, squash=0.75)
    body.sphere((0, 0, 1.43), 0.23, "Tunic", only("Chest"), scale=(1, 0.75, 0.45), segments=10)
    body.cylinder((0, 0, 0.87), (0, 0, 0.94), 0.215, 0.215, "Leather", only("Hips"), segments=10, squash=0.78)
    body.box((0, -0.165, 0.905), (0.07, 0.02, 0.06), "Leather", only("Hips"))
    body.cylinder((0, 0, 1.45), (0, 0, 1.56), 0.055, 0.05, "Skin", only("Neck"), segments=6)
    # Head: the face looks toward -Y.
    body.sphere((0, 0, 1.67), 0.16, "Skin", only("Head"), segments=10, rings=7)
    body.sphere((0, 0.015, 1.715), 0.172, "Hair", only("Head"), scale=(1, 1.02, 0.82), segments=10, rings=7)
    body.sphere((0, 0.05, 1.66), 0.155, "Hair", only("Head"), scale=(1, 0.85, 1.05), segments=10, rings=7)
    body.box((0, -0.16, 1.64), (0.035, 0.04, 0.05), "Skin", only("Head"))
    for x in (-0.06, 0.06):
        body.sphere((x, -0.145, 1.67), 0.022, "Eye", only("Head"), segments=6, rings=4)
    for side, sign in (("Left", 1.0), ("Right", -1.0)):
        x = SHOULDER_X * sign
        arm = along_z((f"{side}UpperArm", f"{side}LowerArm", 1.13), (f"{side}LowerArm", f"{side}Hand", 0.88))
        body.sphere((x * 0.92, 0, 1.41), 0.085, "Tunic", only(f"{side}UpperArm"), segments=8, rings=5)
        body.cylinder((x, 0, 1.12), (x, 0, 1.43), 0.065, 0.075, "Tunic", arm)
        body.cylinder((x, 0, 0.88), (x, 0, 1.14), 0.05, 0.06, "Skin", arm)
        body.sphere((x, -0.01, 0.85), 0.06, "Skin", only(f"{side}Hand"), scale=(0.8, 1, 1.1), segments=7, rings=5)
        hip = HIP_X * sign
        leg = along_z((f"{side}UpperLeg", f"{side}LowerLeg", 0.46))
        body.cylinder((hip, 0, 0.12), (hip, 0, 0.88), 0.07, 0.095, "Trousers", leg)
        body.box((hip, -0.04, 0.07), (0.13, 0.26, 0.14), "Leather", only(f"{side}Foot"))
        body.cylinder((hip, 0, 0.12), (hip, 0, 0.3), 0.078, 0.082, "Leather", only(f"{side}LowerLeg"))
    return body


def build_mesh(armature, materials):
    body = build_body()
    mesh = bpy.data.meshes.new("Hero")
    body.bm.to_mesh(mesh)
    body.bm.free()
    for material in materials:
        mesh.materials.append(material)
    for polygon in mesh.polygons:
        polygon.use_smooth = False
    obj = bpy.data.objects.new("Hero", mesh)
    bpy.context.scene.collection.objects.link(obj)
    for bone in BONES:
        obj.vertex_groups.new(name=bone)
    obj.parent = armature
    modifier = obj.modifiers.new("Armature", "ARMATURE")
    modifier.object = armature
    return obj


# --- The skeleton ---------------------------------------------------------

def build_armature():
    data = bpy.data.armatures.new("Armature")
    obj = bpy.data.objects.new("Armature", data)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (head, tail, parent, connected) in BONES.items():
        bone = data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        direction = Vector(tail) - Vector(head)
        # Z toward the front for upright and hanging bones, up for the feet.
        bone.align_roll((0, 0, 1) if abs(direction.z) < abs(direction.y) else (0, -1, 0))
        if parent:
            bone.parent = data.edit_bones[parent]
            bone.use_connect = connected
    bpy.ops.object.mode_set(mode="OBJECT")
    for bone in obj.pose.bones:
        bone.rotation_mode = "XYZ"
    return obj


# --- Animations -----------------------------------------------------------

def pose(**bones):
    """A pose: bone name to (pitch, twist, spread) in degrees, plus `drop`, the
    metres the hips sink. Pitch swings a bone forward (lifts the toes, for
    a foot). Spread lifts an arm or leg out to its side (negative crosses it
    over the body). Twist turns a bone about its length. Right-side
    bones take the same signs as left ones; mirroring is done here."""
    return bones


def mirrored(name, rotation):
    pitch, twist, spread = (list(rotation) + [0.0, 0.0])[:3]
    if name.startswith("Right"):
        twist, spread = -twist, -spread
    # Rotation about the bone's Z (its front) lifts a left limb outward.
    return (math.radians(pitch), math.radians(twist), math.radians(spread))


def key_action(armature, name, keys, loop):
    """`keys` is [(frame, pose)]. Every bone is keyed at every key, so the
    animation fully decides the body; a loop ends where it starts."""
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    armature.animation_data.action = action
    if loop:
        keys = keys + [(keys[-1][0] + (keys[1][0] - keys[0][0]) if len(keys) > 1 else 1, keys[0][1])]
        keys = sorted({frame: p for frame, p in keys}.items())
    for frame, posed in keys:
        for bone in armature.pose.bones:
            rotation = posed.get(bone.name, (0.0,))
            if isinstance(rotation, (int, float)):
                rotation = (rotation,)
            bone.rotation_euler = mirrored(bone.name, rotation)
            bone.location = (0.0, -posed.get("drop", 0.0) if bone.name == "Hips" else 0.0, 0.0)
            bone.keyframe_insert("rotation_euler", frame=frame)
            if bone.name == "Hips":
                bone.keyframe_insert("location", frame=frame)
    return action


def stride(lead, arms, bob, lean, knee, frames):
    """A walking or running cycle over `frames`: the left leg leads first."""
    half = frames // 2
    quarter = frames // 4
    def step(side_lead):
        other = "Right" if side_lead == "Left" else "Left"
        return {
            f"{side_lead}UpperLeg": lead, f"{side_lead}LowerLeg": -knee * 0.25, f"{side_lead}Foot": 10,
            f"{other}UpperLeg": -lead * 0.8, f"{other}LowerLeg": -knee * 0.5, f"{other}Foot": -15,
            f"{side_lead}UpperArm": (-arms, 0, 6), f"{side_lead}LowerArm": 10,
            f"{other}UpperArm": (arms, 0, 6), f"{other}LowerArm": 25 + arms * 0.4,
            "Spine": lean, "Chest": lean * 0.5, "Head": -lean * 1.2,
        }
    def passing(side_up):
        return {
            f"{side_up}UpperLeg": lead * 0.35, f"{side_up}LowerLeg": -knee, f"{side_up}Foot": 5,
            "LeftUpperArm": (0, 0, 6), "RightUpperArm": (0, 0, 6), "LeftLowerArm": 15, "RightLowerArm": 15,
            "Spine": lean, "Chest": lean * 0.5, "Head": -lean * 1.2, "drop": -bob,
        }
    return [(0, step("Left")), (quarter, passing("Right")), (half, step("Right")), (half + quarter, passing("Left"))]


def build_animations(armature):
    armature.animation_data_create()
    rest_arms = {"LeftUpperArm": (0, 0, 6), "RightUpperArm": (0, 0, 6), "LeftLowerArm": 8, "RightLowerArm": 8}
    key_action(armature, "idle", [
        (0, pose(**rest_arms, Chest=0, Head=0)),
        (30, pose(**rest_arms, Chest=-2.5, Spine=1, Head=2, drop=0.008)),
    ], loop=True)
    key_action(armature, "walk", stride(lead=30, arms=22, bob=0.03, lean=4, knee=55, frames=20), loop=True)
    key_action(armature, "run", stride(lead=50, arms=45, bob=0.06, lean=12, knee=95, frames=14), loop=True)
    airborne = pose(LeftUpperLeg=55, LeftLowerLeg=-80, LeftFoot=20, RightUpperLeg=-5, RightLowerLeg=-45,
                    LeftUpperArm=(20, 0, 35), RightUpperArm=(20, 0, 35), LeftLowerArm=30, RightLowerArm=30,
                    Spine=6, Head=-4)
    key_action(armature, "fall", [(0, airborne), (12, pose(**{**airborne, "LeftUpperArm": (24, 0, 40), "RightUpperArm": (24, 0, 40)}))], loop=True)
    # The sword arm while holding the sword: forearm forward, blade ahead.
    key_action(armature, "hold_sword", [(0, pose(**{**rest_arms, "RightUpperArm": (15, 0, 8), "RightLowerArm": 55, "RightHand": -20}))], loop=True)
    # A diagonal swing, right shoulder to left hip: wind up, strike, recover.
    key_action(armature, "swing", [
        (0, pose(RightUpperArm=(15, 0, 8), RightLowerArm=55, RightHand=-20)),
        (5, pose(RightUpperArm=(150, -30, 35), RightLowerArm=40, RightHand=10, Chest=(-6, -25, 0), Spine=(0, -10, 0),
                 LeftUpperArm=(10, 0, 20))),
        (9, pose(RightUpperArm=(45, 20, -55), RightLowerArm=10, RightHand=-10, Chest=(10, 30, 0), Spine=(4, 15, 0),
                 LeftUpperArm=(-15, 0, 15))),
        (15, pose(RightUpperArm=(15, 0, 8), RightLowerArm=55, RightHand=-20)),
    ], loop=False)
    # Kneeling on both knees, bowed, hands together before the chest.
    kneel = dict(LeftUpperLeg=0, RightUpperLeg=0, LeftLowerLeg=-90, RightLowerLeg=-90, LeftFoot=-30, RightFoot=-30,
                 Spine=8, Chest=6, Neck=8, Head=14,
                 LeftUpperArm=(32, 35, -24), RightUpperArm=(32, 35, -24), LeftLowerArm=100, RightLowerArm=100,
                 LeftHand=(0, 0, -20), RightHand=(0, 0, -20), drop=0.38)
    key_action(armature, "pray", [(0, pose(**kneel)), (45, pose(**{**kneel, "Chest": 8, "Head": 17}))], loop=True)
    # Crying: hunched, hands over the face, shoulders shaking.
    weep = dict(Spine=10, Chest=12, Neck=10, Head=22,
                LeftUpperArm=(42, 40, -20), RightUpperArm=(42, 40, -20), LeftLowerArm=135, RightLowerArm=135,
                LeftHand=(10, 0, 0), RightHand=(10, 0, 0), LeftUpperLeg=4, RightUpperLeg=4, LeftLowerLeg=-8,
                RightLowerLeg=-8, drop=0.03)
    key_action(armature, "cry", [
        (0, pose(**weep)),
        (4, pose(**{**weep, "Chest": 15, "LeftShoulder": (0, 0, 5), "RightShoulder": (0, 0, 5), "drop": 0.04})),
        (8, pose(**weep)),
        (12, pose(**{**weep, "Chest": 14, "LeftShoulder": (0, 0, 4), "RightShoulder": (0, 0, 4)})),
    ], loop=True)
    # Swimming a front crawl: the body face down along the surface (the hips
    # tipped forward), head up to breathe-look ahead, arms reaching and
    # pulling in turn, the high elbow recovering over the water, legs
    # fluttering, the chest rolling toward the pulling arm.
    flat = dict(Hips=78, Neck=-25, Head=-35, LeftFoot=-55, RightFoot=-55)
    def crawl(reach, pull, roll, kick):
        other = "Right" if reach == "Left" else "Left"
        return pose(**flat, **{
            f"{reach}UpperArm": (170, 0, 12), f"{reach}LowerArm": 5, f"{reach}Hand": -10,
            f"{other}UpperArm": (pull, 0, 10), f"{other}LowerArm": 15, f"{other}Hand": 10,
            "Spine": (0, roll, 0), "Chest": (0, roll, 0),
            "LeftUpperLeg": kick, "RightUpperLeg": -kick, "LeftLowerLeg": -12 - max(kick, 0), "RightLowerLeg": -12 - max(-kick, 0),
        })
    def recover(pulling, roll, kick):
        other = "Right" if pulling == "Left" else "Left"
        return pose(**flat, **{
            f"{pulling}UpperArm": (85, 0, 6), f"{pulling}LowerArm": 30, f"{pulling}Hand": 15,
            f"{other}UpperArm": (60, 0, 55), f"{other}LowerArm": 95, f"{other}Hand": -20,
            "Spine": (0, roll, 0), "Chest": (0, roll, 0),
            "LeftUpperLeg": kick, "RightUpperLeg": -kick, "LeftLowerLeg": -12 - max(kick, 0), "RightLowerLeg": -12 - max(-kick, 0),
        })
    key_action(armature, "swim", [
        (0, crawl("Left", -15, 12, 14)),
        (8, recover("Left", -6, -14)),
        (16, crawl("Right", -15, -12, 14)),
        (24, recover("Right", 6, -14)),
    ], loop=True)
    armature.animation_data.action = None
    for bone in armature.pose.bones:
        bone.rotation_euler = (0, 0, 0)
        bone.location = (0, 0, 0)


def export():
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT,
        export_format="GLB",
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_force_sampling=True,
        export_cameras=False,
        export_lights=False,
    )


def main():
    clear_scene()
    materials = make_materials()
    armature = build_armature()
    build_mesh(armature, materials)
    build_animations(armature)
    export()
    print(f"[hero] wrote {OUTPUT}: {len(BONES)} bones, {len(bpy.data.actions)} animations")


if __name__ == "__main__":
    try:
        main()
    except Exception:
        import traceback
        traceback.print_exc()
        sys.exit(1)
