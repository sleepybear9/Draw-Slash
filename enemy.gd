extends CharacterBody2D

@export var speed: float = 70
@export var attack_distance: float = 50
@export var attack_cooldown: float = 1.0
@export var damage: int = 10
@export var max_hp: int = 30

# [효과음 관련 변수 추가] -----------------------
@export_group("Sound Effects") # 인스펙터에서 보기 편하게 그룹화
@export var sfx_attack: AudioStream # 공격 휘두르는 소리
@export var sfx_hit_player: AudioStream # 플레이어를 때렸을 때 타격음
@export var sfx_hurt: AudioStream   # 몬스터가 맞았을 때 소리
@export var sfx_death: AudioStream  # 몬스터 사망 소리
# ---------------------------------------------

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
# [오디오 플레이어 노드 연결]
@onready var sfx_player: AudioStreamPlayer2D = $SfxPlayer 


func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)

	# [오타 수정됨] _on_att단ack -> _on_attack
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

	var walk_name = "walk_" + current_dir
	if anim.animation != walk_name:
		anim.play(walk_name)


func _do_attack():
	velocity = Vector2.ZERO
	if can_attack:
		can_attack = false
		_perform_attack()


func _perform_attack():
	var base = "attack_" + current_dir + "_"

	# 공격 1
	_play_sfx(monster_attack_melee) # [소리 재생] 휘두르는 소리
	anim.play(base + "1")
	await anim.animation_finished
	
	# 공격 2
	_play_sfx(sfx_attack) # [소리 재생] 한번 더 휘두르는 소리
	anim.play(base + "2")
	await anim.animation_finished

	# 실제 데미지 판정
	if player_in_attack_area and player and player.has_method("take_damage"):
		player.take_damage(damage)
		_play_sfx(sfx_hit_player) # [소리 재생] 타격 성공 소리
		print("데미지:", damage)

	# 공격 쿨타임
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true


# 몬스터 피격 / 죽음
func take_damage(amount: int):
	hp -= amount
	_play_sfx(monster_death) # [소리 재생] 몬스터 아파하는 소리
	print("몬스터 HP:", hp)

	if hp <= 0:
		_die()


func _die():
	velocity = Vector2.ZERO
	attack_area.monitoring = false
	
	_play_sfx(sfx_death) # [소리 재생] 사망 소리

	var death_anim = "death_down" if current_dir == "down" else "death_up"
	anim.play(death_anim)

	await anim.animation_finished
	queue_free()


# [소리 재생을 돕는 헬퍼 함수]
# 소리 파일이 할당되어 있을 때만 재생하고, 약간의 피치 변주를 주어 자연스럽게 만듦
func _play_sfx(stream: AudioStream):
	if stream and sfx_player:
		sfx_player.stream = stream
		sfx_player.pitch_scale = randf_range(0.9, 1.1) # 소리 높낮이를 약간 랜덤하게 (0.9 ~ 1.1배)
		sfx_player.play()
