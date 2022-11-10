extends HBoxContainer
class_name GameUI

onready var depthLabel = $"%DepthLabel"
onready var dirtLabel = $"%DirtLabel"


func set_depth(value: int):
    depthLabel.text = str(value) + " m"


func set_dirt(value: int):
    dirtLabel.text = str(value) + " d"
