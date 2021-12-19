extends ActionManager


var action_icons = {
	action_resources[ActionType.HITSCAN].name: preload("res://Resources/Icons/bullet.png"),
	action_resources[ActionType.WALL].name: preload("res://Resources/Icons/wall.png")
}

var action_sounds = {
	action_resources[ActionType.HITSCAN].name: preload("res://Resources/Audio/Effects/Shoot.ogg"),
	action_resources[ActionType.WALL].name: preload("res://Resources/Audio/Effects/PlaceWall.ogg"),
	action_resources[ActionType.DASH].name: preload("res://Resources/Audio/Effects/Dash.ogg"),
	action_resources[ActionType.MELEE].name: preload("res://Resources/Audio/Effects/Shoot.ogg")
}


func get_img_bullet_for_trigger(trigger, timeline_index):
	return action_icons[get_action_for_trigger(trigger, timeline_index).name]


func set_active(action: Action, character: CharacterBase, tree_position: Spatial, action_scene_parent: Node) -> bool:
	var success = .set_active(action, character, tree_position, action_scene_parent)
	
	if success and action_sounds.has(action.name):
		var audio_player = AudioStreamPlayer3D.new()
		audio_player.stream = action_sounds[action.name]
		audio_player.bus = "Effects"
		get_tree().get_root().add_child(audio_player)
		audio_player.global_transform = tree_position.global_transform
		audio_player.unit_size = 20
		audio_player.connect("finished", audio_player, "queue_free")
		audio_player.play()
	
	return success
