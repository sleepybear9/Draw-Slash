extends Area2D

# [설정 변수]
@export var speed: float = 600.0  # 날아가는 속도
@export var damage: int = 50      # 데미지 양
@export var rotation_speed: float = 10.0 # 낫이 회전하는 속도 (빙글빙글)

var direction: Vector2 = Vector2.RIGHT # 보스 스크립트에서 이 값을 덮어씌워줍니다.

func _ready():
	# 3초가 지나도 아무것도 안 맞으면 자동 삭제 (메모리 관리)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 1. 이동 로직
	position += direction * speed * delta
	
	# 2. 회전 로직 (낫이니까 빙글빙글 돌면서 날아가게 연출)
	# 보스가 방향을 잡아주긴 했지만, 자체적으로 회전도 추가하면 더 멋집니다.
	# 회전이 필요 없으면 아래 줄은 지우세요.
	$Sprite2D.rotation += rotation_speed * delta

# --- [신호 연결 함수] ---
# Area2D 노드의 'body_entered' 시그널을 연결하세요.
func _on_body_entered(body):
	# 부딪힌 게 플레이어인지 확인 (그룹 또는 이름으로)
	if body.is_in_group("player") or body.name == "Player":
		print("플레이어 명중!")
		
		# 플레이어에게 데미지 주기 (함수 있는지 확인)
		if body.has_method("take_damage"):
			body.take_damage(damage)
			
		# 투사체 삭제 (관통하게 하려면 이 줄을 지우세요)
		queue_free()
	
	# 벽(TileMap)에 부딪히면 삭제되게 하려면?
	# if body is TileMapLayer or body.name == "Wall":
	# 	queue_free()

# VisibleOnScreenNotifier2D의 'screen_exited' 시그하면 더 좋습니다.널을 연결
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
