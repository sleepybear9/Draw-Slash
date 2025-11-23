extends Node2D

var on : bool = false

@onready var effect1 = $"."
@onready var child1 = $sword1
@onready var child2 = $sword2
@onready var timer = $Timer

func _ready() -> void:
	timer.wait_time = 2.0
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))

func _physics_process(delta):
	if on :
		effect1.rotation_degrees += 1
	
func _timeout() :
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	on = false


func _on_card_effect_1() -> void:
	effect1.visible = true
	child1.monitorable = true
	child1.monitoring = true
	child2.monitorable = true
	child2.monitoring = true
	on = true
	timer.start()
