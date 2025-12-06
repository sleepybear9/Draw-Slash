extends CharacterBody2D

# [설정] 유저가 요청한 값 적용
@export var speed: float = 70
@export var attack_distance: float = 120   # 원거리니까 사거리를 좀 늘렸습니다 (80 -> 120)
@export var attack_cooldown: float = 1.4
@export var damage: int = 15
@export var max_hp: int = 40
# [중요] 투사체가 발사되는 타이밍 (애니메이션 모션에 맞춰 조절하세요)
@export var shoot_delay: float = 0.4 

# [추가] 발사할 투사체 씬 (인스펙터에서 넣으세요)
@export var projectile_scene: PackedScene 

var hp: int
var player: Node2D
var current_dir: String = "down"

# [상태 변수]
var can_attack = true
var is_dead = false # 죽음 확인용

# --- 노드 연결 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	hp = max_hp
	
	# 안전하게 플레이어 찾기
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
	# 죽었거나 플레이어가 없으면 작동 중지
	if is_dead or not player:
		return

	var dist = global_position.distance_to(player.global_position)

	# 공격 사거리 안에 들어왔다면?
	if dist <= attack_distance:
		# 멈춰서 공격 시도 (움직임 멈춤)
		velocity = Vector2.ZERO
		_try_shoot()
	else:
		# 사거리 밖이면 추격
		_chase(delta)

func _chase(delta):
	# 공격 중(쿨타임 도는 중 포함)에는 이동 금지
	# (원거리 몹은 쏘고 나서 쿨타임 동안 도망가게 할 수도 있지만, 일단은 제자리 대기 로직)
	if not can_attack: 
		return

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

# --- [핵심] 원거리 공격 함수 ---
func _try_shoot():
	if not can_attack or is_dead:
		return
		
	can_attack = false
	velocity = Vector2.ZERO # 확실하게 정지
	
	# 1. 플레이어 방향 바라보기
	var direction = global_position.direction_to(player.global_position)
	_update_direction(direction)
	
	# 2. 공격 애니메이션 시작
	var attack_anim = "attack_" + current_dir
	if anim.sprite_frames.has_animation(attack_anim):
		anim.play(attack_anim)
	
	# 3. [수정] 모션에 맞춰 발사 딜레이 (바로 쏘면 어색함)
	await get_tree().create_timer(shoot_delay).timeout
	
	# [중요] 딜레이 사이에 죽었으면 발사 취소
	if is_dead: return
	
	# 4. 투사체 발사
	_spawn_projectile(direction) 
	
	# 5. 애니메이션 종료 대기
	await anim.animation_finished
	
	if is_dead: return # 또 확인

	# 6. 아이들 상태로 복귀
	anim.play("idle_" + current_dir)

	# 7. 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

# 투사체 생성 로직
func _spawn_projectile(direction: Vector2):
	if not projectile_scene:
		print("오류: 인스펙터에 Projectile Scene이 비어있습니다!")
		return

	var bullet = projectile_scene.instantiate()
	bullet.global_position = global_position
	
	# 투사체 스크립트에 setup 함수가 있어야 합니다!
	if bullet.has_method("setup"):
		bullet.setup(direction, damage)
	
	# 맵(Scene)에 추가
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int):
	if is_dead: return

	hp -= amount
	# 피격 효과
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	print("원거리 몬스터 HP:", hp)
	if hp <= 0:
		_die()

func _die():
	is_dead = true
	velocity = Vector2.ZERO
	
	# 물리 처리 및 타이머 정지
	set_physics_process(false)
	if timer: timer.stop()
	
	# 충돌 끄기
	$CollisionShape2D.set_deferred("disabled", true)

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	
	if anim.sprite_frames.has_animation(death_anim):
		anim.play(death_anim)
		await anim.animation_finished
	
	queue_free()
