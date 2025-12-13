extends Area2D

# [설정 변수]
@export var speed: float = 800.0 
@export var damage: int = 20

var direction: Vector2 = Vector2.RIGHT 

func _ready():
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 1. 이동 로직
	position += direction * speed * delta

# --- [신호 연결 함수] ---
# Area2D 노드의 'body_entered' 시그널을 연결하세요.
func _attack(body):
	# 부딪힌 게 플레이어인지 확인 (그룹 또는 이름으로)
	if body.name == "Hitbox":
		print("플레이어 명중!")
		
		GameManager.player.take_damage(damage)
