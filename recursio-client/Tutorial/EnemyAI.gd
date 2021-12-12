extends Node
class_name EnemyAI

var waypoint_reach_distance: float = 0.1

# Enemy instance to control
var _enemy: Enemy
var _waypoints := []
var _current_waypoint: int = 0


var _is_running: bool = false


func _init(enemyToControl: Enemy):
	_enemy = enemyToControl


func _physics_process(delta):
	if not _is_running || _current_waypoint >= _waypoints.size():
		return
	
	var current_waypoint: Vector3 = _waypoints[_current_waypoint]
	
	var direction = current_waypoint - _enemy.get_position()
	var movement: Vector3 = Vector3(direction.x, 0, direction.z)
	_enemy.apply_input(movement.normalized(), Vector3.FORWARD, 0)
	
	# If the waypoint is reached, go to next one
	if _enemy.get_position().distance_to(current_waypoint) <= waypoint_reach_distance:
		_current_waypoint += 1


func add_waypoint(position: Vector3) -> void:
	_waypoints.append(position)


func start() -> void:
	_is_running = true
