extends CenterContainer
class_name WinMenu

onready var timeLabel = $"%TimeLabel"
onready var button = $"%Button"


func _ready():
    button.grab_focus()
    timeLabel.text = "Time: " + SaveAndLoad.get_completion_time_str()


func _on_Button_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/MainMenu.tscn")
