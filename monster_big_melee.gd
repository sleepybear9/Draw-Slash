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

# [상태 변수]
var is_attacking = false
var is_dead = false # 죽었는지 확실히 체크하는 변수 추가

# --- 노드 연결 ---
# [필수] 씬 트리에 NavigationAgent2D와 Timer 노드를 추가해주세요!
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
	
	# 네비게이션 초기화
	call_deferred("navi_setup")

	anim.play("walk_down")

func navi_setup():
	# 첫 물리 프레임 대기 (맵 로딩 동기화)
	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2) # 0.2초마다 경로 갱신

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	# 죽었거나, 플레이어가 없거나, 공격 중이면 이동 안 함
	if is_dead or not player or is_attacking:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# 공격 범위 안이면 공격
	if distance <= attack_distance:
		_do_attack()
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

func _do_attack():
	if not can_attack or is_dead:
		return

	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO # 미끄러짐 방지
	
	_perform_attack()

func _perform_attack():
	# [중요] 애니메이션 이름 규칙 확인 필수!
	# 예: attack_down_1, attack_down_2 가 있어야 합니다.
	var base = "attack_" + current_dir + "_"

	# --- 공격 1타 ---
	if anim.sprite_frames.has_animation(base + "1"):
		anim.play(base + "1")
		await anim.animation_finished
	
	# [버그 수정] 1타 끝난 사이에 죽었으면 여기서 멈춰야 함!
	if is_dead: return 
	
	# --- 공격 2타 ---
	if anim.sprite_frames.has_animation(base + "2"):
		anim.play(base + "2")
		await anim.animation_finished

	# [버그 수정] 2타 끝난 사이에 죽었으면 데미지 주지 말고 종료
	if is_dead: return

	# --- 데미지 판정 ---
	# (현재 로직은 2타까지 다 때려야 데미지가 들어감. 1타 때 주고 싶으면 위로 올리세요)
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("데미지 적용:", damage)

	is_attacking = false 

	# 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	
	# 죽지 않았을 때만 다시 공격 가능
	if not is_dead:
		can_attack = true

func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false

func _update_direction(vec: Vector2):
	if is_attacking or is_dead: return

	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"

func take_damage(amount: int):
	if is_dead: return # 죽은 상태에선 데미지 무시

	hp -= amount
	print("몬스터 HP:", hp)
	
	# 피격 효과 (빨간색 깜빡임)
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if hp <= 0:
		_die()

func _die():
	is_dead = true   # 모든 로직 차단
	is_attacking = false # 공격 상태 강제 해제 (사망 모션 재생을 위해)
	
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	
	# 물리 처리 정지 (중요: 시체가 밀리거나 연산하지 않게 함)
	set_physics_process(false)
	
	if timer: timer.stop() 

	# 사망 애니메이션
	var death_anim = "death_down" if current_dir == "down" else "death_up"
	
	# 애니메이션이 있으면 재생
	if anim.sprite_frames.has_animation(death_anim):
		anim.play(death_anim)
		await anim.animation_finished
	
	queue_free()
