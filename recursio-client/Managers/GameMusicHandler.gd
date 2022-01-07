extends Node


export var round_manager_path: NodePath
onready var round_manager: RoundManager = get_node(round_manager_path)


func _ready():
	var error = round_manager.connect("game_phase_started", self, "play_game_music")
	assert(error == OK)


func play_game_music():
	$AudioStreamPlayer.play()
