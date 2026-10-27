class_name WorldState
extends RefCounted
## What the player has changed in the world during this game, by stable ids
## such as "B1Cornflower/Cornflower", so streamed content comes back the way
## the player left it. A new field starts a new game and clears it. Not saved
## to disk yet.

static var _taken: Dictionary[String, bool] = {}


static func reset() -> void:
	_taken.clear()


## Records that the thing with this id was taken from the world.
static func mark_taken(id: String) -> void:
	_taken[id] = true


static func is_taken(id: String) -> bool:
	return _taken.has(id)
