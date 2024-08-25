extends Node
class_name Codex

var rune_scene = preload("res://Scenes/Rune.tscn")

var draw_pile: Array = []
var discard_pile: Array = []

func initialize(data: CodexData):
	# the start conditions are saved as a map of RuneData to int (number of runes of that type)
	for rune_type in data.runes.keys():
		var count = data.runes[rune_type]
		for _i in range(count):
			var rune = rune_scene.instantiate()
			rune.rune_data = rune_type
			draw_pile.append(rune)
			
func add_rune_by_type(rune_data: RuneData):
	var rune_instance = rune_scene.instantiate()
	rune_instance.rune_data = rune_data
	draw_pile.append(rune_instance)

func draw_random():
	if draw_pile.size() == 0:
		return null
	var index = randi() % draw_pile.size()
	var rune = draw_pile[index]
	draw_pile.remove_at(index)
	discard_pile.append(rune)
	return rune
