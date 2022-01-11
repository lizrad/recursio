extends Reference
class_name RecordManager


onready var server: Server
var record_data: RecordData = RecordData.new()

func reset():
	record_data = RecordData.new()

func add_record_frame(position: Vector3, rotation_y: float, buttons: int) -> void:
	var record_frame: RecordFrame = RecordFrame.new()

	record_frame.timestamp = server.get_server_time()
	record_frame.position = position
	record_frame.rotation_y = rotation_y
	record_frame.buttons = buttons

	record_data.add(record_frame)
