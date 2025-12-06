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

# [수정] 공격 중인지 확인하는 상태 변수 추가
var is_attacking = false

# --- 길찾기 관련 노드 참조 ---
# [중요] 씬 트리에 NavigationAgent2D와 Timer 노드가 있어야 합니다.
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer  

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))
	
	# 맵 로딩 대기 후 네비게이션 설정
	call_deferred("navi_setup")

	anim.play("walk_down")

func navi_setup():
	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2) # 0.2초마다 경로 갱신

func _update_navigation_target():
	if player:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	if not player or hp <= 0:
		return
	
	# [수정] 공격 중이라면 이동 로직을 수행하지 않고 함수 종료
	if is_attacking:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# 공격 범위 안이면 공격
	if distance <= attack_distance:
		_do_attack()
		return
	
	# 아니면 추격
	_chase_player(delta)

func _chase_player(delta):
	if nav_agent.is_navigation_finished():
		return

	# 다음 이동 좌표 가져오기
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	_update_direction(direction)

	velocity = direction * speed
	move_and_slide()

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)

func _do_attack():
	# 쿨타임 중이라면 공격하지 않음
	if not can_attack:
		return

	# [수정] 공격 시작 처리
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO # 즉시 정지
	
	_perform_attack()

func _perform_attack():
	var base = "attack_" + current_dir + "_"

	# 공격 1
	anim.play(base + "1")
	await anim.animation_finished
	
	# 공격 2
	anim.play(base + "2")
	await anim.animation_finished

	# 데미지 판정
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("데미지:", damage)

	# [수정] 공격 애니메이션이 다 끝난 후 공격 상태 해제
	is_attacking = false 

	# 쿨타임 대기 (쿨타임은 공격 종료 후부터 돕니다)
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# ... (나머지 함수들은 동일) ...

func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false

func _update_direction(vec: Vector2):
	# 공격 중일 때는 방향 전환 하지 않도록 막을 수도 있습니다 (선택사항)
	if is_attacking: return

	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"

func take_damage(amount: int):
	hp -= amount
	print("몬스터 HP:", hp)
	if hp <= 0:
		_die()

func _die():
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	
	# 죽으면 타이머 정지
	if timer: timer.stop() 
	
	# [수정] 죽는 애니메이션 재생을 위해 공격 상태 강제 해제 (혹시 공격중에 죽을 수 있으니)
	is_attacking = true # 움직이지 못하게 잠금

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)

	await anim.animation_finished
	queue_free()
