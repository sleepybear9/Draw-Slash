extends Control

var timeover = false
@onready var time = $Time
@onready var timer = $Timer
var hp_bar
var exp_bar
@onready var giveCard = $GiveCard
@onready var cardUI = $UI
var is_stop = false

func _enter_tree() -> void:
	hp_bar = $HpProgressBar
	exp_bar = $ExpProgressBar
	randomize()

func _process(delta: float) -> void:
	if GameManager.is_end:
		end()
	if (!timeover):
		var remaining = timer.time_left
		var minutes = int(remaining / 60)
		var seconds = int(remaining) % 60

		time.text = "%02d:%02d" % [minutes, seconds]
	elif(!is_stop):
		if GameManager.is_nonboss[GameManager.stage]:
			time.text = "You are survive!"
			GameManager.clear()
		else:
			time.text = "Boss appeared!"
			GameManager.spawn(GameManager.stage+1)
		is_stop = true
		

func start():
	is_stop = false
	timeover = false
	timer.start()
	timer.timeout.connect(_on_timer_timeout)
	giveCard.start()
	giveCard.timeout.connect(_on_give_card_timeout)
	hp_bar.show()
	exp_bar.show()

func _on_timer_timeout() -> void:
	timeover = true

func hp_change(hp: int):
	hp_bar.value = hp

func exp_changed(exp:float, max_exp:float):
	exp_bar.value = exp
	exp_bar.max_value = max_exp
	print(exp)

func end():
	timer.paused = true
	giveCard.paused = true
	hp_bar.hide()
	exp_bar.hide()
	
func _on_give_card_timeout() -> void:
	DeckManager.add_card("card" + str(randi_range(1, 6)), 1)
	cardUI._update_ui()
