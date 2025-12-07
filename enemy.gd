extends CharacterBody2D

@export var speed: float = 70
@export var attack_distance: float = 80
@export var attack_cooldown: float = 1.0
@export var damage: int = 15
@export var max_hp: int = 40

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

# [상태 변수]
var is_dead = false
var is_attacking = false 

# --- 노드 연결 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
@onready var timer: Timer = $Timer # 타이머 노드가 없다면 지우거나 추가하세요

func _ready():
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)
	
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)
	
	# 길찾기 초기화
	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2)

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	# 죽었거나 공격 중이면 이동 금지
	if is_dead or not player: return
	if is_attacking: return 
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= attack_distance:
		velocity = Vector2.ZERO # 공격 사거리 안이면 멈춤
		_do_attack()
	else:
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
	velocity = direction * speed
	move_and_slide()

	# [핵심 수정] 움직일 때는 걷기, 멈췄을 때는 아이들 모션 재생
	if velocity.length() > 0:
		var walk_name = "walk_" + current_dir
		if anim.animation != walk_name:
			anim.play(walk_name)
	else:
		_play_idle_anim()

# 아이들 모션 재생 함수
func _play_idle_anim():
	var idle_name = "idle_" + current_dir
	# idle 애니메이션이 있으면 재생, 없으면 walk의 0번 프레임으로 멈춤
	if anim.sprite_frames.has_animation(idle_name):
		anim.play(idle_name)
	else:
		anim.stop() # 애니메이션이 없으면 그냥 멈춤

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
		await anim.animation_finished
	queue_free()
