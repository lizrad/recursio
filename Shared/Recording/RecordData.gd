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
	for frame in record_data.record_frames:
		record_frames.append(RecordFrame.new().copy(frame))
	return self


func add(record_frame: RecordFrame) -> void:
	record_frames.append(record_frame)


# Fills the object with the data from the given array
func from_array(data: Array)-> RecordData:
	timestamp = data[0]
	timeline_index = data[1]
	for i in range(2, data.size()):
		record_frames.append(RecordFrame.new().from_array(data[i]))
	return self


# Converts this class into an array
func to_array()-> Array:
	var array := [timestamp, timeline_index]
	for i in range(record_frames.size()):
		array.append(record_frames[i].to_array())
	return array
