# 투사체 스크립트 예시 (MonsterProjectile.gd)
extends Area2D

var direction := Vector2.ZERO
var damage := 0
var speed := 200.0

#쳐다보는 방향으로 투사체 발
func setup(dir: Vector2, dmg: int):
	direction = dir
	damage = dmg

func _physics_process(delta):
	position += direction * speed * delta

# 플레이어 피격
func _on_body_entered(body):
	if body.is_in_group("player"): # 플레이어 맞춤
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
