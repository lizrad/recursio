extends Object
class_name RecordFrame

var timestamp: int = -1
var position: Vector3 = Vector3.ZERO
var rotation_y: float = -1
var buttons: int = -1

func copy(data: RecordFrame):
	timestamp = data.timestamp
	position = data.position
	rotation_y = data.rotation_y
	buttons = data.buttons
	return self

func from_array(data: Array) -> RecordFrame:
	timestamp = data[0]
	position = data[1]
	rotation_y = data[2]
	buttons = data[3]
	return self


func to_array() -> Array:
	return [timestamp, position, rotation_y, buttons]
