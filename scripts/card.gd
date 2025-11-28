extends Button

@onready var deck_manager = $"/root/DeckManager"
@onready var card_ui = $".."
@onready var count_label = $Sprite2D/Label
@onready var dice = $player/dice

var type : int

signal effect1()
signal effect2()
signal effect3()
signal effect4()
signal effect5()
signal effect6()

#send signal to each effect nodes
func _on_pressed() -> void:
	emit_signal("effect" + str(type))
		
	deck_manager.cleanup_inventory()
	card_ui._update_ui()
	
func edit_count_label() :
	var card_id : String = "card" + str(type)
	count_label.text = str(deck_manager.card_inventory[card_id])
