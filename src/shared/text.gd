class_name Text
extends RefCounted
## Localization helpers. Everything the player reads is written in English in
## the code and goes through translation where it's shown: `tr` in nodes,
## `TranslationServer.translate` in static code, `tr_n` and
## `translate_plural` for counts. `npm run strings` collects the literals
## passed to them into locale/messages.pot, the file translators start from.
## Godot's Controls also translate their text on their own; with English
## source strings as the keys, that second pass changes nothing.


## Marks English text that is stored now and translated later, where it's
## shown: exported prompts and titles set by sector designs, which are baked
## into content and must stay English there. Returns the text unchanged.
static func mark(english: String) -> String:
	return english


## Marks several texts, as `mark` does.
static func marks(english: PackedStringArray) -> PackedStringArray:
	return english
