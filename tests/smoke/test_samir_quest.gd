extends GutTest
## Talking to Samir at the oasis: he asks for a cornflower from B1, the
## quest goes into the log (Q), carrying the flower ticks its step, and
## handing it over finishes the quest; the log survives saving and loading.

var _world: Node
var _player: Player
var _hud: Hud
var _samir: Villager


func before_each() -> void:
	_world = (load("res://src/world/field/field.tscn") as PackedScene).instantiate()
	add_child(_world)
	_player = _world.call("player") as Player
	_hud = _world.get_node("Hud") as Hud
	_samir = _world.get_node("Residents/Samir") as Villager


func after_each() -> void:
	_world.free()


func _talk() -> void:
	var talk := _samir.get_node("Talk") as Talk
	talk.interact(_player)


func _pick(words: String) -> void:
	var menu := _hud.choice_menu()
	assert_true(menu.is_open(), "a line to answer")
	var buttons := menu.find_children("*", "Button", true, false)
	for k in buttons.size():
		if (buttons[k] as Button).text.contains(words):
			menu.pick(k)
			return
	fail_test("no answer '%s' in %s" % [words, menu.text()])


func test_every_dialogue_condition_and_action_names_real_things() -> void:
	var dialogue := load("res://data/dialogue/samir.tres") as DialogueData
	var ids: Array[StringName] = []
	for entry in dialogue.entries:
		ids.append(entry.id)
	for entry in dialogue.entries:
		assert_true(DialogueRules.is_valid(entry.when, "&"), "%s: %s" % [entry.id, entry.when])
		for choice in entry.choices:
			assert_true(DialogueRules.is_valid(choice.then, ";"), choice.then)
			assert_true(choice.goto.is_empty() or choice.goto in ids, "goes to %s" % choice.goto)


func test_walking_up_to_samir_offers_to_talk() -> void:
	var prompts: Array[String] = []
	_player.prompt_changed.connect(func(text: String) -> void: prompts.append(text))
	await wait_physics_frames(2)
	_player.global_position = _samir.global_position + Vector3(1.2, 0.3, 0.0)
	await wait_physics_frames(6)
	assert_true(prompts.any(func(text: String) -> bool: return text.contains("Talk to Samir")), "offered: %s" % [prompts])


func test_samir_can_be_talked_to_and_stops_to_listen() -> void:
	assert_not_null(_samir.get_node_or_null("Talk"))
	_talk()
	assert_true(_samir.is_listening())
	assert_string_contains(_hud.choice_menu().text(), "Samir")
	_pick("Goodbye")
	assert_false(_samir.is_listening())
	assert_false(_hud.is_talking())


func test_the_cornflower_quest_from_start_to_finish() -> void:
	_talk()
	_pick("Can I help")
	assert_string_contains(_hud.choice_menu().text(), "B1")
	_pick("bring you a cornflower")
	assert_eq(QuestLog.state(&"samirs_cornflower"), QuestLog.ACTIVE)
	assert_string_contains(_hud.toast_text(), "New quest")
	_pick("back soon")
	# The quest log shows it, the flower not yet picked.
	var log := _hud.quest_panel()
	log.open()
	log.finish_slide()
	await wait_process_frames(2)
	assert_string_contains(log.text(), "A Flower for the Fever")
	assert_string_contains(log.text(), "(0/1)")
	_player.inventory.add(ItemCatalog.find(&"cornflower"))
	await wait_process_frames(2)
	assert_string_contains(log.text(), "[x]")
	log.close()
	# Talking again with the flower hands it over.
	_talk()
	_pick("Here is the cornflower")
	assert_eq(QuestLog.state(&"samirs_cornflower"), QuestLog.DONE)
	assert_false(_player.inventory.has(&"cornflower"), "Samir took it")
	assert_string_contains(_hud.toast_text(), "Quest complete")
	_pick("glad")
	_talk()
	assert_string_contains(_hud.choice_menu().text(), "fever broke")
	_pick("Take care")


func test_without_the_flower_samir_reminds_where_it_grows() -> void:
	QuestLog.start(&"samirs_cornflower")
	_talk()
	assert_string_contains(_hud.choice_menu().text(), "sector B1")
	_pick("on my way")


func test_the_quest_log_is_saved_and_loaded() -> void:
	QuestLog.start(&"samirs_cornflower")
	var saved: Dictionary = _world.call("capture")
	assert_eq(saved["quests"], {"samirs_cornflower": "active"})
	QuestLog.reset()
	_world.call("apply", saved)
	assert_eq(QuestLog.state(&"samirs_cornflower"), QuestLog.ACTIVE)


func test_q_opens_the_quest_log_from_the_left() -> void:
	var press := InputEventAction.new()
	press.action = &"quests"
	press.pressed = true
	Input.parse_input_event(press)
	await wait_process_frames(2)
	var log := _hud.quest_panel()
	assert_true(log.is_open())
	log.finish_slide()
	var drawer := log.get_node("Drawer") as Control
	assert_lt(drawer.get_global_rect().position.x, 1.0, "on the left edge")
	assert_string_contains(log.text(), "No quests yet")
	log.close()
