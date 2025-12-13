extends Area2D

@onready var timer = $Timer
@onready var audio = $AudioStreamPlayer2D

var dmg : int = 0
var time : int

func _ready():
	#self부분에 적군 tscn을 넣을 것
	#바꾼 후에 적군 함수에서 _on_body_entered로 호출 가능
	#_on_body_entered에서 속박
	timer.wait_time = time
	timer.start()
	audio.play()	

func _timeout() :
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "attackrange": 
		var monster = area.get_parent()
		monster.speed = 0
		timer.timeout.connect(Callable(monster, "_on_unstun"), CONNECT_ONE_SHOT)
