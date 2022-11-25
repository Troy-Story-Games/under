extends CenterContainer
class_name GameOverMenu

var playerStats = Utils.get_player_stats()
var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
var input_array = []
var input_idx = 0
var input_done = false

onready var mainMenuButton = $"%MainMenuButton"
onready var depthLabel = $"%DepthLabel"
onready var dirtLabel = $"%DirtLabel"
onready var firstLetter = $"%FirstLetter"
onready var secondLetter = $"%SecondLetter"
onready var thirdLetter = $"%ThirdLetter"
onready var inputBlinkTimer = $InputBlinkTimer


func _ready():
    mainMenuButton.disabled = true
    mainMenuButton.grab_focus()
    dirtLabel.text = "Dirt: " + str(playerStats.dirt) + " d"
    depthLabel.text = "Depth: " + str(playerStats.depth) + " m"
    input_array = [
        {
            "letter_obj": firstLetter,
            "letter_idx": 0
        },
        {
            "letter_obj": secondLetter,
            "letter_idx": 0
        },
        {
            "letter_obj": thirdLetter,
            "letter_idx": 0
        }
    ]

func _process(_delta: float) -> void:
    if input_done:
        return

    var old_input_idx = input_idx
    if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_cancel"):
        input_idx = clamp(input_idx - 1, 0, len(input_array) - 1)
    elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_accept"):
        input_idx = clamp(input_idx + 1, 0, len(input_array) - 1)
        if old_input_idx == len(input_array) - 1:
            input_done = true
            mainMenuButton.disabled = false
            return

    var input = input_array[input_idx]

    if Input.is_action_just_pressed("ui_up"):
        input.letter_idx -= 1
    elif Input.is_action_just_pressed("ui_down"):
        input.letter_idx += 1

    if input.letter_idx >= len(alphabet):
        input.letter_idx = 0
    if input.letter_idx < 0:
        input.letter_idx = len(alphabet) - 1

    if old_input_idx != input_idx:
        var old_input = input_array[old_input_idx]
        var letter_obj: VBoxContainer = old_input.letter_obj
        var cursor: HSeparator = letter_obj.get_child(1) as HSeparator
        cursor.visible = true

    set_letter(input)


func set_letter(input):
    var letter_obj: VBoxContainer = input.letter_obj
    var letter: String = alphabet[input.letter_idx]
    var label: Label = letter_obj.get_child(0) as Label
    label.text = letter


func get_name():
    var name: String = ""
    for input in input_array:
        var letter_obj: VBoxContainer = input.letter_obj
        var label: Label = letter_obj.get_child(0) as Label
        name += label.text
    return name


func _on_MainMenuButton_pressed() -> void:
    SaveAndLoad.record_score(get_name(), playerStats.depth, playerStats.dirt)
    SaveAndLoad.save_game()
    playerStats.refill_stats()

    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/HighScoreMenu.tscn")


func _on_InputBlinkTimer_timeout() -> void:
    var input = input_array[input_idx]
    var letter_obj: VBoxContainer = input.letter_obj
    var cursor: HSeparator = letter_obj.get_child(1) as HSeparator
    if not input_done:
        cursor.visible = !cursor.visible
    else:
        cursor.visible = true
        inputBlinkTimer.stop()
