extends Control
class_name HighScoreMenu

var MAX_TO_DISPLAY = 10

var high_scores = []
var high_score_text = ""
onready var label = $"%TextEdit"
onready var mainMenuButton = $"%MainMenuButton"
onready var hSep = $"%HSeparator"
onready var completionTimeLabel = $"%CompletedGameTime"


class CustomSorter:
    static func sort_descending(a, b):
        if a.depth > b.depth:
            return true
        return false


func _ready():
    hSep.visible = false
    completionTimeLabel.visible = false
    if SaveAndLoad.custom_data.game_completed:
        hSep.visible = true
        completionTimeLabel.visible = true
        completionTimeLabel.text = "Main Game Completed!\nTime: " + str(SaveAndLoad.custom_data.completion_time / 60.0) + " mins"

    mainMenuButton.grab_focus()
    high_scores = SaveAndLoad.custom_data.high_scores
    high_score_text = "   NAME  |   DEPTH   |   DIRT\n"
    process_high_scores()


func process_high_scores():
    var count = 0
    high_scores.sort_custom(CustomSorter, "sort_descending")

    for score in high_scores:
        var name = score.name
        var depth = score.depth
        var dirt = score.dirt
        high_score_text += str(count + 1) + ". " + name + "   |  " + str(int(depth)) + "  M  |  " + str(int(dirt)) + " D\n"
        count += 1
        if count >= MAX_TO_DISPLAY:
            break

    label.text = high_score_text


func _on_MainMenuButton_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/MainMenu.tscn")
