extends Node2D

const GRID_X = 12
const GRID_Y = 8
const tile_scene: PackedScene = preload("res://Scenes/Tile.tscn")
const resource_folder: String = "res://Assets/Resources/Tiles/"

@export var starter_deck: StarterDeck
@export var start: Vector2
@export var offset: int = 64
@export var game_seed: String

var rng = RandomNumberGenerator.new()
var deck = Deck.new()

var tile_selected = false
var tile_layer = 0
var grid = []

enum GameState {
	MOVE,
	WAIT,
	WIN,
	LOSE
}

var state: GameState = GameState.MOVE

# Move variables
var move_checked = false
var piece1 = null
var piece2 = null
var last_location = null
var last_direction = null

var first_touch: Vector2
var final_touch: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	print(game_seed)
	rng.seed = hash(game_seed)
	print(rng.seed)

	assert(starter_deck != null, "Starter deck not set")
	deck.initialize_deck(starter_deck, rng, resource_folder)

	$UIContainer/ScoreLabel.text = "Score: 0"
	$UIContainer/RestartButton.connect("pressed", Callable(self, "_on_RestartButton_pressed"))

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
			var tile = tile_scene.instantiate()
			var tile_data = deck.get_random_tile()
			tile.initialize_tile(tile_data)
			var count = 0
			while match_at(i, j, tile.type):
				assert(count < 100, "Unable to initialize grid without matches")
				# if it matches, make a new tile instead
				tile_data = deck.get_random_tile()
				tile.initialize_tile(tile_data)
				count += 1
				
			add_child(tile)
			tile.position = grid_to_pixel(i, j)
			grid[i][j] = tile

func grid_to_pixel(row, col):
	var x = start.x + offset * row
	var y = start.y - offset * col
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

func swap_pieces(piece, direction):
	var row = piece.y
	var column = piece.x

	var first_piece = grid[column][row]
	var other_piece = grid[column + direction.x][row + direction.y]

	piece1 = first_piece
	piece2 = other_piece
	last_location = Vector2(column, row)
	last_direction = direction

	grid[column + direction.x][row + direction.y] = first_piece
	grid[column][row] = other_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y));
	other_piece.move(grid_to_pixel(column, row));
	if !move_checked:
		handle_matches(find_matches())

func swap_back():
	print("swap_back")
	if piece1 != null && piece2 != null:
		swap_pieces(last_location, last_direction)
	move_checked = false;
	state = GameState.MOVE
	
func find_matches():
	var matches = []
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] != null:
				var type = grid[i][j].type
				var count = 1
				
				# Check horizontal
				var j2 = j + 1
				while j2 < GRID_Y and grid[i][j2] != null and grid[i][j2].type == type:
					count += 1
					j2 += 1
				if count >= 3:
					matches.append(grid[i].slice(j, j2))

				count = 1
				
				# Check vertical
				var i2 = i + 1
				while i2 < GRID_X and grid[i2][j] != null and grid[i2][j].type == type:
					count += 1
					i2 += 1
				if count >= 3:
					var vert_match = []
					while (count > 0):
						print(count)
						vert_match.append(grid[i+count-1][j])
						count -= 1
					matches.append(vert_match)

	return matches

func handle_matches(matches):
	for tiles_in_match in matches:
		for tile in tiles_in_match:
			tile.matched = true
			tile.get_node("Sprite2D").modulate = Color(1, 1, 1, 0.5)
			get_node("DestroyTimer").start()

func destroy_matched():
	print("destroy_matched");
	var was_matched = false;
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] != null:
				if grid[i][j].matched:
					was_matched = true
					grid[i][j].queue_free()
					grid[i][j] = null
	move_checked = true;
	if was_matched:
		get_node("CollapseTimer").start()
		piece1 = null
		piece2 = null
	else:
		swap_back()

func collapse_columns():
	print("collapse_columns")
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] == null:
				for k in range(j + 1, GRID_Y):
					if grid[i][k] != null:
						grid[i][k].move(grid_to_pixel(i, j))
						grid[i][j] = grid[i][k]
						grid[i][k] = null
						break
	get_node("RefillTimer").start()

func refill_columns():
	print("refill_timer");
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] == null:

				# Instance that piece from the array
				var piece = tile_scene.instantiate();
				piece.initialize_tile(deck.get_random_tile());
				add_child(piece);
				piece.position = grid_to_pixel(i, j + offset);
				piece.move(grid_to_pixel(i, j));
				grid[i][j] = piece;
	after_refill();

func after_refill():
	print("after_refill");
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] != null:
				if match_at(i, j, grid[i][j].type):
					handle_matches(find_matches())
					return;
	move_checked = false;
	state = GameState.MOVE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if state == GameState.MOVE:
		touch_input()	

# TODO: integrate with level menu
func _on_RestartButton_pressed():
	for i in GRID_X:
		for j in GRID_Y:
			grid[i][j].queue_free()
			grid[i][j] = null

	initialize_grid()

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()