extends Control

var is_boss = false
@onready var time = $Time
@onready var timer = $Timer
@onready var hp_bar 

func _enter_tree() -> void:
	hp_bar = $HpProgressBar

func _process(delta: float) -> void:
	if GameManager.is_end:
		end()
	if (!is_boss):
		var remaining = timer.time_left
		var minutes = int(remaining / 60)
		var seconds = int(remaining) % 60

		time.text = "%02d:%02d" % [minutes, seconds]
	else:
		time.text = "Boss appeared!"

func _on_timer_timeout() -> void:
	is_boss = true

func hp_change(hp: int):
	print(hp)
	hp_bar.value = hp

func end():
	timer.paused = true
	hp_bar.visible = false
	
