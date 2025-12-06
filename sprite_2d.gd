extends CharacterBody2D

var speed = 300

func _physics_process(delta):
	var input = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input.x += 1
	if Input.is_action_pressed("ui_left"):
		input.x -= 1
	if Input.is_action_pressed("ui_up"):
		input.y -= 1
	if Input.is_action_pressed("ui_down"):
		input.y += 1

	velocity = input.normalized() * speed
	move_and_slide()
