extends Spatial


onready var _parent = get_parent().get_parent() as CharacterBase


# Called when the node enters the scene tree for the first time.
func _ready():
	_parent.connect("spawning", self, "_on_spawn")
	_parent.connect("dying", self, "_on_die")


func _on_spawn():
	$SpawnAudio.play()


func _on_die():
	$DieAudio.play()


func _process(delta):
	$MoveAudio.unit_size = min(_parent.velocity.length() * 1.5, 6.75)
