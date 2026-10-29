extends SceneTree
## Freezes a sector design's props into the field scene, for `npm run props`:
## builds the design once, then writes every prop its code placed
## (place_prop) into src/world/field/field.tscn as a Prop node under the
## design's `Props` node, and sets the design's `props_frozen`. From then on
## the props are edited by hand in the editor. Only those lines are added:
## the rest of the scene file stays as it was. Close the editor first: it
## would overwrite the file with its own copy.
##
## User argument (after --): the design's node name, such as A1A3Stream.

const SCENE := "res://src/world/field/field.tscn"
const PROP_SCRIPT := "res://src/world/props/prop.gd"
const PROP_ID := "50_prop"
const NAMES: Array[String] = ["Bush", "Rock", "Tree", "Pine"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		_fail("Usage: npm run props -- <DesignNodeName>")
		return
	var design_name := args[0]
	# Instanced but never added to the tree: only the design is built.
	var root := (load(SCENE) as PackedScene).instantiate()
	var design := root.get_node_or_null("Sectors/" + design_name) as SectorDesign
	if design == null:
		root.free()
		_fail("No design named %s under Sectors." % design_name)
		return
	if design.props_frozen or design.has_node("Props"):
		root.free()
		_fail("%s's props are in the scene already; edit them in the editor." % design_name)
		return
	design.generate_content().free()
	var placed := design.placed_props().duplicate()
	root.free()
	var text := FileAccess.get_file_as_string(SCENE)
	var written := _with_props(text, design_name, placed)
	if written.is_empty():
		_fail("Could not find %s's node in %s." % [design_name, SCENE])
		return
	var file := FileAccess.open(SCENE, FileAccess.WRITE)
	file.store_string(written)
	file.close()
	print("[props] froze %d props of %s into %s" % [placed.size(), design_name, SCENE])
	quit(0)


## The scene's text with the design marked frozen and its props added right
## after its own node; "" if the design's node isn't there.
static func _with_props(text: String, design_name: String, placed: Array[Dictionary]) -> String:
	var header := '[node name="%s" ' % design_name
	var start := text.find(header)
	if start < 0:
		return ""
	var end := text.find("\n\n", start)
	if end < 0:
		end = text.length()
	var lines: PackedStringArray = ["props_frozen = true", ""]
	var parent := "Sectors/%s" % design_name
	lines.append('[node name="Props" type="Node3D" parent="%s"]' % parent)
	var counts := {}
	for entry in placed:
		var kind: int = entry["kind"]
		counts[kind] = int(counts.get(kind, 0)) + 1
		lines.append("")
		lines.append('[node name="%s%d" type="Node3D" parent="%s/Props"]' % [NAMES[kind], counts[kind], parent])
		lines.append("transform = " + var_to_str(entry["where"]))
		lines.append('script = ExtResource("%s")' % PROP_ID)
		lines.append("kind = %d" % kind)
		lines.append("variant = %d" % int(entry["variant"]))
		lines.append("solid = %s" % ("true" if entry["solid"] else "false"))
	text = text.substr(0, end) + "\n" + "\n".join(lines) + text.substr(end)
	if not text.contains('id="%s"' % PROP_ID):
		var last := text.rfind("[ext_resource ")
		var line_end := text.find("\n", last)
		text = text.substr(0, line_end + 1) + '[ext_resource type="Script" path="%s" id="%s"]\n' % [PROP_SCRIPT, PROP_ID] + text.substr(line_end + 1)
	return text


func _fail(message: String) -> void:
	push_error("[props] " + message)
	quit(1)
