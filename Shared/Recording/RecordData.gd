extends Object
class_name RecordData


var timestamp: int = -1
# The timeline this record data belongs to
var timeline_index: int = -1
# All record frames this data consists of (see RecordFrame.gd)
var record_frames: Array = []

func copy(record_data: RecordData) -> RecordData:
	timestamp = record_data.timestamp
	timeline_index = record_data.timeline_index
	# TODO: Check if this really copies the underlying RecordFrame(s)
	record_frames = record_data.record_frames.duplicate(true)
	return self


func add(record_frame: RecordFrame) -> void:
	record_frames.append(record_frame)
