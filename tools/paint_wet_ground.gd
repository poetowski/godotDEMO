extends SceneTree
## One-off from the author's "in region R1 in sectors A2 B2 C2 C3 D3 F3 F5 H4 H5 I6 j5 j6 add some
## wet dirt as ground": paints mud through those sectors, thickest where the ground lies low by the
## water, in patches with grass between them, and fading out across their edges so no sector shows
## as a square. It keeps off what the author painted. Run headless with the editor closed:
##   godot --headless --path . -s res://tools/paint_wet_ground.gd
## The paint before this is in git at 9af959e.

const MUD := 1
## World x from west to east, and metres north, of what changes.
const AREA := Rect2i(-3, 7, 106, 56)
## A sample holding more than this of the author's paint is left alone.
const THEIRS := 0.35
## Metres below the water at which there's no point painting, and metres above it where the
## ground stops counting as low.
const UNDER := 0.4
const LOW := 2.0
## Metres out around a sample, ring by ring, looked at to tell how far inside the wet sectors it is.
const LOOK := 5.0
const RINGS := 3
const LOOKS := 12


func _initialize() -> void:
	FieldWorld.configure()
	TerrainPaint.read_again()
	WaterField.use_only(WaterField.saved_plans())
	var wet := {}
	for sector: String in R1Waterside.WET_SECTORS:
		wet[SectorMap.cell_named(sector)] = true
	var patches := FastNoiseLite.new()
	patches.seed = 41
	patches.frequency = 0.085
	var grain := FastNoiseLite.new()
	grain.seed = 42
	grain.frequency = 0.18
	var edge := FastNoiseLite.new()
	edge.seed = 43
	edge.frequency = 0.05
	var amounts := PackedFloat32Array()
	amounts.resize(AREA.size.x * AREA.size.y)
	var painted := 0
	for j in AREA.size.y:
		for i in AREA.size.x:
			var x := AREA.position.x + i
			var y := AREA.position.y + j
			var xz := Vector2(x, -y)
			var inside := _inside(xz, wet)
			if inside <= 0.0:
				continue
			var theirs := 0.0
			for surface in TerrainPaint.LAYERS:
				theirs += TerrainPaint.share(x, y, surface)
			if theirs > THEIRS:
				continue
			var height := WorldShape.height(xz)
			var level := WaterField.level_at(xz)
			var above := height - level if level > SectorDesign.NO_WATER else LOW
			if above < -UNDER:
				continue
			var low := 1.0 - smoothstep(0.2, LOW, above)
			var rough := grain.get_noise_2d(x, y)
			var patch := patches.get_noise_2d(x, y) + rough * 0.14
			# The edge wanders, so no sector's line shows in it.
			var fade := smoothstep(0.28, 0.7, inside + edge.get_noise_2d(x, y) * 0.5 + rough * 0.1)
			var amount := smoothstep(-0.2, 0.2, patch + low * 0.34) * fade
			if amount > 0.04:
				amounts[j * AREA.size.x + i] = minf(amount, 0.96)
				painted += 1
	TerrainPaint.lay(AREA, amounts, MUD)
	var error := TerrainPaint.save(TerrainSculpt.tiles_in(AREA))
	print("[paint] %d samples, saved: %s" % [painted, error_string(error)])
	quit(0 if error == OK else 1)


## How much of the ground round a point lies in the wet sectors, 0 to 1, so sectors side by side
## join with no seam.
func _inside(xz: Vector2, wet: Dictionary) -> float:
	var count := 1.0 if wet.has(SectorMap.unbounded_cell_at(xz)) else 0.0
	for ring in RINGS:
		for k in LOOKS:
			var angle := TAU * (k + ring * 0.5) / LOOKS
			if wet.has(SectorMap.unbounded_cell_at(xz + Vector2(cos(angle), sin(angle)) * LOOK * (ring + 1.0) / RINGS)):
				count += 1.0
	return count / (RINGS * LOOKS + 1.0)
