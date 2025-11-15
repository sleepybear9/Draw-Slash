extends CharacterBody2D

@export var speed = 165.0
@export var hp = 100

@onready var anim = $AnimatedSprite2D
@onready var dmg_delayer = $Timer

var is_left = false
var is_turning = false
var is_attacked = false
var is_alive = true

func _physics_process(delta: float) -> void:
	var dir = Input.get_vector("Left","Right","Up","Down")
	velocity = dir * speed

	if hp > 0:
		update_animation(dir)
		if !is_attacked: move_and_slide()
	elif is_alive:
		anim.play("Death")
		is_alive = false
		if !anim.is_playing():
			queue_free()


func update_animation(dir: Vector2) -> void:
	if is_attacked:
		return

	if is_turning:
		return

	if dir.length() <= 0.1:
		anim.play("Idle")
		return

	if dir.x != 0:
		var going_left = dir.x < 0
		if going_left != is_left:
			start_turn(going_left)
			return

	anim.flip_h = is_left
	anim.play("Walk")


func start_turn(going_left: bool) -> void:
	is_turning = true
	is_left = going_left

	anim.flip_h = !going_left

	anim.play("Turn")
	anim.animation_finished.connect(_on_turn_finished, CONNECT_ONE_SHOT)


func _on_turn_finished() -> void:
	is_turning = false
	anim.flip_h = is_left

	anim.play("Walk")


func take_damage(dmg: int) -> void:
	if !is_attacked:
		is_attacked = true
		dmg_delayer.start()

		hp -= dmg
		if hp <= 0:
			hp = 0
		else:
			anim.play("Hurt")
			anim.animation_finished.connect(_on_hurt_finished, CONNECT_ONE_SHOT)


func _on_hurt_finished() -> void:
	is_attacked = false


func _on_dmg_timeout() -> void:
	is_attacked = false
