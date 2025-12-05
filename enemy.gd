extends CharacterBody2D

@export var speed: float = 70
@export var attack_distance: float = 50
@export var attack_cooldown: float = 1.0
@export var damage: int = 10
@export var max_hp: int = 30

# [효과음 관련 변수] - 인스펙터에서 오디오 파일을 넣어야 합니다.
@export_group("Sound Effects")
@export var sfx_monster_attack_melee: AudioStream # 공격 소리 파일
@export var sfx_hit_player: AudioStream   # 플레이어 타격 성공 소리 파일
@export var sfx_hurt: AudioStream         # 몬스터 피격 소리 파일
@export var sfx_monster_death: AudioStream        # 몬스터 사망 소리 파일

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
# [중요] 씬에 AudioStreamPlayer2D 노드가 있어야 하고 이름이 "SfxPlayer"여야 합니다.
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer 


func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))

	anim.play("walk_down")


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


func _physics_process(delta):
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= attack_distance:
		_do_attack()
		return
	
	_chase_player(delta)


func _chase_player(delta):
	var direction = (player.global_position - global_position)
	_update_direction(direction)

	velocity = direction.normalized() * speed
	move_and_slide()

	# 공격 중이 아닐 때만 걷는 애니메이션 재생 (안 그러면 공격 모션이 끊김)
	if can_attack:
		var walk_name = "walk_" + current_dir
		if anim.animation != walk_name:
			anim.play(walk_name)


func _do_attack():
	if can_attack:
		velocity = Vector2.ZERO
		can_attack = false
		_perform_attack()


# [여기가 가장 많이 수정된 부분입니다]
func _perform_attack():
	# 1. 공격 애니메이션 재생 (예: attack_down, attack_left...)
	var attack_anim_name = "attack_" + current_dir
	anim.play(attack_anim_name)
	
	# 2. 공격 소리 재생

	_play_sfx(sfx_monster_attack_melee)

	# 3. 데미지 판정
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		# 만약 플레이어를 때렸을 때 별도 소리를 내고 싶다면 아래 주석 해제
		# _play_sfx(sfx_hit_player)
	
	# 4. 쿨타임 대기
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


func take_damage(amount: int):
	hp -= amount
	
	# [수정] 몬스터가 맞았을 땐 sfx_hurt를 재생해야 맞습니다. ($monster_death는 잘못된 참조)
	_play_sfx(sfx_hurt) 
	
	print("몬스터 HP:", hp)

	if hp <= 0:
		_die()


func _die():
	velocity = Vector2.ZERO
	# 죽은 뒤에는 공격 판정을 끕니다.
	if attack_area:
		attack_area.monitoring = false
	
	_play_sfx(sfx_monster_death) 

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)

	await anim.animation_finished
	queue_free()


# [헬퍼 함수] 깔끔하게 잘 작성되었습니다. 이대로 쓰면 됩니다.
func _play_sfx(stream: AudioStream):
	# stream이 비어있지 않고(오디오 파일을 넣었고), 플레이어 노드가 있을 때만 실행
	if stream and sfx_player:
		sfx_player.stream = stream
		sfx_player.pitch_scale = randf_range(0.9, 1.1)
		sfx_player.play()
