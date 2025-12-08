extends TextureButton

const NEXT_SCENE_PATH = "res://Scenes/story.tscn"

#func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#var next_scene_resource = load(NEXT_SCENE_PATH)
			#var new_scene_instance = next_scene_resource.instantiate()
			#
			#var tree = get_tree()
			#var current_scene = tree.current_scene
			#
			#current_scene.queue_free()
			#
			#tree.root.add_child(new_scene_instance)
			#tree.current_scene = new_scene_instance
	

func _on_pressed() -> void:
	var next_scene_resource = load(NEXT_SCENE_PATH)
	var new_scene_instance = next_scene_resource.instantiate()
	
	var tree = get_tree()
	var current_scene = tree.current_scene
	
	current_scene.queue_free()
	
	tree.root.add_child(new_scene_instance)
	tree.current_scene = new_scene_instance
