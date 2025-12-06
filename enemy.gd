extends CharacterBody2D

@export var speed: float = 70
@export var attack_distance: float = 50
@export var attack_cooldown: float = 1.0
@export var damage: int = 10
@export var max_hp: int = 30

# [효과음 관련 변수]
@export_group("Sound Effects")
@export var sfx_monster_attack_melee: AudioStream
@export var sfx_hit_player: AudioStream
@export var sfx_hurt: AudioStream
@export var sfx_monster_death: AudioStream

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"
var is_dead: bool = false # [추가] 죽었는지 확인하는 변수

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	hp = max_hp
	
	# [수정] 플레이어 찾기 안전장치 (그룹 사용 권장)
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)
	
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)

	anim.play("walk_down")
	
	# 내비게이션 서버 동기화 대기
	nav_agent.path_desired_distance = 4.0 # [추가] 목표 도달 허용 오차 (너무 작으면 제자리에서 떪)
	nav_agent.target_desired_distance = 4.0
	await get_tree().physics_frame

func _physics_process(delta):
	# [수정] 죽었거나, 플레이어가 없거나, 공격 중(쿨타임 도는 중)이면 이동 금지
	if is_dead or not player:
		return
		
	# 공격 동작 중에는 움직이지 않도록 처리 (애니메이션 꼬임 방지)
	if not can_attack:
		return 
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_distance:
		_do_attack()
	else:
		# 공격 범위 밖이면 추적
		# [수정] 매 프레임 경로 갱신은 부하가 클 수 있으므로 타이머를 쓰기도 하지만, 
		# 지금처럼 간단한 AI에서는 매 프레임 갱신도 괜찮습니다.
		nav_agent.target_position = player.global_position
		_chase_player(delta)

func _chase_player(_delta):
	if nav_agent.is_navigation_finished():
		return

	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_position)
	
	_update_direction(direction)

	velocity = direction * speed
	move_and_slide()

	# [수정] 이동 중일 때만 걷는 애니메이션 재생
	if velocity.length() > 0:
		var walk_name = "walk_" + current_dir
		if anim.animation != walk_name:
			anim.play(walk_name)

func _on_attack_area_entered(body):
	if body.is_in_group("player"): # 그룹 이름 소문자 'player' 확인 필요
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false

func _update_direction(vec: Vector2):
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"

func _do_attack():
	if can_attack:
		velocity = Vector2.ZERO # [중요] 공격 시작 시 미끄러짐 방지
		can_attack = false
		_perform_attack()

func _perform_attack():
	var attack_anim_name = "attack_" + current_dir
	anim.play(attack_anim_name)
	_play_sfx(sfx_monster_attack_melee)
	
	# [선택 사항] 애니메이션과 데미지 타이밍 맞추기
	# 바로 때리는 게 아니라, 애니메이션이 끝날 때쯤 때리고 싶다면 await anim.animation_finished 사용
	# 여기서는 기존 로직대로 즉시 데미지
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
	
	# 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	
	# [중요] 죽지 않았을 때만 다시 공격 가능 상태로 변경
	if not is_dead:
		can_attack = true

func take_damage(amount: int):
	# 죽은 상태에선 데미지 무시
	if is_dead: return
	
	hp -= amount
	_play_sfx(sfx_hurt)
	
	# 피격 효과 (깜빡임) - 선택사항
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	print("몬스터 HP:", hp)

	if hp <= 0:
		_die()

func _die():
	is_dead = true # 사망 상태 확정
	velocity = Vector2.ZERO
	
	# [중요] 더 이상 물리 연산이나 길찾기를 하지 않도록 설정
	set_physics_process(false) 
	nav_agent.set_velocity_forced(Vector2.ZERO) # 내비게이션 정지
	
	if attack_area:
		attack_area.monitoring = false
	
	# 충돌 끄기 (시체가 길막하는 것 방지)
	$CollisionShape2D.set_deferred("disabled", true)
	
	_play_sfx(sfx_monster_death)

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	
	# 사망 애니메이션이 있으면 재생, 없으면 바로 삭제
	if anim.sprite_frames.has_animation(death_anim):
		anim.play(death_anim)
		await anim.animation_finished
	
	queue_free()

func _play_sfx(stream: AudioStream):
	if stream and sfx_player:
		sfx_player.stream = stream
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()
