extends Area2D

@export var speed: float = 2000.0
@export var damage: int = 10
@export var max_distance: float = 1500.0

var direction : Vector2 = Vector2(0, 0)
var start_position : Vector2
var dmg : int

func _ready():
	start_position = global_position
	look_at(global_position + direction)


#bullet movement
func _physics_process(delta: float):
	global_position += direction * speed * delta
	if global_position.distance_to(start_position) > max_distance:
		queue_free()

#bullet collision
func _on_body_entered(body: Node2D):
	print("총알이 ", body.name, "과 충돌했습니다!")
	
	#몬스터 충돌시 사라짐
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	queue_free()
