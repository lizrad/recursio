extends ItemList
class_name GameRoomList


func add_game_room(game_room_id, game_room_name):
	add_item(game_room_name + "#" + str(game_room_id))
	set_item_metadata(get_item_count() - 1, game_room_id)


func get_selected_game_room() -> int:
	var selected_game_rooms = get_selected_items()
	if selected_game_rooms.size() == 0:
		return -1
	else:
		return get_item_metadata(selected_game_rooms[0])


func filter_by(filter_text):
	pass
