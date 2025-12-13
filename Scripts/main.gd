extends Sprite2D

# Reference to the Story node
@onready var story = $"../Story"

# UI buttons
@onready var start = $Start
@onready var exit = $Exit

@onready var bgm = $"../AudioStreamPlayer"

# Enable or disable menu buttons
func setup(how: bool):
	start.disabled = how
	exit.disabled = how


# Called when Start button is pressed
func _on_start_pressed() -> void:
	# Prevent multiple clicks while the story is playing
	setup(true)

	# Start the story sequence
	story.show()
	story.start()


# Called when Exit button is pressed
func _on_exit_pressed() -> void:
	get_tree().quit()
