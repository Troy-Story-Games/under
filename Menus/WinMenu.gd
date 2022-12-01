extends CenterContainer
class_name WinMenu

onready var timeLabel = $"%TimeLabel"
onready var button = $"%Button"


func _ready():
    button.grab_focus()
    timeLabel.text = "Time: " + str(SaveAndLoad.custom_data.completion_time / 60.0) + "mins"


func _on_Button_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/MainMenu.tscn")
