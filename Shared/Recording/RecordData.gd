extends Object
class_name RecordData

var timestamp: int = -1
var timeline_index: int = -1

var record_frames: Array = []

func copy(record_data: RecordData):
	timestamp = record_data.timestamp
	timeline_index = record_data.timeline_index
	# TODO: Check if this really copies the underlying RecordFrame(s)
	record_frames = record_data.record_frames.duplicate(true)
	return self
