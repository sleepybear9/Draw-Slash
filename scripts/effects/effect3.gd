extends Area2D

@onready var timer = $Timer
@onready var anim_player = $AnimationPlayer

@onready var deck_manager = $"/root/DeckManager"

var enabled : bool = false

func _ready() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))
	
#card effect on
func _on_card_effect_3() -> void: 
	if enabled == false :
		self.visible = true
		self.monitorable = true
		self.monitoring = true
		#여기 direction 수정 필요
		look_at(self.global_position + Vector2.LEFT)
		timer.start()
		anim_player.play("lazer")
		enabled = true
		deck_manager.add_card("card3", -1)

#card effect off
func _timeout() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	enabled = false
