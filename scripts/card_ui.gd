extends Control

@onready var card_grid = $"."

#이부분은 나중에 경로 수정 필수
@onready var card1_effect_node = $"../../../../Y_Sort/Player/Effects/card1_effect"
@onready var card2_effect_node = $"../../../../Y_Sort/Player/Effects/card2_effect"
@onready var card3_effect_node = $"../../../../Y_Sort/Player/Effects/card3_effect"
@onready var card4_effect_node = $"../../../../Y_Sort/Player/Effects/card4_effect"
@onready var card5_effect_node = $"../../../../Y_Sort/Player/Effects/card5_effect"
@onready var card6_effect_node = $"../../../../Y_Sort/Player/Effects/card6_effect"

const CARD_TEMPLATE = preload("res://Scenes/card.tscn")

const CARD1_TEXTURE = preload("res://img/card/card1.png")
const CARD2_TEXTURE = preload("res://img/card/card2.png")
const CARD3_TEXTURE = preload("res://img/card/card3.png")
const CARD4_TEXTURE = preload("res://img/card/card4.png")
const CARD5_TEXTURE = preload("res://img/card/card5.png")
const CARD6_TEXTURE = preload("res://img/card/card6.png")

var degree
var length
var card_rotation
var card_position_x
var card_position_y

#update card slot
func _update_ui():
	
	#--------------card ui init-----------------
	var count_id = DeckManager.count_id()
	degree = 180 / (count_id + 1)
	
	length = 50
	
	card_rotation = degree - 90
	card_position_x = cos(deg_to_rad(90 - card_rotation)) * length
	card_position_y = sin(deg_to_rad(90 - card_rotation)) * length
	#-------------/card ui init------------------
	
	#---------------ui reset----------------
	for child in card_grid.get_children():
		child.queue_free()
	#--------------/ui reset----------------
	
	
	for card_id in DeckManager.card_inventory.keys():
		var count = DeckManager.card_inventory[card_id]
		
		var newCard = CARD_TEMPLATE.instantiate()
		
		if card_id == "card1" :
			newCard.icon = CARD1_TEXTURE
			newCard.connect("effect1", Callable(card1_effect_node, "_on_card_effect_1"))
			init_card(1, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			change_degree()
			
		elif card_id == "card2" :
			newCard.icon = CARD2_TEXTURE
			newCard.connect("effect2", Callable(card2_effect_node, "_on_card_effect_2"))
			init_card(2, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			change_degree()
			
		elif card_id == "card3" :
			newCard.icon = CARD3_TEXTURE
			newCard.connect("effect3", Callable(card3_effect_node, "_on_card_effect_3"))
			init_card(3, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			change_degree()
			
		elif card_id == "card4" :
			newCard.icon = CARD4_TEXTURE
			newCard.connect("effect4", Callable(card4_effect_node, "_on_card_effect_4"))
			init_card(4, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			change_degree()
		
		elif card_id == "card5" :
			newCard.icon = CARD5_TEXTURE
			newCard.connect("effect5", Callable(card5_effect_node, "_on_card_effect_5"))
			init_card(5, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			change_degree()
			
		elif card_id == "card6" :
			newCard.icon = CARD6_TEXTURE
			newCard.connect("effect6", Callable(card6_effect_node, "_on_card_effect_6"))
			init_card(6, newCard, card_position_x, card_position_y, deg_to_rad(card_rotation))
			
			change_degree()
		
#make card in UI
func init_card(id, newCard, x, y, r) :
	newCard.position.x += x
	newCard.position.y -= y
	newCard.rotation = r
	newCard.type = id
	card_grid.add_child(newCard)
	newCard.edit_count_label()
	
#adjust card position
func change_degree() :
	card_rotation += degree
	card_position_x = cos(deg_to_rad(90 - card_rotation)) * length
	card_position_y = sin(deg_to_rad(90 - card_rotation)) * length

func _on_button_pressed() -> void:
	DeckManager.add_card("card1", 1)
	_update_ui()

func _on_button_2_pressed() -> void:
	DeckManager.add_card("card2", 1)
	_update_ui()

func _on_button_3_pressed() -> void:
	DeckManager.add_card("card3", 1)
	_update_ui()

func _on_button_4_pressed() -> void:
	DeckManager.add_card("card4", 1)
	_update_ui()

func _on_button_5_pressed() -> void:
	DeckManager.add_card("card5", 1)
	_update_ui()

func _on_button_6_pressed() -> void:
	DeckManager.add_card("card6", 1)
	_update_ui()
