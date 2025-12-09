extends CharacterBody2D

# [설정 변수]
@export var max_hp: int = 5000
@export var pattern_cooldown: float = 3.0
@export var damage: int = 20 # 보스 공격력

# [필요한 씬들 연결]
@export var projectile_boss: PackedScene 
@export_group("Summon Pattern")
@export var enemy: PackedScene          
@export var monster_range: PackedScene  

# [노드 연결]
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var safe_zone_indicator: Node2D = $SafeZonePos 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var red_screen: ColorRect = $CanvasLayer/redscreen 

# [추가] 공격 판정 노드 (이름 꼭 확인하세요!)
@onready var hit_area: Area2D = $Area2D 
@onready var hit_shape: CollisionShape2D = $Area2D/CollisionShape2D

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

	# [추가] 시그널 연결 (공격 판정에 닿으면 실행)
	if hit_area:
		if not hit_area.body_entered.is_connected(_on_hitbox_entered):
			hit_area.body_entered.connect(_on_hitbox_entered)
		# 시작할 때 히트박스 끄기
		hit_shape.disabled = true

	print("보스 등장. 3초 후 패턴 시작.")
	await get_tree().create_timer(3.0).timeout
	start_pattern_loop()
	

func _physics_process(_delta):
	# [핵심] 매 프레임마다 히트박스 위치 업데이트
	_update_hitbox_position()

# --- [핵심 기능] 프레임에 따라 히트박스 이동 ---
func _update_hitbox_position():
	# 만약 지금 'normalattack_2' 애니메이션이 재생 중이라면?
	if anim.animation == "normalattack_2" and anim.is_playing():
		hit_shape.disabled = false # 공격 중이니 히트박스 켜기
		
		# 현재 몇 번째 프레임인지 확인 (0부터 시작)
		var current_frame = anim.frame
		
		# === [여기 숫자를 에디터 보면서 수정하세요] ===
		# 낫의 위치에 맞춰 좌표(Vector2)를 적어줍니다.
		match current_frame:
			0: hit_area.position = Vector2(20, -50)  # 낫을 들어올릴 때
			1: hit_area.position = Vector2(50, -40)  # 휘두르기 시작
			2: hit_area.position = Vector2(80, 0)    # 정면 타격
			3: hit_area.position = Vector2(50, 40)   # 아래로 내려감
			4: hit_area.position = Vector2(20, 50)   # 마무리
			_: pass # 나머지 프레임은 유지
			
	else:
		# 공격 모션이 아니면 히트박스 끄기
		hit_shape.disabled = true


# --- 히트박스 충돌 처리 ---
func _on_hitbox_entered(body: Node2D):
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("플레이어 타격 성공!")


# --- [메인 패턴 로직] ---
func start_pattern_loop():
	while hp > 0 and not is_dead:
		if not is_doing_pattern:
			await choose_random_pattern()
			
			if not is_dead:
				# 패턴 끝나면 Idle 재생
				if anim.sprite_frames.has_animation("idle"):
					anim.play("idle")
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

# --- [패턴 1] 소환 ---
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

# --- [패턴 2] 공격 ---
func _pattern_fire_projectile():
	if anim.sprite_frames.has_animation("normalattack_2"):
		anim.play("normalattack_2")
		# 여기서는 딜레이를 주지 않고 애니메이션 끝날 때까지 기다립니다.
		# (히트박스는 _physics_process에서 자동으로 처리됨)
		await anim.animation_finished
	
	# 투사체
	if player and projectile_boss:
		var projectile = projectile_boss.instantiate()
		projectile.global_position = global_position
		var dir = (player.global_position - global_position).normalized()
		
		if "direction" in projectile: projectile.direction = dir 
		elif projectile.has_method("setup"): projectile.setup(dir, damage)
		
		projectile.rotation = dir.angle()
		get_parent().add_child(projectile)

# --- [패턴 3] 전멸기 ---
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
	
	# 히트박스 끄기
	hit_shape.set_deferred("disabled", true)
	
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()
