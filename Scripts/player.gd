extends CharacterBody2D
class_name Player

# ==============================
# Basic Stats
# ==============================
@export var speed = 200.0
@export var max_hp: int = 1000
var hp: int = max_hp
var exp = 10

# ==============================
# Node References
# ==============================
@onready var anim = $AnimatedSprite2D
@onready var dmg_delayer = $dmgTimer     # Prevents instant repeated damage
@onready var dot_delayer = $dotTimer     # Damage over time timer

# ==============================
# State Flags
# ==============================
var is_left = false          # Current facing direction
var is_turning = false       # Playing turn animation
var is_attacked = false      # Currently in hit state
var is_alive = true
var is_swamped = false       # Standing in swamp (DOT)
var is_poisoned = false      # Standing in poison (DOT)

var direction: Vector2       # Player's direction for game manager

# ==============================
# Signals
# ==============================
signal hp_changed(hp)

func _ready() -> void:
	# Notify UI with initial HP
	hp_changed.emit(hp)

func _physics_process(delta: float) -> void:
	# Do nothing while the game is paused
	if GameManager.is_paused:
		return

	# 8-ways movement
	direction = Input.get_vector("Left", "Right", "Up", "Down")
	GameManager.player_dir = direction

	# If not moving, keep facing direction
	if direction.length() == 0:
		if is_left:
			GameManager.player_dir = Vector2(-1, 0)
		else:
			GameManager.player_dir = Vector2(1, 0)

	velocity = direction * speed

	if hp > 0:
		update_animation(direction)

		# Disable movement while being attacked
		if not is_attacked:
			move_and_slide()
	elif is_alive:
		# Death handling
		anim.play("Death")
		is_alive = false
		GameManager.is_end = true

		if not anim.is_playing():
			queue_free()

# ==============================
# Animation Control
# ==============================
func update_animation(dir: Vector2) -> void:
	# Ignore animation changes during hit or turning animation
	if is_attacked or is_turning:
		return

	# Idle
	if dir.length() <= 0.1:
		anim.play("Idle")
		return

	# Turning logic
	if dir.x != 0:
		var going_left = dir.x < 0
		if going_left != is_left:
			start_turn(going_left)
			return

	anim.flip_h = is_left
	anim.play("Run")

func start_turn(going_left: bool) -> void:
	is_turning = true
	is_left = going_left

	# Flip sprite temporarily for turn animation
	anim.flip_h = !going_left
	anim.play("RunTurn")

	# Slow down during turn animation
	speed -= 80.0
	anim.animation_finished.connect(_on_turn_finished, CONNECT_ONE_SHOT)

func _on_turn_finished() -> void:
	is_turning = false
	anim.flip_h = is_left
	speed += 80.0
	anim.play("Run")

# ==============================
# Healing
# ==============================
func cure(heal: int) -> void:
	hp = min(hp + heal, max_hp)
	hp_changed.emit(hp)

# ==============================
# Direct Damage Handling
# ==============================
func take_damage(dmg: int) -> void:
	# Ignore damage while paused
	if GameManager.is_paused:
		return

	# Prevent damage stacking
	if not is_attacked:
		is_attacked = true
		dmg_delayer.start()

		hp -= dmg * 10
		if hp <= 0:
			hp = 0
		else:
			anim.play("Hurt")
			anim.animation_finished.connect(_on_hurt_finished, CONNECT_ONE_SHOT)

		hp_changed.emit(hp)

func _on_hurt_finished() -> void:
	is_attacked = false

func _on_dmg_timeout() -> void:
	is_attacked = false

# ==============================
# Damage Over Time (DOT)
# ==============================
func _on_dot_timeout() -> void:
	if GameManager.is_paused:
		return

	if is_swamped:
		hp -= 10
		if hp <= 0:
			hp = 0
			return

		# Green flash
		anim.modulate = Color(0.3, 1.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color.WHITE

	elif is_poisoned:
		hp -= 15
		if hp <= 0:
			hp = 0
			return

		# Purple flash
		anim.modulate = Color(0.3, 0.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color.WHITE

	hp_changed.emit(hp)

# ==============================
# Trap Detection
# ==============================
func _on_trap_checker_body_entered(body: Node2D) -> void:
	if GameManager.is_paused:
		return

	if body.name == "Swamp":
		is_swamped = true
		if dot_delayer.is_stopped():
			dot_delayer.start()

		hp -= 10
		hp = max(hp, 0)

		anim.modulate = Color(0.3, 1.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color.WHITE

	elif body.name == "Pollution":
		is_poisoned = true
		if dot_delayer.is_stopped():
			dot_delayer.start()

		hp -= 15
		hp = max(hp, 0)

		anim.modulate = Color(0.3, 0.0, 0.3)
		await get_tree().create_timer(0.35).timeout
		anim.modulate = Color.WHITE

	hp_changed.emit(hp)

func _on_trap_checker_body_exited(body: Node2D) -> void:
	if GameManager.is_paused:
		return

	if body.name == "Swamp":
		is_swamped = false
		dot_delayer.stop()
	elif body.name == "Pollution":
		is_poisoned = false
		dot_delayer.stop()

	
#temp code
func _on_button_pressed() -> void: 
	GameManager.pause_toggle()
