extends Node

var is_paused = false
var is_end = false
var is_main = false
var Game
var player_dir: Vector2 = Vector2(0,0)
var player
@onready var levels = [preload("res://Scenes/Level_1.tscn"),preload("res://Scenes/Level_2.tscn")]
var map
var timer
var d = 680 # +-680 or 0, +-680 or 0 = 8 location

func _ready():
	await get_tree().process_frame
	Game = get_node("/root/Game")

	timer = Game.get_node("Spawning")
	timer.timeout.connect(spawn)
	
	player = Game.get_node("Y_Sort/Player")
	start(1)

func start(stage: int):
	is_main = false
	map = levels[stage].instantiate()
	Game.get_node("Y_Sort").add_child(map)
	
	timer.start()

func pause_toggle():
	get_tree().paused = !get_tree().paused
	is_paused = get_tree().paused

func spawn():
	var center = player.global_position

	var points = [
		center + Vector2(-d, 0),   # left
		center + Vector2(d, 0),    # right
		center + Vector2(0, -d),   # top
		center + Vector2(0, d),    # bottom
		
		center + Vector2(-d, -d),  # left-top
		center + Vector2(d, -d),   # right-top
		center + Vector2(-d, d),   # left-bottom
		center + Vector2(d, d),    # right-bottom
	]
	var spawn_point = points.pick_random()

	#test_spawn_visual(spawn_point)

func test_spawn_visual(pos: Vector2):
	var rect := ColorRect.new()
	rect.color = Color(1, 0, 0, 0.7)  # 빨간색 + 반투명
	rect.size = Vector2(30, 30)      # 보이는 크기
	rect.pivot_offset = rect.size / 2
	rect.global_position = pos

	# 화면에 보이게 Game의 Y_Sort 아래에 추가
	Game.get_node("Y_Sort").add_child(rect)
	


	
