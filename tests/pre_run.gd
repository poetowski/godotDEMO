extends GutHookScript
## Runs before the suite: the tests check what the code makes, not the land the
## author has sculpted by hand, which can change at any time, and they use their
## own items.


func run() -> void:
	TerrainSculpt.start_empty()
	ItemCatalog.folder = "res://tests/fixtures/items"
