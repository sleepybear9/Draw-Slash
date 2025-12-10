extends Area2D

@onready var timer = $Timer
@onready var anim_player = $AnimationPlayer

@onready var dice = $"../dice"
@onready var audio = $AudioStreamPlayer2D

var enabled : bool = false

var dmg : int

var is_shoot = false

func _ready() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))

#shoot lazer
func _physics_process(delta: float) -> void:
	if is_shoot:
		look_at(self.global_position + GameManager.player_dir)
		
func _on_card_effect_3() -> void: 
	#only use when it's not exist
	if enabled == false :
		dmg = dice.roulette()
		self.visible = true
		self.monitorable = true
		self.monitoring = true
		is_shoot = true
		timer.start()
		anim_player.play("lazer")
		enabled = true
		DeckManager.add_card("card3", -1)
		audio.play()

#card effect off
func _timeout() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	is_shoot = false
	enabled = false
