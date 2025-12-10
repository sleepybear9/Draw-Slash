extends Node2D

@onready var anim = $AnimationPlayer

func _ready() -> void:
	randomize()

#dice roulette(random pick 1-6, and play animation)
func roulette() -> int :
	var r : int = randi_range(1, 6)
	anim.play("result" + str(r))
	print("dice result : ", r)
	return r
