extends Node2D

@onready var effect1 = $"."
@onready var child1 = $boomerang1
@onready var child2 = $boomerang2
@onready var timer = $Timer
@onready var audio = $AudioStreamPlayer

@onready var dice = $"../dice"

var dmg : int

var enabled : bool = false

func _ready() -> void:
	timer.wait_time = 2.0
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))

#rotation
func _physics_process(delta):
	if enabled == true :
		effect1.rotation_degrees -= 1
		child1.rotation += 0.2
		child2.rotation += 0.2
	
#card effect off
func _timeout() :
	effect1.visible = false
	child1.monitorable = false
	child1.monitoring = false
	child2.monitorable = false
	child2.monitoring = false
	enabled = false

#card effect on
func _on_card_effect_4() -> void:
	if enabled == false :
		dmg = dice.roulette()
		effect1.visible = true
		child1.monitorable = true
		child1.monitoring = true
		child2.monitorable = true
		child2.monitoring = true
		DeckManager.add_card("card4", -1)
		timer.start()
		enabled = true

func _on_boomerang_area_entered(area: Area2D) -> void:
	if area.name == "attackrange": 
		
		var monster = area.get_parent()
		if monster.take_damage(dmg): audio.play()
		print(monster.hp)
