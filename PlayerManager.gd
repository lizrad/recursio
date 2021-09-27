extends Spatial

var _player_scene = preload("res://Players/Player.tscn")
var _enemy_scene = preload("res://Players/Enemy.tscn")
var player
var enemies = {}

func _ready():
	Server.connect("spawning_player",self ,"spawn_player")
	Server.connect("spawning_enemy",self ,"spawn_enemy")

func spawn_player(spawn_point):
	player = spawn_character(_player_scene,spawn_point)
	
func spawn_enemy(enemy_id, spawn_point):
	var enemy = spawn_character(_enemy_scene,spawn_point)
	enemy.set_name(str(enemy_id))
	enemies[enemy_id]=enemy
	
func spawn_character(character_scene,spawn_point):
	var character = character_scene.instance()
	character.transform.origin = spawn_point
	add_child(character)
	return character
