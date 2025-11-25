extends Node2D

@onready var anim_player = $player

func _on_card_effect_5() -> void:
	anim_player.stop(true)
	anim_player.play("heal")
