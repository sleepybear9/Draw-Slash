extends CharacterBody2D

# [설정 변수]
@export var max_hp: int = 5000
# [수정] 패턴 종료 후 쿨타임을 10초로 변경
@export var pattern_cooldown: float = 10.0 
@export var damage: int = 20

# [필요한 씬들 연결]
@export var projectile_boss: PackedScene 
@export_group("Summon Pattern")
@export var enemy: PackedScene          
@export var monster_range: PackedScene  

# [노드 연결]
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var SafeZonePos: Node2D = $SafeZonePos 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var red_screen: ColorRect = $CanvasLayer/redscreen 

# [공격 판정 노드]
@onready var hit_area: Area2D = $Area2D 
@onready var hit_shape: CollisionShape2D = $Area2D/CollisionShape2D

# [상태 변수]
var hp: int
var player: Node2D
var is_invincible: bool = false 
var active_minions: int = 0       
var is_doing_pattern: bool = false
var is_dead: bool = false

# [추가] 첫 번째 패턴인지 확인하는 플래그
var is_first_pattern: bool = true

func _ready():
	hp = max_hp
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_root().find_child("Player", true, false)
	
	if SafeZonePos: SafeZonePos.visible = false
	if red_screen: red_screen.visible = false

	if hit_area:
		if not hit_area.body_entered.is_connected(_on_hitbox_entered):
			hit_area.body_entered.connect(_on_hitbox_entered)
		hit_shape.disabled = true

	# [수정] 시작하자마자 Idle 모션 재생
	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

	print("보스 등장. 5초 대기 중...")
	
	# [수정] 첫 패턴 시작 전 5초 대기
	await get_tree().create_timer(5.0).timeout
	
	# 죽지 않았으면 패턴 루프 시작
	if not is_dead:
		start_pattern_loop()
	

func _physics_process(_delta):
	if is_dead: return
	# [추가됨] 플레이어 바라보기 (Flip) 로직
	# 보스가 보이고(전멸기 중 아님), 플레이어가 있다면 방향 전환
	if player and anim.visible:
		# 플레이어가 보스보다 왼쪽에 있으면 -> 왼쪽 보기 (flip_h = true)
		if player.global_position.x < global_position.x:
			anim.flip_h = true
		# 플레이어가 오른쪽에 있으면 -> 오른쪽 보기 (flip_h = false)
		else:
			anim.flip_h = false
			
	# 히트박스 업데이트
	_update_hitbox_position()

# --- [핵심 기능] 프레임에 따라 히트박스 이동 (좌우 반전 적용) ---
func _update_hitbox_position():
	if anim.animation == "normalattack_2" and anim.is_playing():
		hit_shape.disabled = false 
		var current_frame = anim.frame
		
		# [수정] 바라보는 방향에 따라 X축 좌표를 반전시킴
		# flip_h가 켜져있으면(왼쪽) -1, 꺼져있으면(오른쪽) 1
		var dir_mult = -1 if anim.flip_h else 1
		
		match current_frame:
			# 기존 좌표의 x값에 dir_mult를 곱해줍니다.
			0: hit_area.position = Vector2(20 * dir_mult, -50) 
			1: hit_area.position = Vector2(50 * dir_mult, -40) 
			2: hit_area.position = Vector2(80 * dir_mult, 0)   
			3: hit_area.position = Vector2(50 * dir_mult, 40)  
			4: hit_area.position = Vector2(20 * dir_mult, 50)  
			_: pass
	else:
		hit_shape.disabled = true


# --- 히트박스 충돌 처리 ---
func _on_hitbox_entered(body: Node2D):
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)


# --- [메인 패턴 로직: 수정됨] ---
func start_pattern_loop():
	# 보스가 살아있는 동안 무한 반복
	while hp > 0 and not is_dead:
		
		# 1. 패턴 시전 (여기서 await으로 패턴이 끝날 때까지 기다림)
		await choose_random_pattern()
		
		if is_dead: break

		# 2. 패턴이 끝났으므로 Idle 모션 재생
		print("패턴 종료. 쿨타임 시작 (10초)")
		if anim.sprite_frames.has_animation("idle"):
			anim.play("idle")
		
		# 3. 쿨타임 대기 (패턴 종료 후 10초)
		await get_tree().create_timer(pattern_cooldown).timeout


func choose_random_pattern():
	if is_doing_pattern or is_dead: return
	
	is_doing_pattern = true
	var random_pick: int
	
	# [수정] 첫 패턴일 경우 필살기(3번) 제외하고 1, 2번 중에서만 선택
	if is_first_pattern:
		random_pick = randi() % 2 + 1 # 1 ~ 2
		is_first_pattern = false # 플래그 해제
		print("첫 패턴 실행 (필살기 제외됨): ", random_pick)
	else:
		random_pick = randi() % 3 + 1 # 1 ~ 3
		print("선택된 패턴: ", random_pick)
	
	# 패턴 실행 및 종료 대기
	match random_pick:
		1: await _pattern_summon()
		2: await _pattern_fire_projectile()
		3: await _pattern_ultimate()
	
	is_doing_pattern = false 

# --- [패턴 1] 소환 ---
func _pattern_summon():
	print("패턴: 소환 시작")
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
			get_parent().call_deferred("add_child", minion) # 안전하게 추가
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
# 투명해진 상태로 이 공격을 시전할수도 있음. 해결법: 소환몹 빨리좀 잡지
func _pattern_fire_projectile():
	print("패턴: 근접/투사체 공격 시작")
	if anim.sprite_frames.has_animation("normalattack_2"):
		anim.play("normalattack_2")
		await anim.animation_finished
	
	if player and projectile_boss:
		var projectile = projectile_boss.instantiate()
		projectile.global_position = global_position
		var dir = (player.global_position - global_position).normalized()
		
		if "direction" in projectile: projectile.direction = dir 
		elif projectile.has_method("setup"): projectile.setup(dir, damage)
		
		projectile.rotation = dir.angle()
		get_parent().call_deferred("add_child", projectile)

# --- [패턴 3] 전멸기 ---
func _pattern_ultimate():
	print("패턴: 필살기 시작")
	is_invincible = true 
	
	# 1. 스킬 시전 모션
	if anim.sprite_frames.has_animation("skill"):
		anim.play("skill")
		await anim.animation_finished
	
	# [중요 수정 1] 보스 전체(self)가 아니라 '스프라이트'만 숨깁니다.
	# visible = false  <-- 이걸 쓰면 SafeZone도 같이 안 보입니다!
	anim.visible = false 
	
	# 히트박스 끄기
	collision_shape.set_deferred("disabled", true) 
	
	print("!!! 전멸기 준비 !!!")
	
	if red_screen: red_screen.visible = true
	
	# [중요 수정 2] SafeZone 소환 및 위치 설정
	if SafeZonePos:
		SafeZonePos.visible = true
		
		# (선택) SafeZone이 보스의 움직임에 딸려가지 않게 독립적으로 만듭니다.
		if SafeZonePos.is_inside_tree():
			SafeZonePos.top_level = true 
		
		# --- 위치 계산 (화면 범위 내 랜덤) ---
		var camera = get_viewport().get_camera_2d()
		if camera:
			var center = camera.get_screen_center_position()
			var size = get_viewport_rect().size / camera.zoom
			var margin = 100.0
			
			var min_x = center.x - (size.x / 2) + margin
			var max_x = center.x + (size.x / 2) - margin
			var min_y = center.y - (size.y / 2) + margin
			var max_y = center.y + (size.y / 2) - margin
			
			SafeZonePos.global_position = Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))
		else:
			# 카메라가 없으면 플레이어 근처에
			if player:
				SafeZonePos.global_position = player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	
	# 5초 대기 (패턴 지속 시간)
	await get_tree().create_timer(5.0).timeout
	
	# --- 생존 판정 및 정리 ---
	if player and SafeZonePos:
		# [주의] global_position으로 거리 계산
		var dist = player.global_position.distance_to(SafeZonePos.global_position)
		# SafeZone 반지름이 150이라고 가정 (스프라이트 크기에 맞춰 조절 필요)
		if dist > 150: 
			if player.has_method("take_damage"): 
				player.take_damage(9999) 
				print("즉사기 적중!")
	
	# SafeZone 숨기기
	if SafeZonePos: SafeZonePos.visible = false
	if red_screen: red_screen.visible = false 

	# [중요 수정 3] 보스 스프라이트 다시 켜기
	anim.visible = true
	collision_shape.set_deferred("disabled", false)
	is_invincible = false
	
	# 복귀 모션
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
	
	hit_shape.set_deferred("disabled", true)
	
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()
