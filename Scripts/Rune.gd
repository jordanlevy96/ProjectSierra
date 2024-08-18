extends RigidBody2D
class_name Rune

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var merge_radius: CollisionShape2D = $Area2D/MergeRadius
@onready var area_sprite: Sprite2D = $Area2D/Sprite2D
@onready var selected_shader = preload("res://Assets/Resources/Shaders/selected.gdshader")
@onready var merge_area: MergeArea = get_parent()

const selected_opacity = 0.5

var selected: bool = false
var merge_candidates: Array = []
var rune_data: RuneData

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
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if !selected:
				if collision_shape.shape.get_rect().has_point(to_local(event.position)):
					selected = true
					print('selected ', self)
					tween_rune_background(area_sprite, selected_opacity, 1)
					
			else:
				if merge_candidates.size() >= 2:
					while merge_candidates.size() > 0:
						var merged_rune = merge_candidates.pop_front()
						merged_rune.queue_free()
					rune_data = rune_data.next
					create()
				selected = false
				tween_rune_background(area_sprite, 0, 1)

func _process(delta):
	if selected:
		var mouse_pos = get_local_mouse_position()
		if !test_move(transform, mouse_pos) and merge_area.test_sprite_within_area(sprite, get_global_mouse_position()):
			move_and_collide(mouse_pos)

func tween_rune_background(sprite: Sprite2D, alpha: float, duration: float):
	var tween = create_tween()
	tween.tween_property(
		sprite, 
		"modulate", 
		Color(sprite.modulate.r, sprite.modulate.g, sprite.modulate.b, alpha),
		duration  # Duration in seconds
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	

func _on_area_2d_area_entered(area):
	var other_rune = area.get_parent()
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
