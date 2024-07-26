extends Node

const GRID_X = 12
const GRID_Y = 8
const rune_scene: PackedScene = preload("res://Scenes/Rune.tscn")

@export var start: Vector2
@export var offset: int = 64

var grid = []
var spell_manager

func _ready():
	# spell_manager = $SpellManager
	pass

func initialize_level():
	grid = init_2d_array(GRID_X, GRID_Y)
	initialize_grid()

func init_2d_array(width, height):
	var arr = []
	for i in width:
		arr.append([])
		for j in height:
			arr[i].append(null)
	return arr

func initialize_grid():
	for i in GRID_X:
		for j in GRID_Y:
			var rune = rune_scene.instantiate()
			rune.initialize()
			add_child(rune)
			rune.position = grid_to_pixel(i, j)
			grid[i][j] = rune

func grid_to_pixel(row, col):
	var x = start.x + offset * row
	var y = start.y - offset * col
	return Vector2(x, y)

func pixel_to_grid(pixel: Vector2):
	var x = round((pixel.x - start.x) / offset)
	var y = round((pixel.y - start.y) / -offset)
	return Vector2(x, y)	

func handle_merge():
	pass
