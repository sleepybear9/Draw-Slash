extends CharacterBody2D

@export var max_hp: int = 1000
@export var attack_damage: int = 50
@export var contact_damage: int = 10
@export var attack_interval: float = 8.0

var current_hp: int
var player: Node2D

var attack_index: int = 0 # 패턴 순번 관리


func _ready():
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player") # player 그룹 지정 필요
	_start_attack_cycle()


func _physics_process(delta):
	# 보스는 이동 안함
	velocity = Vector2.ZERO


func _on_body_entered(body):
	# 플레이어가 닿으면 데미지 10
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)


func take_damage(amount: int):
	current_hp -= amount
	print("Boss HP:", current_hp)

	if current_hp <= 0:
		die()


func die():
	print("Boss defeated!")
	queue_free()

# 공격 루프 (8초마다 반복)
func _start_attack_cycle():
	await get_tree().create_timer(attack_interval).timeout
	perform_attack()
	_start_attack_cycle()


func perform_attack():
	match attack_index:
		0:
			attack_pattern_1()
		1:
			attack_pattern_2()
		2:
			attack_pattern_3()

	#반복
	attack_index = (attack_index + 1) % 3


# 공격 패턴 정의


func attack_pattern_1():
	print("[Boss Attack] Pattern 1: 근접 베기")
	# 플레이어가 가까우면 데미지
	if player and global_position.distance_to(player.global_position) < 100:
		player.take_damage(attack_damage)


func attack_pattern_2():
	print("[Boss Attack] Pattern 2: 원거리 파이어볼")
# 스크립트 작성 전 투사체 스파라이트 필요


func attack_pattern_3():
	print("[Boss Attack] Pattern 3: 충격파(광역)")
	# 범위 넓음: 회피해야 하는 패턴
	if player and global_position.distance_to(player.global_position) < 150:
		player.take_damage(attack_damage * 2)
		

# 갑자기 언더테일 아스고어처 주황/파랑 패턴 비슷한거도 만들고싶네
