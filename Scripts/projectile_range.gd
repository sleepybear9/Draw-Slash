extends Area2D

@export var speed: float = 400 # 날아가는 속도
var direction: Vector2 = Vector2.ZERO
var damage: int = 10

func _ready():
	# [해결] 여기서 connect 코드를 쓰지 마세요. 
	# 대신 에디터 우측 [Node] 탭에서 body_entered를 이 스크립트의 _on_body_entered에 연결하세요.
	
	# 3초 뒤에 자동으로 사라짐 (메모리 정리)
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	# 방향대로 날아감
	position += direction * speed * delta

# [중요] 몬스터가 이 함수를 호출해서 정보를 넘겨줍니다. 없으면 에러 납니다!
func setup(dir: Vector2, dmg: int):
	direction = dir
	damage = dmg
	rotation = dir.angle() # 날아가는 방향으로 회전

# [시그널] 에디터에서 연결된 함수
func _on_body_entered(body):
	# 플레이어와 부딪혔을 때
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free() # 맞았으니 사라짐
		
	# 벽(TileMap 등)에 부딪혔을 때 (몬스터 자신은 통과)
	elif body.name != "Monster": 
		# 토사물이니까 벽에 닿으면 바로 사라지게
		queue_free()
