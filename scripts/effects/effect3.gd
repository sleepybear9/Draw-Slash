extends Area2D

@onready var timer = $Timer
@onready var anim_player = $AnimationPlayer
@onready var cover = $CoverArea
@onready var dice = $"../dice"
@onready var audio = $AudioStreamPlayer2D

var enabled : bool = false
var dmg : int
var is_shoot = false

var last_player_dir: Vector2 = Vector2.ZERO 
const ANGLE_OFFSET = deg_to_rad(22.5) 

func _ready() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false
	cover.monitorable = false
	cover.monitoring = false

	timer.connect("timeout", Callable(self, "_timeout"))

# Shoot laser
func _physics_process(delta: float) -> void:
	if is_shoot:
		look_at(self.global_position + GameManager.player_dir)
		
		# Check if player direction changed
		if GameManager.player_dir != last_player_dir:
			# Enable the sweep_area(cover) for diagonal or in-between directions
			cover.monitorable = true
			cover.monitoring = true
			
			var angle_change = last_player_dir.angle_to(GameManager.player_dir)
			
			if angle_change > 0:
				cover.rotation = -ANGLE_OFFSET
			else:
				cover.rotation = ANGLE_OFFSET
			
			cover.rotation -= ANGLE_OFFSET
			last_player_dir = GameManager.player_dir
		else:
			cover.monitorable = false
			cover.monitoring = false

func _on_card_effect_3() -> void:
	# Only use when it's not exist
	if enabled == false :
		dmg = dice.roulette()
		
		last_player_dir = GameManager.player_dir
		cover.rotation = -ANGLE_OFFSET
		
		self.visible = true
		self.monitorable = true
		self.monitoring = true
		
		is_shoot = true
		timer.start()
		
		anim_player.play("lazer")
		enabled = true
		DeckManager.add_card("card3", -1)
		audio.play()
		
# Card effect off
func _timeout() :
	self.visible = false
	self.monitorable = false
	self.monitoring = false

	cover.monitorable = false
	cover.monitoring = false
	cover.rotation = 0.0 
	
	is_shoot = false
	enabled = false  


func _on_area_entered(area: Area2D) -> void:
	if area.name == "attackrange": 
		var monster = area.get_parent()
		monster.take_damage(dmg)
