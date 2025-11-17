extends Node2D

var toggle : bool = false

@onready var effect1 = $"."
@onready var child1 = $sword1
@onready var child2 = $sword2
@onready var timer = $Timer

func _ready() -> void:
	timer.wait_time = 2.0

func _process(delta: float) -> void:
	if toggle :
		effect1.rotation_degrees += 0.5

func _on_card_pressed() -> void:
	effect1.visible = true
	child1.monitorable = true
	child1.monitoring = true
	child2.monitorable = true
	child2.monitoring = true
	toggle = true
	timer.start()
	timer.connect("timeout", Callable(self, "_timeout"))
	
func _timeout() :
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	toggle = false
