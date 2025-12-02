extends Node

var is_paused = false
var is_end = false
var is_main = true #temp value

func pause_toggle():
	get_tree().paused = !get_tree().paused
	is_paused = get_tree().paused
