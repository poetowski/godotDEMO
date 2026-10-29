"""Shared helpers for the Blender scripts that build the game's models
(tools/blender/assets/*.py and build_hero.py's style): a clean scene,
materials picked in sRGB like every colour in the project, low-poly parts,
collision shapes Godot picks up on import, and .glb export.

Scripts import it with:
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    import kit
"""
import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, roughness=0.8, metallic=0.0, alpha=1.0, emission=None, emission_strength=0.0):
    """A material from an sRGB colour. alpha < 1 makes it see-through
    (glass); `emission` (sRGB) makes it glow."""
    mat = bpy.data.materials.new(name)
    linear = tuple(srgb_to_linear(c) for c in color)
    mat.diffuse_color = (*linear, alpha)
    if mat.node_tree is None:
        mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*linear, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        for attribute, value in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            if hasattr(mat, attribute):
                try:
                    setattr(mat, attribute, value)
                except (TypeError, ValueError):
                    pass
    if emission is not None:
        glow = tuple(srgb_to_linear(c) for c in emission)
        bsdf.inputs["Emission Color"].default_value = (*glow, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


class Model:
    """Collects low-poly parts into one mesh object, each part with its
    material. Parts are bmesh primitives placed by a matrix."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.materials = []

    def _index(self, mat):
        if mat not in self.materials:
            self.materials.append(mat)
        return self.materials.index(mat)

    def _paint(self, verts, mat):
        index = self._index(mat)
        faces = set()
        for vert in verts:
            faces.update(vert.link_faces)
        for face in faces:
            face.material_index = index

    def cylinder(self, bottom, top, r_bottom, r_top, mat, segments=10, caps=True):
        bottom, top = Vector(bottom), Vector(top)
        axis = top - bottom
        rotation = axis.normalized().to_track_quat("Z", "Y").to_matrix().to_4x4()
        matrix = Matrix.Translation((bottom + top) / 2) @ rotation
        made = bmesh.ops.create_cone(self.bm, cap_ends=caps, segments=segments, radius1=r_bottom,
                                     radius2=r_top, depth=axis.length, matrix=matrix)
        self._paint(made["verts"], mat)

    def sphere(self, centre, radius, mat, scale=(1, 1, 1), segments=10, rings=7):
        matrix = Matrix.Translation(centre) @ Matrix.Diagonal((*scale, 1.0))
        made = bmesh.ops.create_uvsphere(self.bm, u_segments=segments, v_segments=rings, radius=radius, matrix=matrix)
        self._paint(made["verts"], mat)

    def box(self, centre, size, mat, rotation_z=0.0):
        matrix = Matrix.Translation(centre) @ Matrix.Rotation(rotation_z, 4, "Z") @ Matrix.Diagonal((*size, 1.0))
        made = bmesh.ops.create_cube(self.bm, size=1.0, matrix=matrix)
        self._paint(made["verts"], mat)

    def lathe(self, profile, mat, segments=12, centre=(0, 0, 0)):
        """A round shape turned from a profile of (radius, height) points,
        bottom to top: flasks, bowls, vases."""
        rings = []
        for radius, height in profile:
            ring = []
            for k in range(segments):
                angle = math.tau * k / segments
                ring.append(self.bm.verts.new((centre[0] + math.cos(angle) * radius, centre[1] + math.sin(angle) * radius, centre[2] + height)))
            rings.append(ring)
        for lower, upper in zip(rings, rings[1:]):
            for k in range(segments):
                self.bm.faces.new((lower[k], lower[(k + 1) % segments], upper[(k + 1) % segments], upper[k]))
        if profile[0][0] > 0.0005:
            self.bm.faces.new(list(reversed(rings[0])))
        if profile[-1][0] > 0.0005:
            self.bm.faces.new(rings[-1])
        self._paint([v for ring in rings for v in ring], mat)

    def tube(self, points, radius, mat, segments=6):
        """A thin tube along a polyline, such as a copper pipe."""
        for a, b in zip(points, points[1:]):
            self.cylinder(a, b, radius, radius, mat, segments=segments, caps=False)
            self.sphere(b, radius, mat, segments=segments, rings=4)

    def finish(self, flat=True):
        mesh = bpy.data.meshes.new(self.name)
        self.bm.normal_update()
        self.bm.to_mesh(mesh)
        self.bm.free()
        for mat in self.materials:
            mesh.materials.append(mat)
        for polygon in mesh.polygons:
            polygon.use_smooth = not flat
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj


def collision_box(name, centre, size):
    """A box Godot turns into a convex collision shape on import (the
    "-convcolonly" suffix), never drawn."""
    model = Model(name + "-convcolonly")
    model.box(centre, size, material("Collision", (1, 0, 1)))
    return model.finish()


def collision_cylinder(name, bottom, top, radius, segments=10):
    model = Model(name + "-convcolonly")
    model.cylinder(bottom, top, radius, radius, material("Collision", (1, 0, 1)), segments=segments)
    return model.finish()


def export(slug):
    """Writes assets/models/props/<slug>/<slug>.glb and returns its path."""
    out = os.path.join(ROOT, "assets", "models", "props", slug, slug + ".glb")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_cameras=False, export_lights=False,
                              export_animations=False)
    return out


def report(slug, path):
    """Prints the model's size, for the skill's checks."""
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    triangles = 0
    for obj in bpy.context.scene.objects:
        if obj.type != "MESH" or obj.name.endswith("-convcolonly"):
            continue
        for vertex in obj.data.vertices:
            point = obj.matrix_world @ vertex.co
            low = Vector(map(min, low, point))
            high = Vector(map(max, high, point))
        triangles += sum(len(p.vertices) - 2 for p in obj.data.polygons)
    size = high - low
    print(f"[asset] {slug}: {size.x:.2f} x {size.y:.2f} x {size.z:.2f} m (x, y, height), {triangles} triangles -> {path}")
