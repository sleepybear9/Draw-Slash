extends CharacterBody2D

@export var speed: float = 80
@export var attack_distance: float = 80
@export var dash_speed: float = 300
@export var dash_duration: float = 0.3
@export var attack_cooldown: float = 2.0
@export var damage: int = 15
@export var max_hp: int = 45

var hp: int
var player: Node2D
var can_attack = true
var is_attacking = false
var is_dashing = false
var is_dead = false
var player_in_attack_area = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange

# [오디오 노드 연결]
# 에디터의 씬 안에 이 이름의 노드가 있어야 합니다.
@onready var sfx_dash: AudioStreamPlayer = $scavenger_dash
@onready var sfx_death: AudioStreamPlayer = $sfx_monster_death

func _ready():
	hp = max_hp
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if not player:
		player = get_tree().root.find_child("Player", true, false)

	if player:
		print("추적 대상 발견: ", player.name)

	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)

	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2)

	_play_idle()

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	if is_dead or not player: return
	if is_dashing:
		move_and_slide()
		return
	if is_attacking:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= attack_distance:
		_start_dash_attack()
	else:
		_chase_player(delta)

# --- 이동 ---
func _chase_player(_delta):
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		_play_idle()
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)

	_update_sprite_direction(direction)
	velocity = direction * speed
	move_and_slide()

	if velocity.length() > 0:
		if anim.animation != "run":
			anim.play("run")
	else:
		_play_idle()

# --- Idle ---
func _play_idle():
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
	else:
		anim.play("run")
		anim.frame = 0
		anim.stop()

# --- [핵심] 공격 및 사운드 재생 ---
func _start_dash_attack():
	if not can_attack or is_dead:
		_play_idle()
		return

	can_attack = false
	is_attacking = true
	velocity = Vector2.ZERO

	var dir_to_player = global_position.direction_to(player.global_position)
	_update_sprite_direction(dir_to_player)

	# 1. 공격 애니메이션 시작
	anim.play("attack")
	
	# 2. [여기서 사운드 재생] 공격 시작하자마자 소리 남
	if sfx_dash:
		sfx_dash.play()

	# 0.2초 딜레이 (선딜)
	await get_tree().create_timer(0.2).timeout
	if is_dead: return

	# 대시 돌진
	is_dashing = true
	velocity = dir_to_player * dash_speed

	await get_tree().create_timer(dash_duration).timeout

	is_dashing = false
	velocity = Vector2.ZERO

	# 데미지 판정
	if player_in_attack_area and player.has_method("take_damage"):
		player.take_damage(damage)

	await anim.animation_finished

	is_attacking = false
	_play_idle()

	# 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func _update_sprite_direction(vec: Vector2):
	if is_attacking or is_dashing: return
	if vec.x != 0:
		anim.flip_h = vec.x < 0

func _on_attack_area_entered(body):
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player") or body.is_in_group("Player"):
		player_in_attack_area = false

# --- 사망 처리 ---
func take_damage(amount: int):
	if is_dead: return
	hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

	if hp <= 0: _die()

func _die():
	is_dead = true
	velocity = Vector2.ZERO
	is_attacking = false
	is_dashing = false
	can_attack = false
	
	set_physics_process(false)
	attack_area.monitoring = false
	timer.stop()
	$CollisionShape2D.set_deferred("disabled", true)

	anim.play("death")
	
	# 사망 사운드 재생
	if sfx_death:
		sfx_death.play()
		await sfx_death.finished
	else:
		await anim.animation_finished

	queue_free()
