extends Area2D

@onready var timer = $Timer

func _ready() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))
	
func _on_card_effect_3() -> void: 
	self.visible = true
	self.monitorable = true
	self.monitoring = true
	#여기 direction 수정 필요
	look_at(self.global_position + Vector2.LEFT)
	timer.start()

func _timeout() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
