extends Reference
class_name HitData

enum HitType {
	MELEE,
	HITSCAN,
	WALL
}

var type
var position: Vector3
var rotation: float

var victim_team_id: int
var victim_round_index: int 
var victim_timeline_index: int

var perpetrator_team_id: int
var perpetrator_round_index: int 
var perpetrator_timeline_index: int


# Converts this class into an array
func to_array()-> Array:
	var array := [
		type, 
		position, 
		rotation, 
		victim_team_id, 
		victim_round_index, 
		victim_timeline_index, 
		perpetrator_team_id, 
		perpetrator_round_index,
		perpetrator_timeline_index
		]
	return array


# Fills the object with the data from the given array
func from_array(data: Array)-> HitData:
	type = data[0]
	position = data[1]
	rotation = data[2]
	victim_team_id = data[3]
	victim_round_index = data[4]
	victim_timeline_index = data[5]
	perpetrator_team_id = data[6]
	perpetrator_round_index = data[7]
	perpetrator_timeline_index = data[8]
	return self

func to_string() -> String:
	var format_string = "TYPE:%s\nPOSITION:%s\nROTATION:%s\nVICTIM TEAM ID:%s\nVICTIM ROUND INDEX:%s\nVICTIM TIMELINE INDEX:%s\nPERPETRATOR TEAM ID:%s\nPERPETRATOR ROUND INDEX:%s\nPERPETRATOR TIMELINE INDEX:%s\n"
	var actual_string = format_string % to_array()
	return actual_string
