extends Node2D

@onready var scene1 = $scene1
@onready var scene2 = $scene2
@onready var scene3 = $scene3
var tween

var now : int = 0

func _ready() -> void:
	tween = create_tween()

func _process(delta: float) -> void:
	if visible and Input.is_action_just_pressed("click"):
		now = min(now+1,3)
		print(now)
		next()

func start():
	#scene1
	scene1.visible = true
	scene2.visible = false
	scene3.visible = false

func next():
	if now == 1 :
		scene1.visible = false
		scene2.visible = true
		
	#scene3
	elif now == 2 :
		print("2")
		scene2.visible = false
		scene3.visible = true
		
	#go to game
	elif now == 3 :
		print("end")
		visible = false
		GameManager.start()
