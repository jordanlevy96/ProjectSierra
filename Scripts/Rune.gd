extends RigidBody2D
class_name Rune

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var selected_shader = preload("res://Assets/Resources/Shaders/selected.gdshader")
@onready var merge_area: MergeArea = get_parent()
var rect_shape: RectangleShape2D
var selected = false

var tier: int= 0
var rune_type: String = ""

func _ready():
	set_process_input(true)

func init(rune_data: RuneData):
	tier = rune_data.tier
	rune_type = rune_data.rune_type
	sprite.texture = rune_data.texture
	sprite.scale *= rune_data.scale
	rect_shape = RectangleShape2D.new()
	rect_shape.extents = sprite.texture.get_size() / 2 * rune_data.scale

	collision_shape.shape = rect_shape
	sprite.material = ShaderMaterial.new()
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if !selected:
				if collision_shape.shape.get_rect().has_point(to_local(event.position)):
					#sprite.material.shader = selected_shader
					selected = true
			else:
				#sprite.material.shader = null
				selected = false

func _process(delta):
	if selected:
		var mouse_pos = get_local_mouse_position()
		if !test_move(transform, mouse_pos) and merge_area.test_sprite_within_area(sprite, get_global_mouse_position()):
			move_and_collide(mouse_pos)
