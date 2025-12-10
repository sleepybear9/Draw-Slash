extends Node2D

@onready var effect6_TEMPLATE = preload("res://Scenes/effects/effect6.tscn")

@onready var dice = $"../dice"

#make ice region in map
func _on_card_effect_6() :
	var new_effect6 = effect6_TEMPLATE.instantiate()
	new_effect6.time = dice.roulette()
	new_effect6.position = global_position
	get_tree().root.add_child(new_effect6)
	DeckManager.add_card("card6", -1)
