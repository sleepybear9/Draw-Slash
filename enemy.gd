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

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer

# [추가됨] 길 찾기를 위한 노드 연결
# 씬 트리에 'NavigationAgent2D' 노드를 꼭 추가해주세요!
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))

	anim.play("walk_down")
	
	# [추가됨] 맵이 처음 로드될 때 내비게이션 서버 동기화를 위해 잠시 대기
	# 이게 없으면 게임 시작 직후 "Actor not synced" 에러가 뜰 수 있습니다.
	await get_tree().physics_frame

func _physics_process(delta):
	if not player:
		return
	
	# 플레이어와 몬스터 사이의 직선 거리 (공격 사거리는 직선으로 체크하는 것이 자연스럽습니다)
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_distance:
		_do_attack()
		return
	
	# [추가됨] 길 찾기 목표 지점을 플레이어 위치로 계속 업데이트
	nav_agent.target_position = player.global_position
	
	_chase_player(delta)

func _chase_player(delta):
	# [수정됨] 단순 직선 이동 대신 내비게이션 경로 사용
	
	# 목적지에 도착했는지 확인 (선택 사항)
	if nav_agent.is_navigation_finished():
		return

	# 다음으로 이동해야 할 경로상의 위치를 가져옴
	var next_path_position: Vector2 = nav_agent.get_next_path_position()
	
	# 현재 위치에서 다음 경로 위치로 향하는 방향 계산
	var direction: Vector2 = global_position.direction_to(next_path_position)
	
	_update_direction(direction)

	# 속도 적용
	velocity = direction * speed
	move_and_slide()

	if can_attack:
		var walk_name = "walk_" + current_dir
		if anim.animation != walk_name:
			anim.play(walk_name)

# --- 아래 함수들은 기존과 동일합니다 ---

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

func _do_attack():
	if can_attack:
		velocity = Vector2.ZERO
		can_attack = false
		_perform_attack()

func _perform_attack():
	var attack_anim_name = "attack_" + current_dir
	anim.play(attack_anim_name)
	_play_sfx(sfx_monster_attack_melee)

	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int):
	hp -= amount
	_play_sfx(sfx_hurt)
	print("몬스터 HP:", hp)

	if hp <= 0:
		_die()

func _die():
	velocity = Vector2.ZERO
	if attack_area:
		attack_area.monitoring = false
	
	_play_sfx(sfx_monster_death)

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)

	await anim.animation_finished
	queue_free()

func _play_sfx(stream: AudioStream):
	if stream and sfx_player:
		sfx_player.stream = stream
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()
