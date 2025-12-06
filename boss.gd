extends CharacterBody2D

# [설정 변수]
@export var max_hp: int = 5000
@export var pattern_cooldown: float = 3.0

# [필요한 씬들 연결]
@export var projectile_scene: PackedScene 
@export_group("Summon Pattern")
@export var enemy: PackedScene          
@export var monster_range: PackedScene  

# [노드 연결]
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var safe_zone_indicator: Node2D = $SafeZonePos 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
# 붉은 화면 노드 (경로가 맞는지 꼭 확인하세요! CanvasLayer 밑에 RedScreen이 있어야 함)
@onready var red_screen: ColorRect = $CanvasLayer/redscreen 

# [상태 변수]
var hp: int
var player: Node2D
var is_invincible: bool = false 
var active_minions: int = 0      
var is_doing_pattern: bool = false
var is_dead: bool = false

func _ready():
	hp = max_hp
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)
	
	if safe_zone_indicator: safe_zone_indicator.visible = false
	if red_screen: red_screen.visible = false

	print("보스 등장. 3초 후 패턴 시작.")
	await get_tree().create_timer(3.0).timeout
	start_pattern_loop()

func _physics_process(_delta):
	pass

# --- [메인 패턴 로직] ---
func start_pattern_loop():
	# 죽지 않았고 HP가 남았을 때 계속 반복
	while hp > 0 and not is_dead:
		if not is_doing_pattern:
			await choose_random_pattern()
			
			if not is_dead:
				await get_tree().create_timer(pattern_cooldown).timeout
		else:
			await get_tree().process_frame

func choose_random_pattern():
	if is_doing_pattern or is_dead: return
	
	is_doing_pattern = true
	var random_pick = randi() % 3 + 1 
	print("선택된 패턴: ", random_pick)
	
	match random_pick:
		1: await _pattern_summon()
		2: await _pattern_fire_projectile()
		3: await _pattern_ultimate()
	
	is_doing_pattern = false 

# --- [패턴 1] ---
func _pattern_summon():
	if anim.sprite_frames.has_animation("summon"):
		anim.play("summon")
		await anim.animation_finished 
	
	is_invincible = true
	modulate = Color(0.5, 0.5, 1, 0.8) 
	
	var total_spawn_count = 5
	for i in range(total_spawn_count):
		var spawn_scene: PackedScene
		if randi() % 2 == 0: spawn_scene = enemy 
		else: spawn_scene = monster_range 
			
		if spawn_scene:
			var minion = spawn_scene.instantiate()
			var random_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
			minion.global_position = global_position + random_offset
			get_parent().add_child(minion)
			minion.tree_exited.connect(_on_minion_died)
			active_minions += 1

func _on_minion_died():
	active_minions -= 1
	if active_minions <= 0: _break_invincibility()

func _break_invincibility():
	if is_invincible:
		is_invincible = false
		modulate = Color(1, 1, 1, 1)
		take_damage(1000)

# --- [패턴 2] ---
func _pattern_fire_projectile():
	if anim.sprite_frames.has_animation("normalattack_2"):
		anim.play("normalattack_2")
		await get_tree().create_timer(0.3).timeout
	
	if player and projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		var dir = (player.global_position - global_position).normalized()
		
		# 투사체 스크립트에 direction이 있는지 확인!
		if "direction" in projectile: projectile.direction = dir 
		# 혹은 setup 함수가 있다면: projectile.setup(dir, 10)
		
		projectile.rotation = dir.angle()
		get_parent().add_child(projectile)
	
	if anim.sprite_frames.has_animation("normalattack_2"):
		await anim.animation_finished

# --- [패턴 3] ---
func _pattern_ultimate():
	is_invincible = true 
	if anim.sprite_frames.has_animation("skill"):
		anim.play("skill")
		await anim.animation_finished
	
	visible = false 
	collision_shape.set_deferred("disabled", true) 
	print("!!! 전멸기 준비 !!!")
	
	if red_screen: red_screen.visible = true
	if safe_zone_indicator:
		safe_zone_indicator.visible = true
		safe_zone_indicator.position = Vector2(randf_range(-200, 200), randf_range(-200, 200))

	await get_tree().create_timer(5.0).timeout
	
	if player and safe_zone_indicator:
		var dist = player.global_position.distance_to(safe_zone_indicator.global_position)
		if dist > 150: 
			if player.has_method("take_damage"): player.take_damage(9999) 
	
	if safe_zone_indicator: safe_zone_indicator.visible = false
	if red_screen: red_screen.visible = false 

	visible = true
	collision_shape.set_deferred("disabled", false)
	is_invincible = false
	
	if anim.sprite_frames.has_animation("return"):
		anim.play("return")
		await anim.animation_finished
	elif anim.sprite_frames.has_animation("skill"):
		anim.play("skill") 
		await anim.animation_finished

# --- [피격] ---
func take_damage(amount):
	if is_invincible or is_dead: return
	hp -= amount
	print("보스 HP: ", hp)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0: die()

func die():
	is_dead = true
	is_doing_pattern = false
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()
