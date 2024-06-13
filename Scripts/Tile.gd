extends Area2D

@export var type: String

signal tile_selected(tile)

func initialize_tile(data):
	type = data.tile_type
	$Sprite2D.texture = data.texture

	# ensure all tiles are 64x64
	var texture_size = $Sprite2D.texture.get_size()
	var desired_size = Vector2(64, 64)
	var scale_factor = desired_size / texture_size
	$Sprite2D.scale = scale_factor
	
func _ready():
	connect("input_event", Callable(self, "_on_Tile_input_event"))

func move_piece(change):
	var move_tween = create_tween()
	var target_position = position + change;
	print(position, name, target_position);
	move_tween.tween_property(
		self, "position", target_position, .4
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	move_tween.play()

func _on_Tile_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("tile_selected", self)
