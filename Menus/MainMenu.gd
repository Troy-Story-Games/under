extends CenterContainer
class_name MainMenu

var little_guy_start_x = 0

onready var playButton = $"%Play"
onready var littleGuyTimer = $LittleGuyStartTimer
onready var littleGuy = $MainMenuLittleGuy
onready var mouse = $Mouse


func _ready() -> void:
    playButton.grab_focus()
    littleGuyTimer.start()
    little_guy_start_x = littleGuy.global_position.x


func _process(_delta):
    var mouse_pos = get_global_mouse_position()
    mouse.global_position = mouse_pos


func _on_Play_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Game.tscn")


func _on_Options_pressed() -> void:
    print("Options pressed")


func _on_Quit_pressed() -> void:
    get_tree().quit()


func _on_MainMenuLittleGuy_stopped():
    littleGuy.global_position.x = little_guy_start_x
    littleGuyTimer.start()


func _on_LittleGuyStartTimer_timeout():
    littleGuy.start()
