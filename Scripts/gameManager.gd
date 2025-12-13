extends Node

var is_paused = true
var is_end = false
var is_main = true
var Game
var sortable
var menus =[]
var player_dir: Vector2 = Vector2(0,0)
var player
var cam
var stage = 0
var is_nonboss = [true, false]
var is_clear = false
# level scenes
var levels = [preload("res://Scenes/Level_1.tscn"),preload("res://Scenes/Level_2.tscn")]
var monster = preload("res://Scenes/enemy.tscn")
var max_enemy = 30
var bosses = [preload("res://Scenes/boss.tscn")] #bose scenes
var map
var gate = preload("res://Scenes/Gate.tscn")
var timer
var hud
var d = 680 # +-680 or 0, +-680 or 0 = 8 locations of spawning
var enemies = []

var test = true #temp variable

func _ready():
	await get_tree().process_frame
	Game = get_node("/root/Game")

	var main = Game.get_node("CanvasLayer/MainMenu")
	menus.append(main)
	timer = Game.get_node("Spawning")
	timer.timeout.connect(spawn.bind(0))
	sortable = Game.get_node("Y_Sort")
	player = sortable.get_node("Player")
	cam = player.get_node("Camera2D")
	hud = Game.get_node("CanvasLayer/Hud")

func start():
	menus[0].hide()
	set_game()
	is_main = false
	is_paused = false
	hud.show()
	hud.start()
	
func upstair():
	stage += 1
	set_game()
	hud.start()
	
func _physics_process(delta: float) -> void:
	if !is_clear:
		for e in enemies:
			if e.visible and e.global_position.distance_to(player.global_position) > d+100:
				e.global_position = player.global_position + (d+50) * e.global_position.direction_to(player.global_position)
		if Input.is_action_just_pressed("test"):
			print("try")
			spawn(1)

func pause_toggle():
	get_tree().paused = !get_tree().paused
	is_paused = get_tree().paused

func set_game():
	is_main = false
	
	if map: map.queue_free()
	map = levels[stage].instantiate()
	sortable.add_child(map)
	
	if !test:
		timer.start()
	is_clear = false

func clear():
	is_clear = true
	timer.stop()
	for e in enemies:
		e.queue_free()
	enemies.clear()
	var portal = gate.instantiate()
	portal.global_position = get_point()
	sortable.add_child(portal)

func get_point() -> Vector2:
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
	var point = points.pick_random()
	print(point)	
	return point
	

func spawn(type: int):
	if (type == 0):
		if enemies.size() < max_enemy:
			var spawn_point = get_point()
			var enemy = spawn_monster(spawn_point) 
	else:
		print(1)
		var boss = spawn_boss(type-1)
		sortable.add_child(boss)
	
func spawn_monster(pos: Vector2):
	var enemy
	for e in enemies:
		if e.is_dead:
			print("reuse")
			enemy = e
			enemy.global_position = pos
			enemy.set_process(true)
			enemy.set_physics_process(true)
			enemy.show()
			enemy.setup(randi_range(0,1))
			return enemy
	
	print("add")
	enemy = monster.instantiate()
	enemies.append(enemy)
	enemy.global_position = pos
	sortable.add_child(enemy)
	enemy.setup(randi_range(0,1))
	return enemy

func spawn_boss(type: int):
	type -= 1 # tempory in current condition
	var bose = bosses[type].instantiate()
	sortable.add_child(bose)
	var pos : Vector2= Vector2(0,0)
	bose.global_position = pos
	
	show_boss_spawn(pos)
	

func show_boss_spawn(spawn_pos: Vector2):
	var camera_speed = 0.005
	var original_pos = cam.global_position
	var distance = original_pos.distance_to(spawn_pos)
	var calculated_speed = pow(distance, 1.6) * camera_speed 
	var move_time = min(0.3, distance / calculated_speed)
	
	var tween = create_tween()
	
	
	hud.hide()
	is_paused = true
	tween.tween_property(cam, "global_position", spawn_pos, move_time)
	await tween.finished

	await get_tree().create_timer(0.8).timeout

	var tween2 = create_tween()
	tween2.tween_property(cam, "position", Vector2.ZERO, move_time)
	await tween2.finished
	hud.show()
	is_paused = false




	
