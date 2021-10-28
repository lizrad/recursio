extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(20):
		add_room_item("Room Name " + str(i), i)


func add_room_item(room_name, room_id):
	add_item(room_name)
	set_item_metadata(get_item_count() - 1, room_id)


func filter_by(filter_text):
	pass
