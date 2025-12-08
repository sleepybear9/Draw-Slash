extends Area2D

@onready var timer = $Timer
@onready var audio = $AudioStreamPlayer2D

var time : int

func _ready():
	#self부분에 적군 tscn을 넣을 것
	#바꾼 후에 적군 함수에서 _on_body_entered로 호출 가능
	#_on_body_entered에서 속박
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	timer.wait_time = time
	timer.connect("timeout", Callable(self, "_timeout"))
	timer.start()
	audio.play()
	
	
func _timeout() :
	queue_free()
