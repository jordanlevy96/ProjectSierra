extends Area2D

const TILE_TYPES = ["Fire", "Water", "Earth", "Air"]

var type = ""

signal tile_selected(tile)

func _ready():
	self.type = get_random_element()
	connect("input_event", Callable(self, "_on_Tile_input_event"))

func get_random_element():
	return TILE_TYPES[randi() % TILE_TYPES.size()]

func _on_Tile_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("tile_selected", self)

