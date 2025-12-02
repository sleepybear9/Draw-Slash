extends CharacterBody2D

@export var speed: float = 50
@export var attack_distance: float = 50
@export var attack_cooldown: float = 1.0
@export var damage: int = 15
@export var max_hp: int = 80

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down" 

# --- [추가됨] 길찾기 관련 노드 참조 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer  

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))
	
	# --- [추가됨] 길찾기 초기화 ---
	# 맵이 준비될 때까지 기다렸다가 네비게이션 설정
	call_deferred("navi_setup")

	anim.play("walk_down")

# --- [추가됨] 네비게이션 설정 함수 ---
func navi_setup():
	await get_tree().physics_frame
	
	timer.timeout.connect(_update_navigation_target)
	timer.start(0.2) 

func _update_navigation_target():
	if player:
		nav_agent.target_position = player.global_position


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

# 이동 / 추격
func _physics_process(delta):
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# 공격 범위 안이면 공격
	if distance <= attack_distance:
		_do_attack()
		return
	
	# 아니면 추격 (네비게이션 사용)
	_chase_player(delta)

func _chase_player(delta):

	if nav_agent.is_navigation_finished():
		return

	# 다음으로 이동해야 할 좌표 가져오기
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	_update_direction(direction)

	velocity = direction * speed
	move_and_slide()

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)

# 공격
func _do_attack():
	velocity = Vector2.ZERO # 공격 중에는 멈춤

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
	
	# 타이머 정지 (죽으면 길찾기 그만)
	timer.stop() 

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)

	await anim.animation_finished
	queue_free()
