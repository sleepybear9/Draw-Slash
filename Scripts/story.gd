extends Node2D

@onready var scene1 = $scene1
@onready var scene2 = $scene2
@onready var scene3 = $scene3

var scenes: Array # Array of story scenes
var now: int = 0 # Current scene index
var tween: Tween
var is_transitioning: bool = false # Flag for checking fade is running
const FADE_TIME := 0.5

func _ready() -> void:
	scenes = [scene1, scene2, scene3]

func _process(delta: float) -> void:
	if visible and Input.is_action_just_pressed("click"):
		# Allow fast skipping:
		if is_transitioning and tween:
			tween.kill()
			is_transitioning = false
		next()

func start():
	for s in scenes:
		s.visible = false
		s.modulate.a = 0.0

	now = 0
	scenes[0].visible = true

	# Fade in the first scene
	is_transitioning = true
	tween = create_tween()
	tween.tween_property(scenes[0], "modulate:a", 1.0, FADE_TIME)
	tween.tween_callback(func():
		is_transitioning = false
	)


func next():
	# Prevent double transitions unless click is allowed
	if is_transitioning:
		return
		
	now += 1

	# If all scenes are done, finish the story
	if now >= scenes.size():
		end_story()
		return

	var prev = scenes[now - 1]
	var current = scenes[now]

	is_transitioning = true
	tween = create_tween()

	# Fade out previous scene
	tween.tween_property(prev, "modulate:a", 0.0, FADE_TIME / 2)

	# Switch visibility after fade out
	tween.tween_callback(func():
		prev.visible = false
		current.visible = true
	)

	# Fade in current scene
	tween.tween_property(current, "modulate:a", 1.0, FADE_TIME)

	# End transition
	tween.tween_callback(func():
		is_transitioning = false
	)


func end_story():
	visible = false

	# Start the actual game
	GameManager.start()
