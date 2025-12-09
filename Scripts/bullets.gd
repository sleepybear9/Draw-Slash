extends Area2D

var speed = 400
var direction = Vector2.ZERO
var damage = 20

func _physics_process(delta):
	position += direction * speed * delta

# 화면 밖으로 나가면 삭제
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

# 플레이어와 충돌 시 (시그널 연결 필요)
func _on_body_entered(body):
	if body.name == "Player": # 혹은 body.is_in_group("player")
		body.take_damage(damage)
		queue_free()
