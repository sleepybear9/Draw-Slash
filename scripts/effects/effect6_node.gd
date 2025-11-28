extends Node2D

@onready var effect6_TEMPLATE = preload("res://Scenes/effects/effect6.tscn")

@onready var deck_manager = $"/root/DeckManager"

func _on_card_effect_6() :
	var new_effect6 = effect6_TEMPLATE.instantiate()
	new_effect6.position = Vector2(0, 0)
	self.add_child(new_effect6)
	deck_manager.add_card("card6", -1)
