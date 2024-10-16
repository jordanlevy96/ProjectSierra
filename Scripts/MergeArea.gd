extends Area2D
class_name MergeArea

@onready var collision_shape = $CollisionShape2D

func get_rect():
	var rect = collision_shape.shape.get_rect()
	return rect

# test all four corners of the sprite at the given position
func test_sprite_within_area(sprite: Sprite2D, pos: Vector2):
	var sprite_size = sprite.texture.get_size() * sprite.scale.x
	var sprite_rect = Rect2(pos - sprite_size / 2, sprite_size)
	var top_left = sprite_rect.position
	var top_right = Vector2(sprite_rect.end.x, sprite_rect.position.y)
	var bottom_left = Vector2(sprite_rect.position.x, sprite_rect.end.y)
	var bottom_right = sprite_rect.end
	
	var merge_area_rect = get_rect()
	
	var top_left_in = merge_area_rect.has_point(top_left)
	var top_right_in = merge_area_rect.has_point(top_right)
	var bottom_left_in = merge_area_rect.has_point(bottom_left)
	var bottom_right_in = merge_area_rect.has_point(bottom_right)

	# Return the final result of all checks
	return top_left_in and top_right_in and bottom_left_in and bottom_right_in
