extends Control

var is_boss = false
@onready var time = $Time
@onready var timer = $Timer
@onready var hp_bar
@onready var giveCard = $GiveCard
@onready var cardUI = $UI

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

func start():
	timer.start()
	timer.timeout.connect(_on_timer_timeout)
	giveCard.start()
	giveCard.timeout.connect(_on_give_card_timeout)
	hp_bar.show()

func _on_timer_timeout() -> void:
	is_boss = true

func hp_change(hp: int):
	print(hp)
	hp_bar.value = hp

func end():
	timer.paused = true
	giveCard.paused = true
	hp_bar.visible = false
	
func _on_give_card_timeout() -> void:
	DeckManager.add_card("card1", 1)
	cardUI._update_ui()
