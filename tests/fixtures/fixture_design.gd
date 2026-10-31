extends SectorDesign
## A sector design for tests, not part of the game: a pond 2.5 m deep in the
## middle of each owned sector, with a pebble to pick up beside the first.

const PEBBLE := preload("res://tests/fixtures/items/pebble.tres")
const POND_RADIUS := 3.0
const DEPTH := 2.5


## Puts a new design of this kind into a field that isn't in the tree yet.
static func add_to(world: Node, node_name: String, owned: PackedStringArray) -> SectorDesign:
	var design: SectorDesign = (load("res://tests/fixtures/fixture_design.gd") as GDScript).new()
	design.name = node_name
	design.sectors = owned
	design.design_id = node_name.to_lower()
	world.get_node("Sectors").add_child(design)
	return design


## The middle of the pond in an owned sector.
func pond(sector_name: String) -> Vector2:
	var centre := SectorMap.center_of(SectorMap.cell_named(sector_name))
	return Vector2(centre.x, centre.z)


## A spot of dry ground beside the first pond, where the pebble lies.
func pebble_spot() -> Vector2:
	return pond(sectors[0]) + Vector2(4.0, 0.0)


func _ground(xz: Vector2) -> float:
	return -DEPTH if _in_pond(xz) else 0.0


func _water_level(xz: Vector2) -> float:
	return WorldShape.height(_pond_centre(xz)) - 0.25 if _in_pond(xz) else NO_WATER


func _populate() -> void:
	var pickup := ItemPickup.new()
	pickup.name = "Pebble"
	pickup.item = PEBBLE
	pickup.persist_id = content_id("pebble")
	var spot := pebble_spot()
	pickup.position = Vector3(spot.x, height_at(spot), spot.y)
	if not WorldState.is_taken(pickup.persist_id):
		add_content(pickup)
	else:
		pickup.free()


func _pond_centre(xz: Vector2) -> Vector2:
	var centre := SectorMap.center_of(SectorMap.unbounded_cell_at(xz))
	return Vector2(centre.x, centre.z)


func _in_pond(xz: Vector2) -> bool:
	return xz.distance_to(_pond_centre(xz)) < POND_RADIUS
