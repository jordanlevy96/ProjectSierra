extends Node2D

const GRID_X = 8
const GRID_Y = 4

const TILE = preload("res://Scenes/Tile.tscn")

var selected_tile = null
var tile_layer = 0

func _ready():
	initialize_grid()
	$UIContainer/RestartButton.connect("pressed", Callable(self, "_on_RestartButton_pressed"))

func initialize_grid():
	$TileMap.clear()
	$UIContainer/ScoreLabel.text = "Score: 0"
	for row in range(GRID_Y):
		for col in range(GRID_X):
			$TileMap.set_cell(tile_layer, Vector2i(col, row), 0, Vector2i.ZERO)

func _on_RestartButton_pressed():
	initialize_grid()
