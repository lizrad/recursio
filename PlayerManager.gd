extends Spatial

var player_scene = preload("res://Players/Player.tscn")
var player

func _ready():
	Server.connect("spawning_player",self ,"spawn_player")

func spawn_player(spawn_point):
	print("Spawning Player")
	player = player_scene.instance()
	player.transform.origin = spawn_point
	add_child(player)
