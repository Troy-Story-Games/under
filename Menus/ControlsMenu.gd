extends Control
class_name ControlsMenu

onready var backButton = $"%BackButton"

func _ready():
    backButton.grab_focus()


func _on_Button_pressed():
    # warning-ignore:return_value_discarded
     get_tree().change_scene("res://Menus/MainMenu.tscn")
