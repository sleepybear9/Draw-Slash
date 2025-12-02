extends CharacterBody2D

@export var speed: float = 80
@export var attack_distance: float = 80
@export var dash_distance: float = 100
@export var dash_speed: float = 220
@export var attack_cooldown: float = 2.0
@export var damage: int = 15
@export var max_hp: int = 45

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

# --- [추가] 길찾기 필수 노드 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))
	
	# --- [추가] 길찾기 설정 시작 ---
	call_deferred("navi_setup")
	
	anim.play("run")

# --- [추가] 네비게이션 초기화 ---
func navi_setup():
	await get_tree().physics_frame
	timer.timeout.connect(_update_navigation_target)
	timer.start(0.2) # 0.2초마다 경로 갱신

# --- [추가] 플레이어 위치 추적 ---
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

func _physics_process(delta):
	# 공격 불가능하거나 플레이어 없으면 중단
	if not player or not can_attack:
		return

	var dist = global_position.distance_to(player.global_position)
	
	# 공격 사거리 내라면 대시 공격 실행
	if dist <= attack_distance:
		_do_dash_attack()
		return

	# 아니면 길찾기 추격
	_chase(delta)

# --- [수정] 길찾기 로직 적용된 추격 함수 ---
func _chase(delta):
	if nav_agent.is_navigation_finished():
		return

	# 다음 이동 지점을 네비게이션에서 받아옴
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	_update_direction(direction)
	velocity = direction * speed
	move_and_slide()

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)

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
	
	# 대시 중에는 물리적으로 벽에 막힐 수 있으므로 move_and_slide 사용 유지
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

func take_damage(amount: int):
	hp -= amount
	print("암살자 HP:", hp)
	if hp <= 0:
		_die()

func _die():
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	timer.stop() # [추가] 죽으면 길찾기 연산 중지
	
	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)
	await anim.animation_finished
	queue_free()
