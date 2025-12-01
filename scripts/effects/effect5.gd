extends Node2D

@onready var anim_player = $player

@onready var deck_manager = $"/root/DeckManager"
@onready var dice = $"../dice"

var heal : int

#card effect on
func _on_card_effect_5() -> void:
	heal = dice.roulette()
	anim_player.stop(true)
	anim_player.play("heal")
	deck_manager.add_card("card5", -1)
