extends CenterContainer
class_name MainMenu

var little_guy_start_x = 0

onready var playButton = $"%Play"
onready var dirtSpawner = $DirtSpawner
onready var dirtSpawner2 = $DirtSpawner2
onready var dirtStopTimer = $DirtStopTimer
onready var littleGuy = $MainMenuLittleGuy



func _ready() -> void:
    playButton.grab_focus()
    dirtStopTimer.start()
    little_guy_start_x = littleGuy.global_position.x


func _on_Play_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Game.tscn")


func _on_Options_pressed() -> void:
    print("Options pressed")


func _on_Quit_pressed() -> void:
    get_tree().quit()


func _on_DirtStopTimer_timeout() -> void:
    dirtSpawner.stop()
    dirtSpawner2.stop()
    littleGuy.start()


func _on_MainMenuLittleGuy_stopped():
    littleGuy.global_position.x = little_guy_start_x
    dirtSpawner.start()
    dirtSpawner2.start()
    dirtStopTimer.start()
