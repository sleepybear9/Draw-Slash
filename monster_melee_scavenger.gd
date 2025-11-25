extends CharacterBody2D

@export var speed: float = 80
@export var attack_distance: float = 50
@export var dash_distance: float = 70
@export var dash_speed: float = 220
@export var attack_cooldown: float = 1.2
@export var damage: int = 15
@export var max_hp: int = 25

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange


func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))
	anim.play("idle_down")

func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false


func _update_direction(vec: Vector2):
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"


func _physics_process(delta):
	if not player or not can_attack:
		return

	var dist = global_position.distance_to(player.global_position)
	if dist <= attack_distance:
		_do_dash_attack()
		return

	_chase(delta)


func _chase(delta):
	var direction = (player.global_position - global_position)
	_update_direction(direction)
	velocity = direction.normalized() * speed
	move_and_slide()

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)


# -------------------------------
#       DASH 공격 부분
# -------------------------------
func _do_dash_attack():
	can_attack = false
	velocity = Vector2.ZERO

	var dash_anim = "attack_" + current_dir
	anim.play(dash_anim)
	await anim.animation_finished

	# 돌진 방향
	var dash_vec := Vector2.ZERO
	match current_dir:
		"up": dash_vec = Vector2.UP
		"down": dash_vec = Vector2.DOWN
		"left": dash_vec = Vector2.LEFT
		"right": dash_vec = Vector2.RIGHT

	# 대시 이동 (거리 70)
	var target := global_position + dash_vec * dash_distance
	while global_position.distance_to(target) > 5:
		velocity = dash_vec * dash_speed
		move_and_slide()
		await get_tree().process_frame

	velocity = Vector2.ZERO

	# 맞았는지 판정
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("암살자 데미지:", damage)

	# 쿨타임
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# -------------------------------
#       데미지 / 죽음
# -------------------------------
func take_damage(amount: int):
	hp -= amount
	print("암살자 HP:", hp)
	if hp <= 0:
		_die()

func _die():
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)
	await anim.animation_finished
	queue_free()
