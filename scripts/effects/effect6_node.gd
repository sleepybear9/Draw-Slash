extends Node2D

@onready var effect6_TEMPLATE = preload("res://Scenes/effects/effect6.tscn")

@onready var dice = $"../dice"

func _on_card_effect_6() :
	var new_effect6 = effect6_TEMPLATE.instantiate()
	new_effect6.time = dice.roulette()
	new_effect6.position = Vector2(0, 0)
	self.add_child(new_effect6)
	DeckManager.add_card("card6", -1)
