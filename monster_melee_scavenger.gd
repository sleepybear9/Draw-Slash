extends CharacterBody2D

# [설정 변수]
@export var speed: float = 80
@export var attack_distance: float = 80 # 공격 사거리
@export var dash_speed: float = 300     # 대시 속도 (평소보다 빨라야 함)
@export var dash_duration: float = 0.3  # 대시 지속 시간 (짧고 굵게)
@export var attack_cooldown: float = 2.0
@export var damage: int = 15
@export var max_hp: int = 45

var hp: int
var player: Node2D
var current_dir: String = "down"

# [상태 변수]
var can_attack = true
var player_in_attack_area = false
var is_attacking = false # 공격 동작 중인지
var is_dashing = false   # 현재 대시 이동 중인지
var is_dead = false      # 사망 여부

# --- 노드 연결 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange

func _ready():
	hp = max_hp
	
	# 안전하게 플레이어 찾기
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)
		
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)
	
	call_deferred("navi_setup")
	anim.play("walk_down")

func navi_setup():
	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2)

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	# 죽었거나 플레이어가 없으면 작동 중지
	if is_dead or not player:
		return
	
	# [중요] 대시 중일 때는 기존 이동 로직 무시하고 대시 속도로 이동
	if is_dashing:
		move_and_slide() # velocity는 공격 함수에서 설정함
		return

	# [중요] 공격(대시 준비 등) 중이면 이동 멈춤
	if is_attacking:
		return

	var distance = global_position.distance_to(player.global_position)

	# 공격 사거리 안이면 대시 공격 시작
	if distance <= attack_distance:
		_start_dash_attack()
	else:
		_chase_player(delta)

func _chase_player(_delta):
	if nav_agent.is_navigation_finished():
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	_update_direction(direction)
	
	velocity = direction * speed
	move_and_slide()

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)

# --- [핵심] 대시 공격 로직 ---
func _start_dash_attack():
	if not can_attack or is_dead:
		return
	
	can_attack = false
	is_attacking = true
	velocity = Vector2.ZERO # 일단 정지 (준비 동작)
	
	# 1. 플레이어 방향 바라보기 (공격 전 마지막 조준)
	var dir_to_player = global_position.direction_to(player.global_position)
	_update_direction(dir_to_player)
	
	# 2. 공격 애니메이션 시작 (준비 동작)
	var attack_anim = "attack_" + current_dir
	if anim.sprite_frames.has_animation(attack_anim):
		anim.play(attack_anim)
	
	# (선택사항) 공격 전 살짝 뜸 들이기 (0.2초) - 텔레그래프
	await get_tree().create_timer(0.2).timeout
	if is_dead: return # 대기 중 죽으면 취소
	
	# 3. 대시 시작 (플레이어가 있던 방향으로 돌진)
	is_dashing = true
	# 현재 플레이어 방향으로 속도 설정
	var dash_dir = global_position.direction_to(player.global_position)
	velocity = dash_dir * dash_speed 
	
	# 4. 일정 시간 동안 돌진
	await get_tree().create_timer(dash_duration).timeout
	
	# 5. 대시 끝
	is_dashing = false
	velocity = Vector2.ZERO # 미끄러짐 방지
	
	# 6. 데미지 판정 (돌진 후 범위 안에 있으면 타격)
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("대시 공격 명중!")
	
	# 7. 애니메이션이 아직 안 끝났으면 기다림
	if anim.is_playing() and "attack" in anim.animation:
		await anim.animation_finished
		
	is_attacking = false
	
	# 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false

func _update_direction(vec: Vector2):
	# 공격(대시) 중에는 방향을 바꾸지 않음 (직진성 유지)
	if is_attacking or is_dead: return

	# [수정] 잘려있던 부분 복구
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"

func take_damage(amount: int):
	if is_dead: return

	hp -= amount
	# 피격 효과
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if hp <= 0:
		_die()

func _die():
	is_dead = true
	is_attacking = false
	is_dashing = false
	velocity = Vector2.ZERO
	
	set_physics_process(false)
	attack_area.monitoring = false
	if timer: timer.stop()
	
	var death_anim = "death_" + current_dir
	if anim.sprite_frames.has_animation(death_anim):
		anim.play(death_anim)
		await anim.animation_finished
	
	queue_free()
