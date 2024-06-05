extends Area2D

@export var tile_data: GameTileData

signal tile_selected(tile)

func initialize_tile(data):
    tile_data = data
    self.type = tile_data.tile_type
    $Sprite2D.texture = tile_data.texture

func _ready():
    connect("input_event", Callable(self, "_on_Tile_input_event"))

func _on_Tile_input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton and event.pressed:
        emit_signal("tile_selected", self)