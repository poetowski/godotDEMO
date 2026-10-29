@tool
class_name Landforms
extends RefCounted
## Every region design in data/world/landforms/ that fits the current world,
## and what they do to the land: height, how much of a landform covers a
## point, where trees thin out, and where the ground turns to rock or snow.
## Loaded by WorldShape.configure; read-only afterwards, so worker threads
## may ask.

const FOLDER := "res://data/world/landforms"
## Ground colours (sRGB) the grass gives way to.
const ROCK := Color(0.48, 0.45, 0.42)
const SNOW := Color(0.93, 0.95, 0.98)
## How steep (1 - the ground's up component) bare rock begins and takes over.
const ROCK_FROM := 0.2
const ROCK_FULL := 0.34
## Rise per metre up to which jungle grows on tropical landforms.
const TROPICAL_MAX_SLOPE := 1.7

static var _sets: Array[LandformSet] = []
static var _all: Array[Landform] = []
static var _boxes: Array[Rect2] = []


## Loads the sets that fit the current world (RegionMap).
static func load_all() -> void:
	_sets.clear()
	_all.clear()
	_boxes.clear()
	if not DirAccess.dir_exists_absolute(FOLDER):
		return
	for file in ResourceLoader.list_directory(FOLDER):
		var landform_set := load(FOLDER.path_join(file)) as LandformSet
		if landform_set == null or not landform_set.fits_world():
			continue
		_sets.append(landform_set)
		for landform in landform_set.landforms:
			landform.prepare()
			_all.append(landform)
			_boxes.append(landform.bounds())


static func sets() -> Array[LandformSet]:
	return _sets


## Metres all landforms add at a world x and z.
static func height(xz: Vector2) -> float:
	var north := Vector2(xz.x, -xz.y)
	var total := 0.0
	for k in _all.size():
		if _boxes[k].has_point(north):
			total += _all[k].height_at(xz)
	return total


## How thick trees grow here compared with the woods around, 0 to 1, given
## the ground's height.
static func tree_factor(xz: Vector2, ground: float) -> float:
	var north := Vector2(xz.x, -xz.y)
	var factor := 1.0
	for k in _all.size():
		if not _boxes[k].has_point(north):
			continue
		var landform := _all[k]
		var cover := landform.cover_at(xz)
		if cover <= 0.0:
			continue
		factor *= lerpf(1.0, landform.tree_density, cover)
		if landform.tree_line > 0.0 and ground > landform.tree_line:
			factor *= 1.0 - cover
	return factor


## How much the woods here are tropical, 0 to 1: the cover of the tropical
## landforms over the point.
static func tropical(xz: Vector2) -> float:
	var north := Vector2(xz.x, -xz.y)
	var most := 0.0
	for k in _all.size():
		if _all[k].tropical and _boxes[k].has_point(north):
			most = maxf(most, _all[k].cover_at(xz))
	return most


## The ground's colour at a point for the grass shader (alpha: how much grass
## shows): grass, rock where it's steep, snow above a landform's snow line.
## `up` is the ground's up component (1 flat, 0 a wall).
static func ground_tint(xz: Vector2, ground: float, up: float) -> Color:
	# Jungle clings to steeper slopes than temperate grass: only cliffs show
	# rock on tropical landforms.
	var lush := tropical(xz)
	var rock := smoothstep(lerpf(ROCK_FROM, 0.5, lush), lerpf(ROCK_FULL, 0.72, lush), 1.0 - up)
	var tint := Color(ROCK.r, ROCK.g, ROCK.b, 1.0 - rock)
	var north := Vector2(xz.x, -xz.y)
	for k in _all.size():
		var landform := _all[k]
		if landform.snow_line <= 0.0 or ground <= landform.snow_line or not _boxes[k].has_point(north):
			continue
		var snow := smoothstep(landform.snow_line, landform.snow_line + 6.0, ground) * landform.cover_at(xz)
		tint = Color(lerpf(tint.r, SNOW.r, snow), lerpf(tint.g, SNOW.g, snow), lerpf(tint.b, SNOW.b, snow), tint.a * (1.0 - snow))
	return tint
