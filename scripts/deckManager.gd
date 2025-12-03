extends Node

var card_inventory: Dictionary = {}

#add card
func add_card(card_id: String, amount: int = 1):
	if card_inventory.has(card_id):
		card_inventory[card_id] += amount
	else:
		card_inventory[card_id] = amount
		
	print("카드 획득! ", card_id, ": ", card_inventory[card_id], "개")

#amount of ids
func count_id() -> int :
	var total_card_types = 0
	for card_id in card_inventory.keys() :
		if card_inventory[card_id] != 0 :
			total_card_types += 1
	return total_card_types

#remove keys have value 0 at deck
func cleanup_inventory():
	var keys_to_remove = []
	
	for card_id in card_inventory.keys():
		if card_inventory[card_id] == 0:
			keys_to_remove.append(card_id)
	
	for card_id in keys_to_remove:
		card_inventory.erase(card_id)
