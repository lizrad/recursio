extends Object
class_name DeathData

enum HitType {
	MELEE,
	HITSCAN,
	WALL
}

var hit_type
var hit_position
var hit_rotation

# in msecs passed since gamephase start
var time

var victim_team_id: int
var victim_round_index: int 
var victim_timeline_index: int

var perpetrator_team_id: int
var perpetrator_round_index: int 
var perpetrator_timeline_index: int
