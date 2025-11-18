extends CharacterBody2D

@export var speed: float = 70
@export var attack_distance: float = 50
@export var attack_cooldown: float = 1.0
@export var damage: int = 10
@export var max_hp: int = 30

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"  # 일 default

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange


func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)

	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_att단ack_area_exited"))

	anim.play("walk_down")


# 공격 히트박스 충돌
func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false



# 방향 계산
func _update_direction(vec: Vector2):
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"



# 이동 / 추격
func _physics_process(delta):
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_distance:
		_do_attack()
		return
	
	_chase_player(delta)



func _chase_player(delta):
	var direction = (player.global_position - global_position)
	_update_direction(direction)

	velocity = direction.normalized() * speed
	move_and_slide()

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)



# 공격(애니메이션 1 → 2 순차 재생)
func _do_attack():
	velocity = Vector2.ZERO

	if can_attack:
		can_attack = false
		_perform_attack()


func _perform_attack():
	var base = "attack_" + current_dir + "_"

	# 공격 1
	anim.play(base + "1")
	await anim.animation_finished
	
	# 공격 2
	anim.play(base + "2")
	await anim.animation_finished

	# 실제 데미지 판정 (플레이어가 닿아있는 경우만)
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("데미지:", damage)

	# 공격 쿨타임
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true




# 몬스터 피격 / 죽음

func take_damage(amount: int):
	hp -= amount
	print("몬스터 HP:", hp)

	if hp <= 0:
		_die()


func _die():
	velocity = Vector2.ZERO
	attack_area.monitoring = false

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)

	await anim.animation_finished
	queue_free()
