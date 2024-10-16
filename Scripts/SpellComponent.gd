extends Node2D

@onready var Area = $Area2D
@onready var Sprite = $ComponentSprite
@onready var background_scale = $RuneBackground.scale # TODO: replace all in-engine sprite scaling

var pending_rune_data: RuneData
var component_set: bool = false


func commit_rune():
	component_set = true
	Sprite.texture = pending_rune_data.texture
	Sprite.apply_scale(background_scale)


func _on_area_2d_area_entered(area):
	if component_set:
		return
		
	# FIXME: no error handling if other area ends up here (none exist at time of writing)
	var rune: Rune = area.get_parent()
	
	rune.spell_component = self
	pending_rune_data = rune.rune_data


func _on_area_2d_area_exited(area):
	if component_set:
		return
	
	var rune: Rune = area.get_parent()
	
	rune.spell_component = null
	pending_rune_data = null
	
