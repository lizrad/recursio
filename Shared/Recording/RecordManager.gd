extends Object
class_name RecordManager


var record_data: RecordData = RecordData.new()

func reset():
	record_data = RecordData.new()

func add_record_frame(position: Vector3, rotation_y: float, buttons: int, input_timestamp: int) -> void:
	var record_frame: RecordFrame = RecordFrame.new()
	
	record_frame.timestamp = input_timestamp
	record_frame.position = position
	record_frame.rotation_y = rotation_y
	record_frame.buttons = buttons
	
	record_data.add(record_frame)
