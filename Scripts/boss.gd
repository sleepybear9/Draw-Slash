extends CharacterBody2D

# [설정 변수]
@export var max_hp: int = 500
@export var pattern_cooldown: float = 10.0 
@export var dmg: int = 20
var offset = 219.0

# [필요한 씬들 연결]
@export_group("Summon Pattern")
var projectile = preload("res://Scenes/projectile.tscn")

# [노드 연결]
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var SafeZonePos = $SafeZonePos
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
# [공격 판정 노드]
@onready var attack1 = $attack1
@onready var attack2 = $attack2
@onready var delayer = $Timer
var attackable = true
@onready var dead = $sfx_boss_death

# [상태 변수]
var hp: int
var player
var is_invincible: bool = false 
var active_minions: int = 0       
var is_doing_pattern: bool = false
var is_dead: bool = false

var is_first_pattern: bool = true

func _ready():
	hp = max_hp
	attack1.monitorable = false
	attack1.monitoring = false
	attack2.monitorable = false
	attack2.monitoring = false
	
	player = $"../Player"

	if anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

	print("보스 등장. 5초 대기 중...")

	await get_tree().create_timer(5.0).timeout
	
	# 죽지 않았으면 패턴 루프 시작
	if not is_dead:
		start_pattern_loop()
	

func _physics_process(_delta):
	if is_dead: return
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
	if anim.animation == "normalattack_1":
		if anim.flip_h:	attack1.scale.x = -1
		else: attack1.scale.x = 1
	if anim.animation == "normalattack_2":
		if anim.flip_h:	attack1.scale.x = -1
		else: attack1.scale.x = 1


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
	
	attackable = false
	is_invincible = true
	modulate = Color(0.5, 0.5, 1, 0.8) 
	
	var total_spawn_count = 5
	for i in range(total_spawn_count):
		var type = randi_range(0,1)
		var random_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
		
		var minion = GameManager.spawn_monster(global_position + random_offset, type)
		minion.by_boss = true
		minion.modulate = Color(0.5, 0.5, 1, 0.8) 
		
		active_minions += 1

func _on_minion_died():
	active_minions -= 1
	if active_minions <= 0: _break_invincibility()

func _break_invincibility():
	if is_invincible:
		is_invincible = false
		attackable = true
		modulate = Color(1, 1, 1, 1)
		take_damage(50)

# --- [패턴 2] 공격 ---
# 투명해진 상태로 이 공격을 시전할수도 있음. 해결법: 소환몹 빨리좀 잡지
func _pattern_fire_projectile():
	print("패턴: 근접/투사체 공격 시작")
	if anim.sprite_frames.has_animation("normalattack_2"):
		anim.play("normalattack_2")
		await get_tree().create_timer(0.65).timeout
	
	if player:
		var proj = projectile.instantiate()
		proj.global_position = global_position
		proj.look_at(player.global_position)
		var dir = global_position.direction_to(player.global_position)
		proj.direction = dir
		
		get_parent().call_deferred("add_child", proj)

# --- [패턴 3] 전멸기 ---
func _pattern_ultimate():
	print("패턴: 필살기 시작")
	is_invincible = true 
	attackable = false
	
	# 1. 스킬 시전 모션
	if anim.sprite_frames.has_animation("skill"):
		anim.play("skill")
		await anim.animation_finished
	
	# visible = false  <-- 이걸 쓰면 SafeZone도 같이 안 보입니다!
	anim.visible = false 
	
	# 히트박스 끄기
	collision_shape.set_deferred("disabled", true) 
	
	print("!!! 전멸기 준비 !!!")
	
	GameManager.boss_warning(true)
	
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
			print(player.global_position," ", SafeZonePos.global_position)
		else:
			# 카메라가 없으면 플레이어 근처에
			if player:
				SafeZonePos.global_position = player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200))
	
	# 5초 대기 (패턴 지속 시간)
	await get_tree().create_timer(5.0).timeout
	
	# --- 생존 판정 및 정리 ---
	var dist = player.global_position.distance_to(SafeZonePos.global_position)
		# SafeZone 반지름이 150이라고 가정 (스프라이트 크기에 맞춰 조절 필요)
	if dist > 150: 
		if player.has_method("take_damage"): 
			player.take_damage(999) 
			print("즉사기 적중!")
	
	# SafeZone 숨기기
	SafeZonePos.visible = false
	GameManager.boss_warning(false)

	anim.visible = true
	collision_shape.set_deferred("disabled", false)
	is_invincible = false
	attackable = true
	
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
	if !attackable: return
	
	attackable = false
	hp -= amount
	print("보스 HP: ", hp)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0: die()
	delayer.start()

func die():
	is_dead = true
	is_doing_pattern = false
	dead.play()
	collision_shape.set_deferred("disabled", true) 
	if anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	GameManager.end()	
	queue_free()
	
func _on_timer_timeout() -> void:
	attackable = true
