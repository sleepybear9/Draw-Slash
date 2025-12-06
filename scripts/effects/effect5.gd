extends Node2D

@onready var anim_player = $player

@onready var dice = $"../dice"
@onready var audio = $AudioStreamPlayer2D

var heal : int

#card effect on
func _on_card_effect_5() -> void:
	heal = dice.roulette()
	anim_player.stop(true)
	anim_player.play("heal")
	self.get_parent().get_parent().cure(heal*15)
	DeckManager.add_card("card5", -1)
	audio.play()
