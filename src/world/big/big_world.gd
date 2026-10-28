extends "res://src/world/field/field.gd"
## The big world: REGIONS x REGIONS regions of open, hilly woodland (R1 in
## the south-west corner), its ground and woods streamed around the player.
## Built to prove the world holds at kilometres: memory and draw calls
## should stay flat however far the player goes. Not game content. Play it
## with `npm run game -- src/world/big/big_world.tscn`; `--regions=20` after
## `--` makes it 20 x 20 (4 km).

## Regions east and north: 10 makes 2 km.
const REGIONS := 10
## Metres the hills rise and fall at most.
const HILL_HEIGHT := 34.0
## How quickly the hills come and go: about one every 250 m.
const HILL_FREQUENCY := 0.004
## Metres inside the world's edge over which the land eases flat.
const BORDER := 80.0
## Thinner fog than the small field's, so the land reads far off.
const FOG_DENSITY := 0.0011


func _init() -> void:
	super()
	var regions := REGIONS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--regions="):
			regions = clampi(arg.trim_prefix("--regions=").to_int(), 1, 50)
	RegionMap.configure(regions, regions)
	WorldShape.configure(HILL_HEIGHT, HILL_FREQUENCY, 3)
	WorldShape.border = BORDER
	var middle := RegionMap.name_of(Vector2i(regions / 2, regions / 2))
	start_sector = middle + ":J10"


func _ready() -> void:
	($WorldEnvironment as WorldEnvironment).environment.fog_density = FOG_DENSITY
	super()


func vegetation() -> Vegetation:
	return $Vegetation as Vegetation


## Builds the woods around the player at once too, after the ground.
func teleport(cell: Vector2i) -> void:
	super(cell)
	if has_node("Vegetation"):
		vegetation().build_now()
