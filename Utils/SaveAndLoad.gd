extends Node

# Auto-load singleton to deal with
# saving and loading the game

const SAVE_FILE := "user://under_save_data.json"

var custom_data := {
    "version": "0.0.1",
    "high_scores": [],
    "game_completed": false,
    "completion_time": 0.0
}


func _ready():
    load_game()


func get_completion_time_str() -> String:
    var duration = custom_data.completion_time
    var mins: int = int(floor(duration / 60.0))
    var secs_fraction: float = float(duration / 60.0) - mins
    var secs: int = 0
    if secs_fraction > 0:
        secs = int(floor(60 * secs_fraction))

    return str(mins) + ":" + str(secs)


func save_game():
    var save_game := File.new()
    # warning-ignore:return_value_discarded
    save_game.open(SAVE_FILE, File.WRITE)
    save_game.store_line(to_json(custom_data))
    save_game.close()


func load_game():
    var save_game := File.new()
    if not save_game.file_exists(SAVE_FILE):
        return

    # warning-ignore:return_value_discarded
    save_game.open(SAVE_FILE, File.READ)

    if not save_game.eof_reached():
        custom_data = parse_json(save_game.get_line())

    save_game.close()


func record_score(name: String, depth: int, dirt: int) -> void:
    var record = {}
    record.name = name
    record.depth = depth
    record.dirt = dirt
    custom_data.high_scores.append(record)
