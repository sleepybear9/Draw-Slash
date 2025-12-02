extends Area2D

@onready var timer = $Timer
@onready var anim_player = $AnimationPlayer

@onready var dice = $"../dice"

var enabled : bool = false

var dmg : int

var is_shoot = false

func _ready() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	timer.connect("timeout", Callable(self, "_timeout"))

#card effect on
func _physics_process(delta: float) -> void:
	if is_shoot:
		look_at(self.global_position + GameManager.player_dir)
		
func _on_card_effect_3() -> void: 
	if enabled == false :
		dmg = dice.roulette()
		self.visible = true
		self.monitorable = true
		self.monitoring = true
		#여기 direction 수정 필요
		is_shoot = true
		timer.start()
		anim_player.play("lazer")
		enabled = true
		DeckManager.add_card("card3", -1)

#card effect off
func _timeout() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	is_shoot = false
	enabled = false
