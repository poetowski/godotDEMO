class_name HeroBody
extends Node3D
## The hero's skinned body (assets/models/hero/hero.glb, built by
## tools/blender/build_hero.py) and the AnimationTree that moves it. The
## player tells it how it moves; it blends the animations:
##   idle, walk and run by ground speed; fall while airborne;
##   hold_sword on the right arm while a sword is held; swing on the upper
##   body; pray or cry over everything while a gesture runs; swim over
##   everything in deep water, faster the faster it moves.
## It also carries the attachment points: the right hand and the eyes.

## Bones a swing moves; the legs keep walking underneath.
const UPPER_BODY: Array[String] = [
	"Spine", "Chest", "Neck", "Head",
	"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand",
]
const SWORD_ARM: Array[String] = ["RightUpperArm", "RightLowerArm", "RightHand"]
const LOOPS: Array[StringName] = [&"idle", &"walk", &"run", &"fall", &"hold_sword", &"pray", &"cry", &"swim"]
## Metres per second the swim animation is made for; slower swimming plays it
## slower, down to a gentle paddle when still.
const SWIM_SPEED := 2.4
## Metres per second the walk and run animations are made for.
const WALK_SPEED := 4.5
const RUN_SPEED := 7.5

var _tree: AnimationTree
var _skeleton: Skeleton3D
var _hand: Node3D
var _eyes: Array[Node3D] = []


func _ready() -> void:
	_skeleton = find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var player := find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for animation_name in LOOPS:
		if player.has_animation(animation_name):
			player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	add_child(_tree)
	_tree.root_node = _tree.get_path_to(player.get_node(player.root_node))
	_tree.anim_player = _tree.get_path_to(player)
	# Filters name bones the way the animation tracks do.
	var idle := player.get_animation(&"idle")
	var skeleton_path := NodePath(String(idle.track_get_path(0)).get_slice(":", 0))
	_tree.tree_root = _build_tree(skeleton_path)
	_tree.active = true
	_hand = _attach("RightHand", "Hand", Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0.0, 0.06, 0.0)))
	_eyes.append(_attach("Head", "LeftEye", Transform3D(Basis(Vector3.UP, PI), Vector3(0.06, 0.15, 0.145))))
	_eyes.append(_attach("Head", "RightEye", Transform3D(Basis(Vector3.UP, PI), Vector3(-0.06, 0.15, 0.145))))


## Where a held sword goes: the right palm, -Y down the arm and -Z ahead.
func hand() -> Node3D:
	return _hand


## The left and right eyes, -Z looking ahead, for tears.
func eyes() -> Array[Node3D]:
	return _eyes


## Recolours one of the body's materials ("Tunic", "Trousers", "Hair"...)
## on this body only.
func tint(material_name: String, color: Color) -> void:
	for mesh_instance in find_children("*", "MeshInstance3D", true, false):
		var mesh := (mesh_instance as MeshInstance3D).mesh
		for surface in mesh.get_surface_count():
			var material := mesh.surface_get_material(surface) as BaseMaterial3D
			if material and material.resource_name == material_name:
				var own := material.duplicate() as BaseMaterial3D
				own.albedo_color = color
				(mesh_instance as MeshInstance3D).set_surface_override_material(surface, own)


## Stops or restarts animating, for bodies far from the player.
func set_active(active: bool) -> void:
	if _tree.active != active:
		_tree.active = active


## Sets how the body moves this frame.
func move(ground_speed: float, airborne: bool, holding_sword: bool, delta: float) -> void:
	var position_now := float(_tree.get("parameters/locomotion/blend_position"))
	_tree.set("parameters/locomotion/blend_position", lerpf(position_now, ground_speed, 1.0 - exp(-10.0 * delta)))
	var air := float(_tree.get("parameters/air/blend_amount"))
	_tree.set("parameters/air/blend_amount", move_toward(air, 1.0 if airborne else 0.0, delta * 6.0))
	var hold := float(_tree.get("parameters/hold/blend_amount"))
	_tree.set("parameters/hold/blend_amount", move_toward(hold, 1.0 if holding_sword else 0.0, delta * 6.0))


## Plays one swing over the upper body.
func swing() -> void:
	_tree.set("parameters/swing/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Swims (or stops swimming) at `speed` metres per second, easing in and out.
func swim(swimming: bool, speed: float, delta: float) -> void:
	var amount := float(_tree.get("parameters/water/blend_amount"))
	_tree.set("parameters/water/blend_amount", move_toward(amount, 1.0 if swimming else 0.0, delta * 3.0))
	_tree.set("parameters/swim_pace/scale", clampf(speed / SWIM_SPEED, 0.35, 1.6))


## Blends a gesture (&"pray" or &"cry") over the whole body by `weight`,
## 0 to 1.
func gesture(name_of_gesture: StringName, weight: float) -> void:
	if weight > 0.0:
		_tree.set("parameters/gesture_pick/transition_request", String(name_of_gesture))
	_tree.set("parameters/gesture/blend_amount", weight)


## A bone's height above the body's origin, in metres, as posed now.
func bone_height(bone: String) -> float:
	var index := _skeleton.find_bone(bone)
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(index)).origin.y - global_position.y


func _attach(bone: String, node_name: String, offset: Transform3D) -> Node3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = bone + "Attachment"
	attachment.bone_name = bone
	_skeleton.add_child(attachment)
	var point := Node3D.new()
	point.name = node_name
	point.transform = offset
	attachment.add_child(point)
	return point


func _build_tree(skeleton: NodePath) -> AnimationNodeBlendTree:
	var root := AnimationNodeBlendTree.new()
	var locomotion := AnimationNodeBlendSpace1D.new()
	locomotion.min_space = 0.0
	locomotion.max_space = RUN_SPEED
	locomotion.sync = true
	locomotion.add_blend_point(_clip(&"idle"), 0.0, -1, &"idle")
	locomotion.add_blend_point(_clip(&"walk"), WALK_SPEED, -1, &"walk")
	locomotion.add_blend_point(_clip(&"run"), RUN_SPEED, -1, &"run")
	root.add_node(&"locomotion", locomotion)
	root.add_node(&"fall", _clip(&"fall"))
	root.add_node(&"air", AnimationNodeBlend2.new())
	root.add_node(&"hold_sword", _clip(&"hold_sword"))
	root.add_node(&"hold", _filtered(AnimationNodeBlend2.new(), skeleton, SWORD_ARM) as AnimationNodeBlend2)
	var swing := _filtered(AnimationNodeOneShot.new(), skeleton, UPPER_BODY) as AnimationNodeOneShot
	swing.fadein_time = 0.04
	swing.fadeout_time = 0.12
	root.add_node(&"swing_clip", _clip(&"swing"))
	root.add_node(&"swing", swing)
	var pick := AnimationNodeTransition.new()
	pick.xfade_time = 0.2
	pick.add_input("pray")
	pick.add_input("cry")
	root.add_node(&"pray", _clip(&"pray"))
	root.add_node(&"cry", _clip(&"cry"))
	root.add_node(&"gesture_pick", pick)
	root.add_node(&"gesture", AnimationNodeBlend2.new())
	root.add_node(&"swim", _clip(&"swim"))
	root.add_node(&"swim_pace", AnimationNodeTimeScale.new())
	root.add_node(&"water", AnimationNodeBlend2.new())
	root.connect_node(&"air", 0, &"locomotion")
	root.connect_node(&"air", 1, &"fall")
	root.connect_node(&"hold", 0, &"air")
	root.connect_node(&"hold", 1, &"hold_sword")
	root.connect_node(&"swing", 0, &"hold")
	root.connect_node(&"swing", 1, &"swing_clip")
	root.connect_node(&"gesture_pick", 0, &"pray")
	root.connect_node(&"gesture_pick", 1, &"cry")
	root.connect_node(&"swim_pace", 0, &"swim")
	root.connect_node(&"water", 0, &"swing")
	root.connect_node(&"water", 1, &"swim_pace")
	root.connect_node(&"gesture", 0, &"water")
	root.connect_node(&"gesture", 1, &"gesture_pick")
	root.connect_node(&"output", 0, &"gesture")
	return root


func _clip(animation: StringName) -> AnimationNodeAnimation:
	var clip := AnimationNodeAnimation.new()
	clip.animation = animation
	return clip


func _filtered(node: AnimationNode, skeleton: NodePath, bones: Array[String]) -> AnimationNode:
	node.filter_enabled = true
	for bone in bones:
		node.set_filter_path(NodePath("%s:%s" % [skeleton, bone]), true)
	return node
