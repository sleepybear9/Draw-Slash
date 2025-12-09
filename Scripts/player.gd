extends CharacterBody2D

class_name Player 

@export var speed = 200.0
@export var max_hp: int = 1000
var hp: int = max_hp
@export var mp = 100

@onready var anim = $AnimatedSprite2D
@onready var dmg_delayer = $dmgTimer
@onready var dot_delayer = $dotTimer

var is_left = false
var is_turning = false
var is_attacked = false
var is_alive = true
var direction
var is_swamped = false
var is_poisoned = false
var is_setting = false

signal hp_changed (hp)

func _ready() -> void:
	hp_changed.emit(hp)	
	

func _physics_process(delta: float) -> void:
	if GameManager.is_paused: return
	
	direction = Input.get_vector("Left","Right","Up","Down")
	GameManager.player_dir = direction
	if direction.length() == 0:
		if is_left:
			GameManager.player_dir = Vector2(-1, 0)
		else :
			GameManager.player_dir = Vector2(1, 0)
	
	velocity = direction * speed

	if hp > 0:
		update_animation(direction)
		if !is_attacked: move_and_slide()
	elif is_alive:
		anim.play("Death")
		is_alive = false
		GameManager.is_end = true
		if !anim.is_playing():
			queue_free()

func update_animation(dir: Vector2) -> void:
	if is_attacked:
		return

	if is_turning:
		return

	if dir.length() <= 0.1:
		anim.play("Idle")
		return

	if dir.x != 0:
		var going_left = dir.x < 0
		if going_left != is_left:
			start_turn(going_left)
			return

	anim.flip_h = is_left
	#anim.play("Walk")
	anim.play("Run")


func start_turn(going_left: bool) -> void:
	is_turning = true
	is_left = going_left

	anim.flip_h = !going_left

	#anim.play("WalkTurn")
	anim.play("RunTurn")
	speed -= 80.0
	anim.animation_finished.connect(_on_turn_finished, CONNECT_ONE_SHOT)


func _on_turn_finished() -> void:
	is_turning = false
	anim.flip_h = is_left
	speed += 80.0
	
	#anim.play("Walk")
	anim.play("Run")

func cure(heal: int) -> void:
	hp = min(hp+ heal, max_hp)
	hp_changed.emit(hp)
	

func take_damage(dmg: int) -> void:
	print(GameManager.is_paused)
	if GameManager.is_paused: return
	
	if !is_attacked:
		is_attacked = true
		dmg_delayer.start()
		
		hp -= dmg*10
		if hp <= 0:
			hp = 0
		else:
			anim.play("Hurt")
			anim.animation_finished.connect(_on_hurt_finished, CONNECT_ONE_SHOT)
		#print(hp)
		hp_changed.emit(hp)
			

func _on_hurt_finished() -> void:
	is_attacked = false

func _on_dmg_timeout() -> void:
	is_attacked = false
	
func _on_dot_timeout() -> void:
	if GameManager.is_paused: return
	if is_swamped:
		hp -= 10
		if hp <= 0:
			hp = 0
		#print(hp)
		if hp == 0: return
		
		anim.modulate = Color(0.3, 1.0, 0.3) 
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color(1,1,1)
	elif is_poisoned:
		print("dot")
		hp -= 15
		if hp <= 0:
			hp = 0
		#print(hp)
		if hp == 0: return
		
		anim.modulate = Color(0.3, 0.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color(1,1,1)
	hp_changed.emit(hp)
	

func _on_trap_checker_body_entered(body: Node2D) -> void:
	if GameManager.is_paused: return
	if body.name == "Swamp":
		is_swamped = true
		if dot_delayer.is_stopped():
			dot_delayer.start()
		hp -= 10
		if hp <= 0:
			hp = 0
		print(hp)
	
		anim.modulate = Color(0.3, 1.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color(1,1,1)
	elif body.name == "Pollution":
		is_poisoned = true
		if dot_delayer.is_stopped():
			dot_delayer.start()
		hp -= 15
		if hp <= 0:
			hp = 0
		print("first", hp)
		
	
		anim.modulate = Color(0.3, 0.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color(1,1,1)
	hp_changed.emit(hp)


func _on_trap_checker_body_exited(body: Node2D) -> void:
	if GameManager.is_paused: return
	if body.name == "Swamp":
		is_swamped = false
		dot_delayer.stop()
	elif body.name == "Pollution":
		is_poisoned = false
		dot_delayer.stop()
	


func _on_button_pressed() -> void:
	GameManager.pause_toggle()
