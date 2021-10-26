extends VBoxContainer


func _ready():
	$TopBar/LineEdit.connect("text_changed", self, "_on_filter_text_changed")


func _on_filter_text_changed(new_text):
	$RoomList.filter_by(new_text)
