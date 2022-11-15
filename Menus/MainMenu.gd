extends CenterContainer
class_name MainMenu

onready var playButton = $"%Play"
onready var dirtSpawner = $DirtSpawner
onready var dirtSpawner2 = $DirtSpawner2

func _ready() -> void:
    playButton.grab_focus()


func _on_Play_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Game.tscn")


func _on_Options_pressed() -> void:
    pass # Replace with function body.


func _on_Quit_pressed() -> void:
    get_tree().quit()


func _on_DirtStopTimer_timeout() -> void:
    dirtSpawner.stop()
    dirtSpawner2.stop()
