extends CharacterBody2D

var speed: float = 70
var attack_distance: float = 100
var attack_cooldown: float = 1.0
var damage: int = 15
var hp: int = 40
var hitbox_offset: float = 30.0

@onready var player = $"../Player"
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

var is_dead = false
var is_attacking = false 

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
@onready var timer: Timer = $Timer
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func setup(id: int):
	pass

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	if is_dead or not player: return
	var dist = global_position.distance_to(player.global_position)
	
	_chase_player(delta)
	

func _chase_player(_delta):
	if nav_agent.is_navigation_finished():
		# 목적지 도착했으면 멈추고 아이들 모션
		velocity = Vector2.ZERO
		_play_idle_anim()
		return

	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	_update_direction(direction)
	var wanted_velocity = direction * speed
	nav_agent.velocity = wanted_velocity

	# 움직일 때는 걷기, 멈췄을 때는 아이들 모션 재생
	if velocity.length() > 0:
		var walk_name = "walk_" + current_dir
		if anim.animation != walk_name:
			anim.play(walk_name)
	else:
		_play_idle_anim()

# 아이들 모션 재생 함수
func _play_idle_anim():
	var idle_name = "idle_" + current_dir
	if anim.sprite_frames.has_animation(idle_name):
		anim.play(idle_name)
	else:
		anim.stop()

func _do_attack():
	if can_attack:
		velocity = Vector2.ZERO
		can_attack = false
		is_attacking = true
		_perform_attack()
	else:
		# 쿨타임 중일 때는 아이들 모션으로 대기
		_play_idle_anim()

func _perform_attack():
	# [추가됨] 공격 사운드 재생

	# 낫 몬스터용 근접 공격
	var base = "attack_" + current_dir + "_"

	# 1타
	if anim.sprite_frames.has_animation(base + "1"):
		anim.play(base + "1")
		await anim.animation_finished 
	
	if is_dead: return 
	
	# 2타
	if anim.sprite_frames.has_animation(base + "2"):
		anim.play(base + "2")
		await anim.animation_finished 

	if is_dead: return

	# 데미지 판정
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
	
	is_attacking = false 
	
	await get_tree().create_timer(attack_cooldown).timeout
	if not is_dead:
		can_attack = true

func _on_attack_area_entered(body):
	if body.is_in_group("player"): player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"): player_in_attack_area = false

func _update_direction(vec: Vector2):
	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec.y > 0 else "up"
		
	if attack_area:
		match current_dir:
			"right":
				attack_area.position = Vector2(hitbox_offset, 0)
				attack_area.rotation_degrees = 0
			"left":
				attack_area.position = Vector2(-hitbox_offset, 0)
				attack_area.rotation_degrees = 180
			"down":
				attack_area.position = Vector2(0, hitbox_offset)
				attack_area.rotation_degrees = 90
			"up":
				attack_area.position = Vector2(0, -hitbox_offset)
				attack_area.rotation_degrees = 270

func take_damage(amount: int):
	if is_dead: return
	hp -= amount
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	if hp <= 0: _die()

func _die():
	is_dead = true
	is_attacking = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	var death_anim = "death_" + current_dir
	if anim.sprite_frames.has_animation(death_anim):
		anim.play(death_anim)

	# [추가됨] 사망 사운드 재생
		# 소리가 애니메이션보다 길 경우 끊기는 것을 방지하려면 아래 주석 해제
		# await sfx_death.finished 
	
	await anim.animation_finished
	queue_free()

func _velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()
