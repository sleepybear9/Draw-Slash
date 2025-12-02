extends Node2D

@onready var effect2_TEMPLATE = preload("res://Scenes/effects/effect2.tscn")

@onready var dice = $"../dice"

#card effect(make bullet)
func _on_card_effect_2() :
	var new_effect2 = effect2_TEMPLATE.instantiate()
	new_effect2.dmg = dice.roulette()
	new_effect2.position = global_position
	#이 부분 수정(방향)
	new_effect2.direction = Vector2.RIGHT
	get_tree().root.add_child(new_effect2)
	
	DeckManager.add_card("card2", -1)
