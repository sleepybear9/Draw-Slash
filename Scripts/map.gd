extends Node2D

@export var chunk_size := Vector2(1280, 1280)
@onready var cam = $"../../Player/Camera2D"

func _on_map_checker_area_exited(area: Area2D) -> void:
	
	var chunk_center = global_position + chunk_size / 2
	var diff = cam.global_position - chunk_center

	if abs(diff.x) > abs(diff.y):
		if diff.x > chunk_size.x / 2:
			global_position.x += chunk_size.x * 2
		elif diff.x < -chunk_size.x / 2:
			global_position.x -= chunk_size.x * 2
	else:
		if diff.y > chunk_size.y / 2:
			global_position.y += chunk_size.y * 2
		elif diff.y < -chunk_size.y / 2:
			global_position.y -= chunk_size.y * 2

	print(self.name, global_position)
