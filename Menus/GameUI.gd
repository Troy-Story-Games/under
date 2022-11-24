extends HBoxContainer
class_name GameUI

onready var depthLabel = $"%DepthLabel"
onready var dirtLabel = $"%DirtLabel"
onready var livesLabel = $"%LivesLabel"


func set_depth(value: int):
    depthLabel.text = str(value) + " m"


func set_dirt(value: int):
    dirtLabel.text = str(value) + " d"


func set_lives(value: int):
    livesLabel.text = str(value)
