extends Spatial

onready var server = get_node("/root/Server")
var player_scene = preload("res://Players/Player.tscn")
var player

func _ready():
	server.connect("spawning_player",self ,"spawn_player")

func spawn_player():
	print("Spawning Player")
	player = player_scene.instance()
	add_child(player)
