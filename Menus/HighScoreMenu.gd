extends Control
class_name HighScoreMenu


func _on_Timer_timeout() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/MainMenu.tscn")
