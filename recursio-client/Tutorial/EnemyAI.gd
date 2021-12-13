extends Node
class_name EnemyAI

var waypoint_reach_distance: float = 0.1

# Enemy instance to control
var _enemy: Enemy
var _waypoints := []
var _current_waypoint: int = 0

var _character_to_shoot: CharacterBase
var _shoot_timer: float = 2.0
var _shoot_cooldown: float = 3.0
var _rotation_lerp: float = 0.1

var _is_running: bool = false

onready var _range = Constants.get_value("hitscan", "range")


func _init(enemyToControl: Enemy):
	_enemy = enemyToControl


func _physics_process(delta):
	if not _is_running:
		return
	
	var character_pos = Vector2(_character_to_shoot.get_position().x, _character_to_shoot.get_position().z)
	var enemy_pos = Vector2(_enemy.get_position().x, _enemy.get_position().z)
	
	var movement: Vector3
	var rotation: Vector3
	var buttons: int = 0
	
	if _current_waypoint < _waypoints.size():
		var current_waypoint: Vector2 = _waypoints[_current_waypoint]
		var direction = current_waypoint - enemy_pos
		movement = Vector3(direction.x, 0, direction.y)
		
		# If the waypoint is reached, go to next one
		if enemy_pos.distance_to(current_waypoint) <= waypoint_reach_distance:
			_current_waypoint += 1
		
	if _enemy.get_position().distance_to(_character_to_shoot.get_position()) <= _range:
		var diff = (character_pos - enemy_pos)
		var enemy_rotation = Vector2(_enemy.kb.rotation.x, _enemy.kb.rotation.z)
		enemy_rotation = lerp(enemy_rotation.normalized(), diff.normalized(), _rotation_lerp * delta)
		rotation = Vector3(enemy_rotation.x, 0, enemy_rotation.y)
		_shoot_timer += delta
		if _shoot_timer  >= _shoot_cooldown:
			_shoot_timer = 0
			buttons = 2
	
	_enemy.apply_input(movement.normalized(), rotation.normalized(), buttons)


func start() -> void:
	_is_running = true


func add_waypoint(position: Vector2) -> void:
	_waypoints.append(position)


func set_character_to_shoot(character: CharacterBase):
	_character_to_shoot = character
