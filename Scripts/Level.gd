extends Node2D
class_name Level

@onready var RuneScene = preload("res://Scenes/Rune.tscn")
@onready var merge_area: MergeArea = $MergeArea
@onready var codex_display = $UI/CodexDisplay
@onready var rune_count_display = $UI/CodexDisplay/RuneCount

@export var start_codex: CodexData

# Number of runes to place
@export var rune_count: int = 10

var codex: Codex
var placed_runes: Array
var min_distance: float
var rune_displays: Array

enum GameState {
	PLAYER_MOVE,
	MERGING
}

var state: GameState = GameState.PLAYER_MOVE:
	set(value):
		state = value
		if state == GameState.PLAYER_MOVE:
			update_codex_display()
		

func _ready():
	codex = Codex.new()
	codex.initialize(start_codex)
	create_level()
	update_codex_display()
	
	
func update_codex_display():
	rune_count_display.text = str(codex.draw_pile.size())
	
	for display in rune_displays:
		display.queue_free()
	
	rune_displays = []
	
	for i in range(0, min(codex.draw_pile.size(), 2)):
		var display = RuneScene.instantiate()
		codex_display.add_child(display)
		display.rune_data = codex.draw_pile[i].rune_data
		display.create()
		display.position = Vector2(80 + i * 40, 120)
		rune_displays.append(display)
		
	
func spawn_rune(rune: Rune):
	rune.merge_area = merge_area
	rune.connect("merged", Callable(self, "_on_rune_merged"))
	rune.connect("spell_committed", Callable(self, "_on_rune_committed"))
	merge_area.add_child(rune)
	rune.create()
	
	# set rune sprite to 0 opacity
	rune.sprite.modulate = Color(rune.sprite.modulate.r, rune.sprite.modulate.g, rune.sprite.modulate.b, 0)
	
	var tween = create_tween()
	var sprite = rune.sprite
	tween.tween_property(
		sprite, 
		"modulate", 
		Color(sprite.modulate.r, sprite.modulate.g, sprite.modulate.b, 1),
		1  # Duration in seconds
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	return rune
	
func create_level():
	placed_runes = []
	var active_list = []

	var first_rune_instance = spawn_rune(codex.draw_random())
	# Start with a random initial position
	var initial_position = get_random_position_within_merge_area(first_rune_instance)
	min_distance = first_rune_instance.sprite.texture.get_size().x * first_rune_instance.sprite.scale.x * 2
	var sample_radius = min_distance * 4
	
	first_rune_instance.position = initial_position
	placed_runes.append(first_rune_instance)
	active_list.append(initial_position)

	while active_list.size() > 0 and placed_runes.size() < rune_count:
		var random_index = randi_range(0, active_list.size() - 1)
		var sample_position = active_list[random_index]

		var new_position_found = false
		for i in range(30):  # Try up to 30 candidates around the sample
			var angle = randf() * PI * 2
			var distance = randf_range(min_distance, sample_radius)
			var candidate = sample_position + Vector2(cos(angle), sin(angle)) * distance
			var rune_instance = spawn_rune(codex.draw_random())

			# Check if the candidate is within bounds and not overlapping
			if is_sprite_position_valid(rune_instance.sprite, candidate):
				rune_instance.position = candidate
				placed_runes.append(rune_instance)
				active_list.append(candidate)
				new_position_found = true
				break
			else:
				var rune_data = rune_instance.rune_data
				rune_instance.queue_free()
				codex.add_rune_by_type(rune_data)

		if not new_position_found:
			# Remove this point from the active list if no valid positions were found
			active_list.remove_at(random_index)
			
	#print('placed ', placed_runes.size(), ' runes')

func is_sprite_position_valid(sprite: Sprite2D, new_position: Vector2) -> bool:
	# Ensure position is within merge area bounds
	if not merge_area.test_sprite_within_area(sprite, new_position):
		#print('outside of merge area')
		return false

	# Check against all placed runes
	for rune_instance in placed_runes:
		var distance = new_position.distance_to(rune_instance.position)
		if distance < min_distance:
			#print('too close to existing rune')
			return false

	#print('valid rune placed at ', new_position)
	return true

func get_random_position_within_merge_area(rune: Rune) -> Vector2:
	# Get the bounding box of the MergeArea in world space
	var rect = merge_area.get_rect()

	# Generate a random position within this bounding box
	var x = randf_range(rect.position.x, rect.end.x)
	var y = randf_range(rect.position.y, rect.end.y)
	
	# Ensure the rune's sprite fits within the area at this position
	var sprite_size = rune.sprite.texture.get_size() * rune.sprite.scale.x
	x = clamp(x, rect.position.x + sprite_size.x / 2, rect.end.x - sprite_size.x / 2)
	y = clamp(y, rect.position.y + sprite_size.y / 2, rect.end.y - sprite_size.y / 2)
	
	return Vector2(x, y)
	
func _on_rune_merged(rune: Rune):
	var new_rune = codex.draw()
	if new_rune:
		new_rune = spawn_rune(new_rune)
		new_rune.position = get_nearby_position(rune.position, new_rune)
		placed_runes.append(new_rune)
	
	placed_runes.erase(rune)
	rune.queue_free()
	
	
func get_nearby_position(target_position: Vector2, new_rune: Rune):
	var nearest_distance = INF
	var nearest_position = target_position

	# raycast at different angles until a suitable spawn point is found
	var angle_checks = 360 / 5
	var distance_checks = 4

	for i in range(angle_checks):
		var angle = i * 5 * PI / 180
		
		for j in range(distance_checks):
			var distance = j * min_distance
			var candidate = target_position + Vector2(cos(angle), sin(angle)) * distance
			if is_sprite_position_valid(new_rune.sprite, candidate):
				return candidate

func _on_rune_committed(rune: Rune):
	placed_runes.erase(rune)
	rune.queue_free()
