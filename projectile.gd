extends Area2D

# [설정 변수]
@export var speed: float = 600.0  # 날아가는 속도
@export var damage: int = 30      # 데미지 양

var direction: Vector2 = Vector2.RIGHT # 보스 스크립트에서 이 값을 덮어씌워줍니다.

func _ready():
	# 3초가 지나도 아무것도 안 맞으면 자동 삭제 (메모리 관리)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 1. 이동 로직
	position += direction * speed * delta

# --- [신호 연결 함수] ---
func _on_body_entered(body):
	# 부딪힌 게 플레이어인지 확인 (그룹 또는 이름으로)
	if body.is_in_group("player") or body.name == "Player":
		print("플레이어 명중!")
		
		# 플레이어에게 데미지 주기 (함수 있는지 확인)
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
		# 투사체 삭제 (관통하게 하려면 이 줄을 지우세요)
		queue_free()
	
	# 벽(TileMap)에 부딪히면 삭제: 이거 투사체가 지형물에 안막히는거 원하면 냅두면돼
	# if body is TileMapLayer or body.name == "Wall":
	# 	queue_free()

# VisibleOnScreenNotifier2D의 'screen_exited' 시그하면 더 좋습니다.널을 연결
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
