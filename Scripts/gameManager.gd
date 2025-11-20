extends Node

var is_paused = false

func pause_toggle():
	get_tree().paused = !get_tree().paused
	is_paused = get_tree().paused
