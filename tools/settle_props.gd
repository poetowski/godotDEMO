extends SceneTree
## Sets the props under sector designs back on the ground after the land was
## sculpted again, for `npm run settle`: each one's height, so it stands on the
## lowest ground under it and nothing floats. Only the height changes, in those
## lines of src/world/field/field.tscn, so where props were moved by hand stays as it
## is. Close the editor first: it would overwrite the file with its own copy.

const SCENE := "res://src/world/field/field.tscn"
## Metres off before a prop is moved.
const TOLERANCE := 0.15
## How far under the lowest ground a prop's base goes.
const SINK := 0.05
## How much of a prop's half width counts as standing on the ground, and at most
## how far that reaches for anything but bedrock: a tree's branches overhang.
const FOOTPRINT := 0.6
const MOST_REACH := 0.7
## Assets that stand on the ground right across, not at a foot in the middle, such
## as buildings and outcrops, by part of their slug.
const WHOLE_FOOTPRINT: Array[String] = []
## Assets that stand on the ground at the trunk, not across their width: trees, by
## part of their slug.
const TREE_FOOT := 0.2
const TREES: Array[String] = []
## Assets that lie along the ground with their middle on it, such as lengths of
## fence, by part of their slug, and how far they sink.
const LIES_ALONG: Array[String] = []
const ALONG_SINK := 0.02
const SIDES := 8


func _initialize() -> void:
	FieldWorld.configure()
	var world := (load(SCENE) as PackedScene).instantiate()
	var text := FileAccess.get_file_as_string(SCENE)
	var pattern := RegEx.create_from_string('\\[node name="([^"]+)" type="Node3D" parent="(Sectors/[^"]+/Props)"[^\\]]*\\]\\s*transform = Transform3D\\(([^)]*)\\)')
	var moved := 0
	var furthest := 0.0
	var found := pattern.search_all(text)
	# From the end, so earlier places in the text stay where they are.
	found.reverse()
	for match_found in found:
		var prop := world.get_node_or_null("%s/%s" % [match_found.get_string(2), match_found.get_string(1)]) as Prop
		if prop == null:
			continue
		var numbers := match_found.get_string(3).split(",")
		var was := numbers[10].to_float()
		var settled := standing_height(prop)
		if absf(settled - was) < TOLERANCE:
			continue
		numbers[10] = " %.4f" % settled
		text = text.substr(0, match_found.get_start(3)) + ",".join(numbers) + text.substr(match_found.get_end(3))
		moved += 1
		furthest = maxf(furthest, absf(settled - was))
	world.free()
	if moved > 0:
		var file := FileAccess.open(SCENE, FileAccess.WRITE)
		file.store_string(text)
		file.close()
	print("[settle] moved %d props, the furthest %.2f m" % [moved, furthest])
	quit()


static func standing_height(prop: Prop) -> float:
	if not prop.stands_on_ground():
		return prop.position.y
	var xz := Vector2(prop.position.x, prop.position.z)
	# Code-made kinds (bushes, rocks, trees) have no asset, and no slug.
	var path := prop.asset.resource_path if prop.asset else ""
	if LIES_ALONG.any(func(part: String) -> bool: return path.contains(part)):
		return WorldShape.height(xz) - ALONG_SINK
	var reach := PropLibrary.asset_room(prop.asset) * prop.transform.basis.get_scale().x * FOOTPRINT
	if not WHOLE_FOOTPRINT.any(func(part: String) -> bool: return path.contains(part)):
		reach = minf(reach, MOST_REACH)
	if TREES.any(func(part: String) -> bool: return path.contains(part)):
		reach = TREE_FOOT
	var lowest := WorldShape.height(xz)
	for k in SIDES:
		var angle := TAU * k / SIDES
		lowest = minf(lowest, WorldShape.height(xz + Vector2(cos(angle), sin(angle)) * reach))
	return lowest - SINK
