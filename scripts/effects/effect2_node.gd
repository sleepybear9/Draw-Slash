extends Node2D

@onready var effect2_TEMPLATE = preload("res://Scenes/effects/effect2.tscn")

@onready var dice = $"../dice"
@onready var timer = $Timer
var max_count = 3
var count = 1 

#card effect(make bullet)
func _on_card_effect_2() :
	var new_effect2 = effect2_TEMPLATE.instantiate()
	timer.start()
	new_effect2.dmg = dice.roulette()
	new_effect2.position = global_position
	new_effect2.direction = GameManager.player_dir
	get_tree().root.add_child(new_effect2)
	
	DeckManager.add_card("card2", -1)

func _on_timer_timeout() -> void:
	count += 1
	var new_effect2 = effect2_TEMPLATE.instantiate()
	new_effect2.dmg = dice.roulette()
	new_effect2.position = global_position
	new_effect2.direction = GameManager.player_dir
	get_tree().root.add_child(new_effect2)
	
	if count == max_count: 
		timer.stop()
		count = 1
