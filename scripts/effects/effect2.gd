extends Area2D

@export var speed: float = 2000.0
@export var dmg: int = 5
@export var max_distance: float = 1500.0

@onready var audio = $AudioStreamPlayer2D

var direction : Vector2 = Vector2(0, 0)
var start_position : Vector2

func _ready():
	start_position = global_position
	look_at(global_position + direction)
	
	connect("body_entered", Callable(self, "_on_body_entered"))
	audio.play()

#bullet movement
func _physics_process(delta: float):
	global_position += direction * speed * delta
	if global_position.distance_to(start_position) > max_distance:
		queue_free()

#bullet collision
func _on_body_entered(body: PhysicsBody2D):
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "attackrange": 
		var monster = area.get_parent()
		monster.take_damage(dmg)
		print(monster.hp)
