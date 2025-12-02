extends Node2D
@onready var effect1 = $"."
@onready var child1 = $sword1
@onready var child2 = $sword2
@onready var timer = $Timer

@onready var dice = $"../dice"

var enabled : bool = false

var dmg : int

func _ready() -> void:
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))

func _physics_process(delta):
	if enabled == true :
		effect1.rotation_degrees += deg_to_rad(180)
	
#card effect off
func _timeout() :
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	enabled = false

#card effect on
func _on_card_effect_1() -> void:
	if enabled == false :
		dmg = dice.roulette()
		effect1.visible = true
		child1.monitorable = true
		child1.monitoring = true
		child2.monitorable = true
		child2.monitoring = true
		DeckManager.add_card("card1", -1)
		timer.start()
		enabled = true
