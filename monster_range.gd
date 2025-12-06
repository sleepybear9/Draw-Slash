extends CharacterBody2D

# --- [설정] 유저가 요청한 값 적용 ---
@export var speed: float = 70
@export var attack_distance: float = 80   # 이 거리 안에 들어오면 멈추고 쏨
@export var attack_cooldown: float = 1.4
@export var damage: int = 15
@export var max_hp: int = 40

# --- [추가] 발사할 투사체 씬 (인스펙터에서 넣으세요) ---
@export var projectile_scene: PackedScene 

var hp: int
var player: Node2D
var can_attack = true
var current_dir: String = "down"

# --- [필수] 길찾기 노드 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	
	# 길찾기 초기화
	call_deferred("navi_setup")
	anim.play("idle_down")

func navi_setup():
	await get_tree().physics_frame
	timer.timeout.connect(_update_navigation_target)
	timer.start(0.2)

func _update_navigation_target():
	if player:
		nav_agent.target_position = player.global_position

func _update_direction(vec: Vector2):
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"

func _physics_process(delta):
	if not player:
		return

	var dist = global_position.distance_to(player.global_position)

	# 공격 사거리 안에 들어왔다면?
	if dist <= attack_distance:
		# 멈춰서 공격 시도
		velocity = Vector2.ZERO
		_try_shoot()
	else:
		# 사거리 밖이면 추격
		_chase(delta)

func _chase(delta):
	# 공격 중(애니메이션 재생 중)이면 이동 금지
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
	if not can_attack:
		return
		
	can_attack = false
	
	# 플레이어 쪽을 바라보게 방향 갱신
	var direction = global_position.direction_to(player.global_position)
	_update_direction(direction)
	
	var attack_anim = "attack_" + current_dir
	anim.play(attack_anim)
	
	# 애니메이션의 특정 프레임(예: 손을 뻗었을 때)에 발사하고 싶다면 
	# await anim.frame_changed 등을 쓸 수 있지만, 여기선 간단히 즉시 발사 혹은 애니메이션 끝난 후 발사로 처리
	
	_spawn_projectile(direction) # 투사체 생성
	
	await anim.animation_finished
	anim.play("idle_" + current_dir)

	# 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# 투사체 생성 로직
func _spawn_projectile(direction: Vector2):
	if not projectile_scene:
		print("오류: 인스펙터에 Projectile Scene이 비어있습니다!")
		return

	# 투사체 인스턴스화
	var bullet = projectile_scene.instantiate()
	
	# 투사체 위치 설정 (몬스터 위치)
	bullet.global_position = global_position
	
	# 투사체에 방향과 데미지 전달 (투사체 스크립트에 해당 변수가 있어야 함)
	if bullet.has_method("setup"):
		bullet.setup(direction, damage)
	
	# 씬 트리에 추가 (몬스터 자식이 아니라 월드에 추가해야 같이 안 움직임)
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int):
	hp -= amount
	print("원거리 몬스터 HP:", hp)
	if hp <= 0:
		_die()

func _die():
	velocity = Vector2.ZERO
	timer.stop()
	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)
	await anim.animation_finished
	queue_free()
