extends Node2D

const GRID_X = 12
const GRID_Y = 8
const rune_scene: PackedScene = preload("res://Scenes/Rune.tscn")
const resource_folder: String = "res://Assets/Resources/Tiles/"
const special_tile_shader: Shader = preload("res://Assets/Resources/Shaders/match-4.gdshader")

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
			var rune = rune_scene.instantiate()
			var rune_data = deck.get_random_tile()
			rune.initialize(rune_data)
			var count = 0
			while match_at(i, j, rune.type):
				assert(count < 100, "Unable to initialize grid without matches")
				# if it matches, make a new tile instead
				rune_data = deck.get_random_tile()
				rune.initialize(rune_data)
				count += 1
				
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
				while j2 < GRID_Y and grid[i][j2] != null and grid[i][j2].type == type and !grid[i][j2].matched:
					count += 1
					j2 += 1
				if count >= 3:
					var horz_match = grid[i].slice(j, j2)
					horz_match.map(func(tile): tile.matched = true)
					matches.append(horz_match)

				count = 1
				
				# Check vertical
				var i2 = i + 1
				while i2 < GRID_X and grid[i2][j] != null and grid[i2][j].type == type and !grid[i2][j].matched:
					count += 1
					i2 += 1
				if count >= 3:
					var vert_match = []
					while (count > 0):
						vert_match.append(grid[i+count-1][j])
						count -= 1

					vert_match.map(func(tile): tile.matched = true)
					matches.append(vert_match)

	return matches

func handle_matches(matches):
	var special_tile
	for tiles_in_match in matches:
		if tiles_in_match.size() > 3:
			special_tile = tiles_in_match[0]  # default to first in match
			for tile in tiles_in_match:
				if (piece1 != null && piece1 == tile) || (piece2 != null && piece2 == tile):
					special_tile = tile
					break

			# TODO: different handling for 4- or 5- matches
			var shader_material = ShaderMaterial.new()
			shader_material.shader = special_tile_shader
			shader_material.set_shader_parameter("color1", Color(1.0, 0.0, 0.0, 1.0))  # Red
			shader_material.set_shader_parameter("color2", Color(0.0, 0.0, 1.0, 1.0))  # Blue
			shader_material.set_shader_parameter("threshold", 1.0)
			shader_material.set_shader_parameter("intensity", 1.0)
			shader_material.set_shader_parameter("opacity", 1.0)
			shader_material.set_shader_parameter("glow_color", Color(1.0, 1.0, 0.0, 1.0))  # Yellow
			
			special_tile.get_node("Sprite2D").material = shader_material
			special_tile.matched = false
		
		# TODO: destruction animation
		# for i in range(len(tiles_in_match)):
		# 	var tile = tiles_in_match[i]
		# 	if tile != special_tile:
		# 		tile.get_node("Sprite2D").modulate = Color(1, 1, 1, 0.5)
	
	get_node("DestroyTimer").start()

func destroy_matched():
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
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] == null:
				for k in range(j + 1, GRID_Y):
					if grid[i][k] != null:
						grid[i][k].move_slower(grid_to_pixel(i, j))
						grid[i][j] = grid[i][k]
						grid[i][k] = null
						break
	get_node("RefillTimer").start()

func refill_columns():
	for i in GRID_X:
		for j in GRID_Y:
			if grid[i][j] == null:
				# Instance that piece from the array
				var piece = rune_scene.instantiate();
				piece.initialize(deck.get_random_tile());
				add_child(piece);
				piece.position = Vector2(grid_to_pixel(i, j).x, -300 - offset*j) # -300 is just above the grid
				piece.move_slower(grid_to_pixel(i, j));
				grid[i][j] = piece;
	
	get_node("DelayTimer").start()

func after_refill():
	piece1 = null
	piece2 = null

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

func _on_delay_timer_timeout():
	after_refill()
