extends Node2D

const GRID_X = 12
const GRID_Y = 8
const tile_scene: PackedScene = preload("res://Scenes/Tile.tscn")
const resource_folder: String = "res://Assets/Resources/Tiles/"

@export var starter_deck: StarterDeck
@export var start: Vector2
@export var offset: int = 64
@export var seed: String

var rng = RandomNumberGenerator.new()
var deck = Deck.new()

var tile_selected = false
var tile_layer = 0
var grid = []

var first_touch: Vector2
var final_touch: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	print(seed)
	rng.seed = hash(seed)
	print(rng.seed)

	assert(starter_deck != null, "Starter deck not set")
	deck.initialize_deck(starter_deck, rng, resource_folder)


	$UIContainer/ScoreLabel.text = "Score: 0"
	$UIContainer/RestartButton.connect("pressed", Callable(self, "_on_RestartButton_pressed"))

	grid = init_2d_array(GRID_X, GRID_Y)
	initialize_grid()
	
func find_matches():
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] != null:
				var current_tile = grid[i][j]
				print(current_tile)
				# if i > 0 && i < grid_size.x - 1:
					
func match_at(i, j, type):
	if i > 1:
		var left = grid[i-1][j]
		var left2 = grid[i-2][j]
		if left != null && left2 != null:
			if left.type == type && left2.type == type:
				return true
	if j > 1:
		var down = grid[i][j-1]
		var down2 = grid[i][j-2]
		if down != null && down2 != null:
			if down.type == type && down2.type == type:
				return true

	return false
		
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
			var tile = tile_scene.instantiate()
			var tile_data = deck.get_random_tile()
			tile.initialize_tile(tile_data)
			# var count = 0
			# while match_at(i, j, tile.get_type()):
			# 	assert(count < 100, "Unable to initialize grid without matches")
			# 	# if it matches, make a new tile instead
			# 	tile.queue_free()
			# 	tile = tile_scene.instantiate()
			# 	count += 1
				
			add_child(tile)
			tile.position = grid_to_pixel(i, j)
			grid[i][j] = tile

func grid_to_pixel(col, row):
	var x = start.x + offset * col
	var y = start.y - offset * row
	return Vector2(x, y)

func pixel_to_grid(pixel: Vector2):
	var x = round((pixel.x - start.x) / offset)
	var y = round((pixel.y - start.y) / -offset)
	return Vector2(x, y)	

func is_in_grid(input):
	var row = input.x
	var col = input.y
	
	if col >= 0 && col < GRID_Y:
		if row >= 0 && row < GRID_X:
			return true
	return false

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		first_touch = pixel_to_grid(get_global_mouse_position())
		if is_in_grid(first_touch):
			tile_selected = true
		else:
			tile_selected = false
	if Input.is_action_just_released("ui_touch"):
		final_touch = pixel_to_grid(get_global_mouse_position())
		if tile_selected && is_in_grid(final_touch):
			handle_swap()
		else:
			tile_selected = false

func swap_pieces(piece, direction):
	var row = piece.y
	var column = piece.x

	var first_piece = grid[column][row];
	var other_piece = grid[column + direction.x][row + direction.y];

	grid[column + direction.x][row + direction.y] = first_piece;
	grid[column][row] = other_piece;
	first_piece.move_piece(Vector2(direction.x * offset, direction.y * -offset));
	other_piece.move_piece(Vector2(direction.x * -offset, direction.y * offset));
	# find_matches_timer.start();

func handle_swap():
	var difference = final_touch - first_touch;
	if(abs(difference.x) > abs(difference.y)):
		if(difference.x > 0):
			swap_pieces(first_touch, Vector2(1, 0));
		elif(difference.x < 0):
			swap_pieces(first_touch, Vector2(-1, 0));
	elif(abs(difference.y) > abs(difference.x)):
		if(difference.y > 0):
			swap_pieces(first_touch, Vector2(0, 1));
		elif(difference.y < 0):
			swap_pieces(first_touch, Vector2(0, -1));


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	touch_input()	

func _on_RestartButton_pressed():
	initialize_grid()
