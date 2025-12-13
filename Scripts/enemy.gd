extends CharacterBody2D

var id: int
var speed: float = 70
var attack_distance: float = 100
var attack_cooldown: float = 1.0
var damage: int = 15
var hp: int = 40

@onready var player = $"../Player"
@onready var hidbox_shape = $attackrange/CollisionShape2D
var can_attack = true
var player_in_attack_area = false
var is_dead = false
var is_attacking = false
var is_damaging = false
var by_boss = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $attackrange
@onready var timer: Timer = $Timer
@onready var attack: Timer = $attack_term
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var types = [preload("res://Resource/monster/MutilatedStumbler.tres"), preload("res://Resource/monster/DecrepitBones.tres")]

func setup(mon_id: int):
	id = mon_id
	var select = types[id]
	anim.play(select.anim)
	hp = select.hp
	speed = select.speed
	damage = select.dmg
	is_dead = false
	by_boss = false
	attack_area.monitorable = true
	attack_area.monitoring = true
	modulate = Color(1, 1, 1) 

func _update_navigation_target():
	if player and not is_dead:
		nav_agent.target_position = player.global_position

func _physics_process(delta):
	if is_dead or not player: return
	
	if player.global_position.x - global_position.x > 0:
		anim.flip_h = false
	else:
		anim.flip_h = true
	
	if nav_agent.is_navigation_finished(): return
	var dist = global_position.distance_to(player.global_position)
	
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	
	var wanted_velocity = direction * speed
	nav_agent.velocity = wanted_velocity

func take_damage(amount: int):
	if is_dead: return
	hp -= amount
	
	modulate = Color.RED
	var tween = create_tween()
	if by_boss:
		tween.tween_property(self, "modulate", Color(0.5, 0.5, 1, 0.8), 0.2)
	else: 
		tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	if hp <= 0: _die()

func _die():
	if is_dead: return
	
	if by_boss: 
		$"../Boss"._on_minion_died()
		
	is_attacking = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)
	attack_area.monitorable = false
	attack_area.monitoring = false
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	hide()
	modulate.a = 1
	
	is_dead = true

func _velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func _on_attackrange_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox":
		is_attacking = true
		player.take_damage(damage)
		attack.start()
	elif area.is_in_group("attack"):
		#print("attacked by ", area.name)
		pass
		
func _on_attackrange_area_exited(area: Area2D) -> void:
	if area.name == "Hitbox":
		is_attacking = false
		attack.stop()

func try_attack() -> void:
	if is_attacking and !is_dead:
		player.take_damage(damage)

func _on_unstun():
	speed = types[id].speed
