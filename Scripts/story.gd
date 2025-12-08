extends Node2D

@onready var scene1 = $scene1
@onready var scene2 = $scene2
@onready var scene3 = $scene3
@onready var timer = $Timer

const NEXT_SCENE_PATH = "res://Scenes/main.tscn"

var now : int = 1

func _ready() -> void:
	#scene1
	scene1.visible = true
	scene2.visible = false
	scene3.visible = false
	timer.start()

func _on_timer_timeout() -> void:
	
	#scene2
	if now == 1 :
		scene1.visible = false
		scene2.visible = true
		now += 1
		
	#scene3
	elif now == 2 :
		print("2")
		scene2.visible = false
		scene3.visible = true
		now += 1
		
	#go to game
	elif now == 3 :
		print("?")
		var next_scene_resource = load(NEXT_SCENE_PATH)
		var new_scene_instance = next_scene_resource.instantiate()
		
		var tree = get_tree()
		var current_scene = tree.current_scene
		
		current_scene.queue_free()
		
		tree.root.add_child(new_scene_instance)
		tree.current_scene = new_scene_instance
