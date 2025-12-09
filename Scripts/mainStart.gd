extends TextureButton
@onready var story = $"../../Story"
var is_used = false

func _on_pressed() -> void:
	if !is_used:
		story.show()
		story.start()
		is_used = true
