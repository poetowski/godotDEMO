extends GutTest
## Localization: everything the player reads goes through translation, and
## locale/messages.pot lists all of it. The game ships in English only for
## now; a stand-in translation proves the text would change.

const EXTRACTOR := preload("res://tools/extract_strings.gd")
const STAND_IN := "eo"

var _translation: Translation


func before_each() -> void:
	_translation = Translation.new()
	_translation.locale = STAND_IN
	for english: String in ["[E]  Pick up %s", "Cornflower", "Empty", "Inventory", "Sector %s", "Pray"]:
		_translation.add_message(english, "<" + english + ">")
	TranslationServer.add_translation(_translation)
	TranslationServer.set_locale(STAND_IN)


func after_each() -> void:
	TranslationServer.remove_translation(_translation)
	TranslationServer.set_locale("en")


func test_the_string_catalog_is_up_to_date() -> void:
	assert_true(FileAccess.file_exists(EXTRACTOR.OUTPUT), "run npm run strings")
	assert_eq(FileAccess.get_file_as_string(EXTRACTOR.OUTPUT), EXTRACTOR.catalog(), "out of date: run npm run strings")


func test_the_catalog_holds_ui_item_and_design_text() -> void:
	var catalog: String = EXTRACTOR.catalog()
	for english: String in ["Inventory", "Cornflower", "Fly Agaric", "[E]  Stand before the statue", "the flame katana", "Pray", "Save game"]:
		assert_string_contains(catalog, "msgid \"%s\"" % english)
	assert_string_contains(catalog, "msgid_plural \"%d items\"")


func test_prompts_and_item_names_are_translated() -> void:
	var pickup := ItemPickup.new()
	pickup.item = preload("res://data/items/cornflower.tres")
	assert_eq(pickup.prompt(), "<[E]  Pick up %s>" % "<Cornflower>")
	pickup.free()


func test_static_text_is_translated() -> void:
	SaveGame.folder = "user://test_saves"
	assert_eq(SaveGame.describe("2"), "<Empty>")
	SaveGame.folder = "user://saves"


func test_the_hud_shows_translated_text() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.show_sector("B1")
	assert_eq(hud.sector_text(), "<Sector %s>" % "B1")
	hud.inventory_panel().bind(Inventory.new())
	hud.choice_menu().ask("Before the statue", PackedStringArray(["Pray", "Cry"]))
	var labels: Array[String] = []
	for node in hud.find_children("*", "Button", true, false):
		labels.append((node as Button).text)
	assert_has(labels, "1   <Pray>")
	assert_has(labels, "2   Cry", "untranslated text stays English")


## Text set straight from a string literal skips translation. Every literal
## the player reads goes through tr() (or TranslationServer, or Text.mark).
func test_no_player_text_skips_translation() -> void:
	var direct := RegEx.create_from_string("(\\.text = |_button\\(|_label\\(|notify\\(|ask\\()\"[A-Za-z]")
	for path: String in EXTRACTOR._scripts("res://src"):
		if path.begins_with("res://src/autoload/"):
			continue
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for k in lines.size():
			assert_null(direct.search(lines[k]), "%s:%d sets text without tr(): %s" % [path, k + 1, lines[k].strip_edges()])
