extends CharacterBody2D 

@export var speed: float = 80
@export var attack_distance: float = 80
@export var dash_distance: float = 100
@export var dash_speed: float = 220
@export var attack_cooldown: float = 2.0
@export var damage: int = 15
@export var max_hp: int = 45

var hp: int
var player: Node2D
var can_attack = true
var player_in_attack_area = false
var current_dir: String = "down"

# [추가] 공격(대시) 중 이동 제어를 위한 변수
var is_attacking = false

# --- 길찾기 필수 노드 ---
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var timer: Timer = $Timer

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange

func _ready():
	hp = max_hp
	player = get_tree().get_root().find_child("Player", true, false)
	attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
	attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))
	
	call_deferred("navi_setup")
	
	# 초기 애니메이션은 걷는 것과 이름을 맞추는 게 좋습니다 (run -> walk_down 등)
	anim.play("walk_down")

func navi_setup():
	await get_tree().physics_frame
	if timer:
		timer.timeout.connect(_update_navigation_target)
		timer.start(0.2)

func _update_navigation_target():
	if player:
		nav_agent.target_position = player.global_position

func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player_in_attack_area = true

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player_in_attack_area = false

func _update_direction(vec: Vector2):
	# 공격 중엔 방향 전환 금지
	if is_attacking: return

	if abs(vec.x) > abs(vec.y):
		current_dir = "right" if vec.x > 0 else "left"
	else:
		current_dir = "down" if vec
