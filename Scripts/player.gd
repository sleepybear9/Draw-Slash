extends CharacterBody2D

@export var speed = 175.0
@onready var animation = $AnimatedSprite2D
var isLeft

func _physics_process(delta: float) -> void:
		
	var direction = Input.get_vector("Left","Right","Up","Down")
	velocity = direction * speed
	
	if (direction.length() <= 0.1): animation.play("Idle")
	else:
		if (direction.x >= 0): 
			isLeft = false
			animation.flip_h = false
		else:				
			isLeft = true
			animation.flip_h = true
		animation.play("Walk")
				
	move_and_slide()
