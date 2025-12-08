extends CharacterBody2D

# [설정]
@export var speed: float = 70
@export var attack_distance: float = 120   # 원거리
@export var attack_cooldown: float = 1.4
@export var damage: int = 15
@export var max_hp: int = 40
@export var shoot_delay: float = 0.4 

@export var projectile_range: PackedScene 

var hp: int
var player: Node2D
var current_dir: String = "down"

# [상태 변수]
var can_attack = true
var is_dead = false 
var is_attacking = false # [추가] 쿨타임과 실제 공격 행동을 분리하기 위함

# --- 노드 연결 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	hp = max_hp
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)
	
	call_deferred("navi_setup")
	anim.play("idle_down")

func navi_setup():
	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2)

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _update_direction(vec: Vector2):
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"

func _physics_process(delta):
	if is_dead or not player: return
	
	# [수정] 공격 동작 중이면 아무것도 안 함 (이동X)
	if is_attacking: return

	var dist = global_position.distance_to(player.global_position)

	if dist <= attack_distance:
		velocity = Vector2.ZERO
		# 공격 가능할 때만 시도
		if can_attack:
			_try_shoot()
		else:
			# 사거리 안인데 쿨타임 중이면? 
			# 선택 1: 가만히 서서 노려봄 (현재 적용: idle 재생)
			# 선택 2: 도망감 (AI 추가 필요)
			_play_idle_anim() 
	else:
		_chase(delta)

func _chase(_delta):
	# [수정] 여기 있던 'if not can_attack: return' 삭제함
	# 쿨타임 중이라도 플레이어가 멀어지면 쫓아가야 함

	if nav_agent.is_navigation_finished():
		_play_idle_anim()
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	_update_direction(direction)
	velocity = direction * speed
	move_and_slide()

	# 걷기 애니메이션
	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)

# 아이들 애니메이션 헬퍼 함수
func _play_idle_anim():
	var idle_name = "idle_" + current_dir
	if anim.sprite_frames.has_animation(idle_name):
		anim.play(idle_name)

# --- [핵심] 원거리 공격 함수 ---
func _try_shoot():
	if not can_attack or is_dead: return
		
	can_attack = false
	is_attacking = true # [수정] 공격 행동 시작 알림
	velocity = Vector2.ZERO
	
	# 1. 플레이어 방향 바라보기
	var direction = global_position.direction_to(player.global_position)
	_update_direction(direction)
	
	# 2. 공격 애니메이션
	var attack_anim = "attack_" + current_dir
	if anim.sprite_frames.has_animation(attack_anim):
		anim.play(attack_anim)
	
	# 3. 발사 딜레이
	await get_tree().create_timer(shoot_delay).timeout
	
	if is_dead: return
	
	# 4. 투사체 발사
	_spawn_projectile(direction) 
	
	# 5. 애니메이션 종료 대기
	await anim.animation_finished
	
	is_attacking = false # [수정] 공격 행동 종료 (이제 다시 움직일 수 있음)
	
	if is_dead: return

	# 6. 아이들 상태로 복귀
	_play_idle_anim()

	# 7. 쿨타임 대기 (행동 종료 후 쿨타임 시작)
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func _spawn_projectile(direction: Vector2):
	if not projectile_range:
		print("오류: 인스펙터에 Projectile Scene이 비어있습니다!")
		return

	var bullet = projectile_range.instantiate()
	bullet.global_position = global_position
	
	if bullet.has_method("setup"):
		bullet.setup(direction, damage)
	
	# [수정] call_deferred로 안전하게 추가 (물리 연산 중 노드 조작 방지)
	get_tree().current_scene.call_deferred("add_child", bullet)

func take_damage(amount: int):
	if is_dead: return

	hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# print("원거리 몬스터 HP:", hp)
	if hp <= 0:
		_die()

func _die():
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	
	set_physics_process(false)
	if timer: timer.stop()
	$CollisionShape2D.set_deferred("disabled", true)

	# [수정] 4방향 죽음 모션 처리 (이미지가 없으면 down으로 통일하거나 수정 필요)
	var death_anim = "death_" + current_dir
	if not anim.sprite_frames.has_animation(death_anim):
		death_anim = "death_down" # 없으면 기본값

	if anim.sprite_frames.has_animation(death_anim):
		anim.play(death_anim)
		await anim.animation_finished
	
	queue_free()
