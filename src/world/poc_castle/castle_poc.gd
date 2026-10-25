extends Node3D
## Castle proof of concept: puts the sword and the player on the generated
## terrain and points the player at the castle. Everything in this scene is
## placeholder content.

@onready var _player: Player = $Player
@onready var _sword_stone: SwordStone = $SwordStone
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_sword_stone.global_position = PocLayout.ground(PocLayout.SWORD) - Vector3.UP * 0.1
	_player.global_position = PocLayout.ground(PocLayout.SPAWN) + Vector3.UP * 0.05
	_player.look_toward(PocLayout.ground(PocLayout.CASTLE_CENTER))
	_hud.track(_player)
