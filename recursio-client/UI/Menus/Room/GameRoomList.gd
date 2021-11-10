extends ItemList
class_name GameRoomList


func add_room_item(room_id, room_name):
	add_item(room_name)
	set_item_metadata(get_item_count() - 1, room_id)


func filter_by(filter_text):
	pass
