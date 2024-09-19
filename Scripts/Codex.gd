extends Node
class_name Codex

var rune_scene = preload("res://Scenes/Rune.tscn")

var draw_pile: Array = []
var discard_pile: Array = []
var next_rune: Node = null # To store the next rune for preview

# Initialize Codex with a set of runes from CodexData
func initialize(data: CodexData):
	draw_pile.clear()
	discard_pile.clear()
	# Populate the draw_pile based on CodexData
	for rune_type in data.runes.keys():
		var count = data.runes[rune_type]
		for _i in range(count):
			var rune = rune_scene.instantiate()
			rune.rune_data = rune_type
			draw_pile.append(rune)
	# Shuffle the deck and set up the next rune for preview
	shuffle_deck()


# Add a rune of a specific type to the draw_pile
func add_rune_by_type(rune_data: RuneData):
	var rune_instance = rune_scene.instantiate()
	rune_instance.rune_data = rune_data
	draw_pile.append(rune_instance)

func draw():
	var drawn_rune = draw_pile.pop_front()
	discard_pile.append(drawn_rune)

	return drawn_rune

func draw_random():
	if draw_pile.size() == 0:
		return null
	var index = randi() % draw_pile.size()
	var rune = draw_pile[index]
	draw_pile.remove_at(index)
	discard_pile.append(rune)
	#set_next_rune()
	return rune

# Restore the deck by moving all runes from discard_pile to draw_pile and shuffle
func restore_deck():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_deck()


func shuffle_deck():
	for i in range(draw_pile.size()):
		var swap_index = randi() % draw_pile.size()
		var temp = draw_pile[i]
		draw_pile[i] = draw_pile[swap_index]
		draw_pile[swap_index] = temp
