extends RigidBody2D

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var selected_shader = preload("res://Assets/Resources/Shaders/selected.gdshader")
@export var merge_area: Area2D
var rect_shape: RectangleShape2D
var selected = false

func _ready():
	assert(merge_area != null)
	set_process_input(true)

	rect_shape = RectangleShape2D.new()
	rect_shape.extents = sprite.texture.get_size() / 2
	collision_shape.shape = rect_shape
	sprite.material = ShaderMaterial.new()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if !selected:
				if sprite.get_rect().has_point(to_local(event.position)):
					#sprite.material.shader = selected_shader
					selected = true
			else:
				#sprite.material.shader = null
				selected = false

func _process(delta):
	if selected:
		# Follow mouse with collision
		var mouse_pos = get_local_mouse_position()
		if !test_move(transform, mouse_pos) and test_sprite_within_area(get_global_mouse_position()):
			move_and_collide(mouse_pos)

func test_sprite_within_area(pos):
	var merge_collision_shape = merge_area.get_node("CollisionShape2D") as CollisionShape2D
	
	# test all four corners of the sprite at the mouse position
	var sprite_size = sprite.texture.get_size() / 2
	var sprite_rect = Rect2(pos - sprite_size, sprite_size * 2)
	var top_left = sprite_rect.position
	var top_right = Vector2(sprite_rect.end.x, sprite_rect.position.y)
	var bottom_left = Vector2(sprite_rect.position.x, sprite_rect.end.y)
	var bottom_right = sprite_rect.end
	
	return (merge_collision_shape.shape.get_rect().has_point(top_left - merge_area.position) and
			merge_collision_shape.shape.get_rect().has_point(top_right - merge_area.position) and
			merge_collision_shape.shape.get_rect().has_point(bottom_left - merge_area.position) and
			merge_collision_shape.shape.get_rect().has_point(bottom_right - merge_area.position))

