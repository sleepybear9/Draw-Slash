extends CharacterBody2D

# [설정 변수]
@export var max_hp: int = 5000
@export var pattern_cooldown: float = 10.0 # 패턴 사이 간격 10초

# [필요한 씬들 연결]
@export var projectile_scene: PackedScene # 낫 투사체 씬(.tscn), 찾는중
@export var minion_scene: PackedScene     # 소환할 몬스터 씬(.tscn), 기존 몬스터 소환
@export_group("Summon Pattern")
@export var enemy: PackedScene 
@export var monster_range: PackedScene
# [노드 연결]
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var dangerzone: Area2D = $dangerzone # 필살기 전체 범위
@onready var safe_zone_indicator: Node2D = $SafeZonePos # 안전지대 위치 표시용 노드

var hp: int
var player: Node2D
var is_invincible: bool = false # 무적 상태 확인
var active_minions: int = 0     # 현재 살아있는 소환수 수
var is_doing_pattern: bool = false # 현재 패턴 사용 중인지

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	dangerzone.monitoring = false # 필살기 범위 꺼두기
	
	# 게임 시작 후 3초 뒤 첫 패턴 시작
	await get_tree().create_timer(3.0).timeout
	start_pattern_loop()

func _physics_process(_delta):
	# 패턴 중이 아닐 때만 플레이어를 바라보거나 이동하는 로직 추가 가능
	pass

# --- [메인 패턴 로직] ---
func start_pattern_loop():
	while hp > 0:
		if not is_doing_pattern:
			choose_random_pattern()
		# 10초 쿨타임 대기 (패턴이 끝난 후가 아니라, 시작 주기라면 여기서 제어)
		await get_tree().create_timer(pattern_cooldown).timeout

func choose_random_pattern():
	if is_doing_pattern or hp <= 0: return
	
	is_doing_pattern = true
	var random_pick = randi() % 3 + 1 # 1, 2, 3 중 하나 선택
	
	match random_pick:
		1: _pattern_summon()
		2: _pattern_scythe()
		3: _pattern_ultimate()

# --- [패턴 1: 몬스터 소환] ---, 소환물들은 모듈레이터값 따로
func _pattern_summon():
	#print("패턴 1: 쫄병 5마리 무작위 소환")
	anim.play("summon") # 소환 모션 재생
	
	# 보스 무적 설정
	is_invincible = true
	modulate = Color(0.5, 0.5, 1, 0.8) # 무적 표시 (푸르스름하고 약간 투명하게)
	
	# 총 5마리 소환 루프
	var total_spawn_count = 5
	
	for i in range(total_spawn_count):
		# 1. 근거리 vs 원거리 랜덤 선택 (50% 확률)
		var spawn_scene: PackedScene
		if randi() % 2 == 0:
			spawn_scene = enemy # 근거리
		else:
			spawn_scene = monster_range # 원거리
			
		# 2. 몬스터 생성
		if spawn_scene:
			var minion = spawn_scene.instantiate()
			
			# 3. 위치 설정
			var random_offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
			minion.global_position = global_position + random_offset
			
			# 4. 씬 트리에 추가 (보스의 자식이 아니라, 맵(부모)에 추가해야 보스가 움직여도 따라오지 않음)
			get_parent().add_child(minion)
			
			
			# 5. 사망 감지 연결
			minion.tree_exited.connect(_on_minion_died)
			
			active_minions += 1
	
	is_doing_pattern = false 


# 쫄병이 죽었을 때 호출되는 함수
func _on_minion_died():
	active_minions -= 1
	print("남은 쫄병 수: ", active_minions)
	
	if active_minions <= 0:
		# 모든 쫄병 사망 시 무적 해제 및 데미지
		_break_invincibility()

# 무적 해제 처리 (코드가 길어져서 분리함)
func _break_invincibility():
	is_invincible = false
	modulate = Color(1, 1, 1, 1) # 원래 색으로 복구

	take_damage(1000)


# --- [패턴 2: 낫 휘두르기] ---
func _pattern_scythe():
	#print("패턴 2: 낫 던지기")
	anim.play("normalattack_2")
	
	if player:
		var scythe = projectile_scene.instantiate()
		scythe.global_position = global_position
		# 플레이어 방향 계산
		var dir = (player.global_position - global_position).normalized()
		scythe.direction = dir
		scythe.rotation = dir.angle() # 낫이 날아가는 방향 봄
		get_parent().add_child(scythe)
	
	await anim.animation_finished
	is_doing_pattern = false

# --- [패턴 3: 필살기] ---
func _pattern_ultimate():
	#print("패턴 3: 필살기 준비")
	is_invincible = true # 시전 중 무적 (선택사항)
	anim.play("skill") # 사라지는 모션
	
	# 1. 보스 숨기기
	await anim.animation_finished
	visible = false #숨겨도 collision 유효할수 있음
	
	#child1.monitorable = false
	#child1.monitoring = false 이거쓰는거 권장
	
	await get_tree().create_timer(5.0).timeout
	
	# 3. 광역 데미지 판정
	# 안전지대(SafeZone) 안에 플레이어가 없으면 데미지
	if player:
		var dist_to_safe = player.global_position.distance_to(safe_zone_indicator.global_position)
		if dist_to_safe > 100: # 안전지대 반경 100 밖이라면
			player.take_damage(9999) # 즉사급 데미지
			print("DANGER!!!")
		else:
			print("SAFE")
			
	# 4. 보스 재등장
	visible = true
	#monitorable = true
	#monitoring = true 
	is_invincible = false
	anim.play("return") # 등장 모션, skill 애니메이션 공유
	await anim.animation_finished
	is_doing_pattern = false

# --- [데미지 처리] ---
func take_damage(amount):
	if is_invincible:
		print("Immune")
		return # 데미지 무효화
		
	hp -= amount
	print("보스 HP: ", hp)
	if hp <= 0:
		#여기에 사망 애니메이션 명령, 애니메이션 끝나고 die 호출
		is_invincible = true
		$AnimationPlayer.play("death")
		await $AnimationPlayer.animation_finished
		die()
		

func die():
	queue_free()
