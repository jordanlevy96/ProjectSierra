extends Node2D

const GRID_X = 8
const GRID_Y = 4

@export var tile_scene: PackedScene = preload("res://Scenes/Tile.tscn")
@export var resource_folder: String = "res://Assets/Resources/Tiles/"

var selected_tile = null
var tile_layer = 0

func _ready():
	initialize_grid()
	$UIContainer/RestartButton.connect("pressed", Callable(self, "_on_RestartButton_pressed"))

	var tile_data_array = load_tile_resources(resource_folder)
	for data in tile_data_array:
		create_tile(data)

func initialize_grid():
	$TileMap.clear()
	$UIContainer/ScoreLabel.text = "Score: 0"
	for row in range(GRID_Y):
		for col in range(GRID_X):
			$TileMap.set_cell(tile_layer, Vector2i(col, row), 0, Vector2i.ZERO)

func load_tile_resources(path):
	var dir = DirAccess.open(path)
	var resources = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".tres"):
				var resource_path = path.plus_file(file_name)
				var resource = load(resource_path)
				if resource != null:
					resources.append(resource)
			file_name = dir.get_next()
		dir.list_dir_end()
	return resources

func create_tile(data):
	var tile_instance = tile_scene.instantiate()
	tile_instance.initialize_tile(data)
	add_child(tile_instance)

func _on_RestartButton_pressed():
	initialize_grid()
