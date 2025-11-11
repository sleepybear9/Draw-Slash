extends CharacterBody2D

@export var speed = 300.0
@onready var animation = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
		
	var direction = Input.get_vector("Left","Right","Up","Down")
	velocity = direction * speed
	
	if (direction.length() <= 0.1): animation.play("Idle_front")
	else:
		if (abs(direction.x) >= abs(direction.y)): 
			if (direction.x >= 0): 
				animation.play("Run_right")
			else:
				animation.play("Run_left")
		else:
			if (direction.y >= 0): 
				animation.play("Run_front")
			else:
				animation.play("Run_back")
				
	move_and_slide()
