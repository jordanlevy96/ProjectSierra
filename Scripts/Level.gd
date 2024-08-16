extends Node2D

@onready var RuneScene = preload("res://Scenes/Rune.tscn")
@onready var merge_area: MergeArea = $MergeArea

# Minimum distance between runes to avoid overlap
var min_distance

# Number of runes to place
@export var rune_count: int = 10
@export var start_codex: CodexData
#@export var example_rune: RuneData

var codex: Codex

func _ready():
	codex = Codex.new()
	codex.initialize(start_codex)
	create_level()
	
func spawn_rune(rune: Rune):
	merge_area.add_child(rune)
	return rune.create()
	
func create_level():
	var placed_runes = []
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
			if is_sprite_position_valid(rune_instance.sprite, candidate, placed_runes):
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
			
	print('placed ', placed_runes.size(), ' runes')

func is_sprite_position_valid(sprite: Sprite2D, position: Vector2, placed_runes: Array) -> bool:
	# Ensure position is within merge area bounds
	if not merge_area.test_sprite_within_area(sprite, merge_area.to_global(position)):
		#print('outside of merge area')
		return false

	# Check against all placed runes
	for rune_instance in placed_runes:
		var distance = position.distance_to(rune_instance.position)
		if distance < min_distance:
			#print('too close to existing rune')
			return false

	return true

func get_random_position_within_merge_area(rune: Rune) -> Vector2:
	# Get the bounding box of the MergeArea in world space
	var rect = merge_area.get_rect()

	# Generate a random position within this bounding box
	var x = randf_range(rect.position.x, rect.position.x + rect.size.x)
	var y = randf_range(rect.position.y, rect.position.y + rect.size.y)
	
	# Ensure the rune's sprite fits within the area at this position
	var sprite_size = rune.sprite.texture.get_size() / 2 * rune.sprite.scale.x
	x = clamp(x, rect.position.x + sprite_size.x, rect.end.x - sprite_size.x)
	y = clamp(y, rect.position.y + sprite_size.y, rect.end.y - sprite_size.y)
	
	return Vector2(x, y)
