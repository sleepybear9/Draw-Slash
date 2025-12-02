extends CharacterBody2D

# --- 오디오 및 설정 ---
@export var max_hp: int = 10000
@export var attack_damage: int = 50
@export var contact_damage: int = 10
@export var attack_interval: float = 4.0 # 테스트를 위해 8초 -> 4초로 줄임

# 투사체 씬 (인스펙터에서 넣으세요)
@export var projectile_scene: PackedScene 

var current_hp: int
var player: Node2D
var attack_index: int = 0 

# --- 필수 노드 참조 ---
# 보스 몸체에 닿으면 데미지를 주기 위한 Area2D가 필요합니다.
@onready var contact_area: Area2D = $ContactArea 
@onready var sfx_attack: AudioStreamPlayer2D = $SfxAttack # 공격 효과음 노드 (없으면 지우세요)

func _ready():
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")
	
	# 몸통 박치기 데미지 시그널 연결
	if contact_area:
		contact_area.body_entered.connect(_on_contact_area_entered)
		
	# 공격 루프 시작
	_start_attack_cycle()

func _physics_process(delta):
	# 보스는 보통 가만히 있거나 특정 패턴때만 움직임
	move_and_slide()

# --- 접촉 데미지 (Area2D 사용) ---
func _on_contact_area_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)

# --- 피격 및 사망 ---
func take_damage(amount: int):
	current_hp -= amount
	print("Boss HP:", current_hp)
	
	# 깜빡이는 효과 (선택)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if current_hp <= 0:
		die()

func die():
	print("Boss defeated!")
	queue_free()

# --- 공격 사이
