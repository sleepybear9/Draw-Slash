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

func _ready():
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")

	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)

	await get_tree().physics_frame
	timer.timeout.connect(_update_navigation_target)
	timer.start(0.2)

	_play_idle()

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	if is_dead or not player: 
		return
	
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


# --- 이동 처리 (좌/우만 표현) ---
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


# --- Idle 처리 ---
func _play_idle():
	# run 프레임 0에서 정지 (idle 대체)
	anim.play("run")
	anim.frame = 0
	anim.stop()


# --- 대시 공격 ---
func _start_dash_attack():
	if not can_attack or is_dead:
		_play_idle()
		return

	can_attack = false
	is_attacking = true
	velocity = Vector2.ZERO

	var dir_to_player = global_position.direction_to(player.global_position)
	_update_sprite_direction(dir_to_player)

	anim.play("attack")

	await get_tree().create_timer(0.2).timeout
	if is_dead: return

	is_dashing = true
	velocity = dir_to_player * dash_speed

	await get_tree().create_timer(dash_duration).timeout

	is_dashing = false
	velocity = Vector2.ZERO

	if player_in_attack_area and player.has_method("take_damage"):
		player.take_damage(damage)

	await anim.animation_finished

	is_attacking = false
	_play_idle()

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true


# --- 방향 처리(좌우만) ---
func _update_sprite_direction(vec: Vector2):
	if is_attacking or is_dashing: return

	if vec.x != 0:
		anim.flip_h = vec.x < 0


func _on_attack_area_entered(body):
	if body.is_in_group("player"): 
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"): 
		player_in_attack_area = false


# --- 피격 / 죽음 ---
func take_damage(amount: int):
	if is_dead: return

	hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

	if hp <= 0:
		_die()

func _die():
	is_dead = true
	velocity = Vector2.ZERO
	is_attacking = false
	is_dashing = false
	can_attack = false

	set_physics_process(false)
	attack_area.monitoring = false
	timer.stop()
	$CollisionShape2D.disabled = true

	anim.play("death")
	await anim.animation_finished

	queue_free()
