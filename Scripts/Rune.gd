extends RigidBody2D
class_name Rune

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var merge_radius: CollisionShape2D = $Area2D/MergeRadius
@onready var area_sprite: Sprite2D = $Area2D/Sprite2D
@onready var selected_shader = preload("res://Assets/Resources/Shaders/selected.gdshader")
@onready var level: Level = get_tree().current_scene # I think this means runes will break if instanced outside of a level

const selected_opacity = 0.5

signal merged(rune: Rune)
signal spell_committed(rune: Rune)

var spell_component = null
var selected: bool = false
var merge_candidates: Array = []
var rune_data: RuneData
var merge_area: MergeArea

func _ready():
	set_process_input(true)
	area_sprite.modulate.a = 0.0
	
func create():
	sprite.texture = rune_data.texture
	sprite.scale = Vector2(rune_data.scale, rune_data.scale)
	
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = sprite.texture.get_size() / 2 * rune_data.scale
	collision_shape.shape = rect_shape
	
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = sprite.texture.get_size().x * rune_data.scale
	merge_radius.shape = circle_shape
	
	area_sprite.scale = Vector2(rune_data.scale, rune_data.scale)
	
	sprite.material = ShaderMaterial.new()
	
	return self
	
func _input(event):
	# skip input checks if other stuff is happening
	if level.state != Level.GameState.PLAYER_MOVE or merge_area == null:
		#print('skipping player input')
		#print(self, ', ', level.state, ', ',  merge_area)
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if spell_component != null:
				spell_component.commit_rune()
				emit_signal("spell_committed", self)
				return
			
			if !selected:
				if collision_shape.shape.get_rect().has_point(to_local(event.position)):
					selected = true
					tween_rune_background(area_sprite, selected_opacity, 1)
					
			else:
				if merge_area.test_sprite_within_area(sprite, merge_area.to_local(event.global_position)):
					var candidates = merge_candidates.size()
					
					# check if it's time for a merge
					# TODO: use lambdas or something to allow different checks
					if candidates >= 2:
						level.state = Level.GameState.MERGING
						while candidates > 0:
							var merged_rune: Rune = merge_candidates.pop_front()
							merged_rune.emit_signal("merged", merged_rune)
							candidates -= 1
						rune_data = rune_data.next
						create()
						level.state = Level.GameState.PLAYER_MOVE
					selected = false
					tween_rune_background(area_sprite, 0, 1)
				#else:
					#print('failed sprite within area check')
				

func _process(_delta):
	if selected:
		var mouse_pos = get_local_mouse_position()
		if !test_move(transform, mouse_pos): # and merge_area.test_sprite_within_area(sprite, get_global_mouse_position()):
			move_and_collide(mouse_pos)

func tween_rune_background(tweening_sprite: Sprite2D, alpha: float, duration: float):
	var tween = create_tween()
	tween.tween_property(
		tweening_sprite, 
		"modulate", 
		Color(sprite.modulate.r, sprite.modulate.g, sprite.modulate.b, alpha),
		duration  # Duration in seconds
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	

func _on_area_2d_area_entered(area):
	var other_rune = area.get_parent()
	
	if other_rune is not Rune:
		return
	
	if selected and other_rune.rune_data.rune_type == rune_data.rune_type:
		var n = merge_candidates.size()
		if (n == 0):
			merge_candidates.append(other_rune)
		else:
			if (n == 1):
				tween_rune_background(merge_candidates[0].area_sprite, 1, 1)
				tween_rune_background(area_sprite, 1, 1)
			tween_rune_background(other_rune.area_sprite, 1, 1)
			merge_candidates.append(other_rune)

func _on_area_2d_area_exited(area):
	var other_rune = area.get_parent()
	if selected and other_rune in merge_candidates:
		tween_rune_background(other_rune.area_sprite, 0, 1)
		var n = merge_candidates.size()
		if (n < 3):
			for candidate in merge_candidates:
				tween_rune_background(candidate.area_sprite, 0, 1)
				tween_rune_background(area_sprite, selected_opacity, 1)
		merge_candidates.erase(other_rune)
