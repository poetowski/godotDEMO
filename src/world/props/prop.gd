@tool
class_name Prop
extends Node3D
## A prop placed by hand: a bush, rock or tree you can select, move, turn,
## scale, duplicate or delete in the editor. Put props under a sector
## design's `Props` node (drag in src/world/props/*.tscn, or duplicate one).
## The game never draws them one by one: the design merges its props into a
## few meshes per sector when its content is built (and baked), with their
## collision. In the editor each prop shows a preview of itself.

## What it is (PropLibrary.Kind).
@export var kind: PropLibrary.Kind = PropLibrary.Kind.BUSH:
	set(value):
		kind = value
		_refresh()
## Which of its kind's shapes, the same every time for the same number.
@export var variant: int = 0:
	set(value):
		variant = value
		_refresh()
## Whether the player bumps into it.
@export var solid: bool = false

var _preview: MeshInstance3D


func _ready() -> void:
	_refresh()


## Where it stands in its design, for merging.
func placement() -> Transform3D:
	var holder := get_parent() as Node3D
	return holder.transform * transform if holder else transform


func _refresh() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if _preview == null:
		_preview = MeshInstance3D.new()
		_preview.name = "Preview"
		add_child(_preview)
	_preview.mesh = PropLibrary.mesh(kind, variant)
	_preview.material_override = PropLibrary.material(PropLibrary.group(kind))
