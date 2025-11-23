extends Control

@onready var card_grid = $"."
@onready var deck_manager = $"/root/DeckManager"

#이부분은 나중에 경로 수정 필수
@onready var card1_effect_node = $"../player/card1_effect"
@onready var card2_effect_node = $"../player/card2_effect"
@onready var card3_effect_node = $"../player/card3_effect"

const CARD_TEMPLATE = preload("res://Scenes/card.tscn")

const CARD1_TEXTURE = preload("res://img/card/card1.png")
const CARD2_TEXTURE = preload("res://img/card/card2.png")
const CARD3_TEXTURE = preload("res://img/card/card3.png")

#update card slot
func _update_ui():
	
	#--------------card ui init-----------------
	var count_id = deck_manager.count_id()
	var degree = 180 / (count_id + 1)
	
	var length = 50
	
	var card_rotation = degree - 90
	var card_position_x = cos(deg_to_rad(90 - card_rotation)) * length
	var card_position_y = sin(deg_to_rad(90 - card_rotation)) * length
	#-------------/card ui init------------------
	
	#---------------ui reset----------------
	for child in card_grid.get_children():
		child.queue_free()
	#--------------/ui reset----------------
	
	
	for card_id in deck_manager.card_inventory.keys():
		var count = deck_manager.card_inventory[card_id]
		
		var newCard = CARD_TEMPLATE.instantiate()
		
		if card_id == "card1" :
			newCard.icon = CARD1_TEXTURE
			newCard.connect("effect1", Callable(card1_effect_node, "_on_card_effect_1"))
			init_card(1, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			card_rotation += degree
			card_position_x = cos(deg_to_rad(90 - card_rotation)) * length
			card_position_y = sin(deg_to_rad(90 - card_rotation)) * length
			
		elif card_id == "card2" :
			newCard.icon = CARD2_TEXTURE
			newCard.connect("effect2", Callable(card2_effect_node, "_on_card_effect_2"))
			init_card(2, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			card_rotation += degree
			card_position_x = cos(deg_to_rad(90 - card_rotation)) * length
			card_position_y = sin(deg_to_rad(90 - card_rotation)) * length
			
		elif card_id == "card3" :
			newCard.icon = CARD3_TEXTURE
			newCard.connect("effect3", Callable(card3_effect_node, "_on_card_effect_3"))
			init_card(3, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			card_rotation += degree
			card_position_x = cos(deg_to_rad(90 - card_rotation)) * length
			card_position_y = sin(deg_to_rad(90 - card_rotation)) * length
		
func init_card(id, newCard, x, y, r) :
	newCard.position.x += x
	newCard.position.y -= y
	newCard.rotation = r
	newCard.type = id
	card_grid.add_child(newCard)
	newCard.edit_count_label()

func _on_button_pressed() -> void:
	deck_manager.add_card("card1", 1)
	_update_ui()

func _on_button_2_pressed() -> void:
	deck_manager.add_card("card2", 1)
	_update_ui()

func _on_button_3_pressed() -> void:
	deck_manager.add_card("card3", 1)
	_update_ui()
