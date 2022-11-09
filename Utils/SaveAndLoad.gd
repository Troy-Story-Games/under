extends Node

# Auto-load singleton to deal with
# saving and loading the game

const SAVE_FILE := "user://under_save_data.json"

var custom_data := {
    # TODO: Store custom data here. This will be saved to the file first.
    "version": "0.0.1"
}


func _ready():
    # (OPTIONAL) Have the game load on _ready()
    load_game()


func save_game():
    var save_game := File.new()
    # warning-ignore:return_value_discarded
    save_game.open(SAVE_FILE, File.WRITE)
    save_game.store_line(to_json(custom_data))

    var persisting_nodes := get_tree().get_nodes_in_group("Persists")
    for node in persisting_nodes:
        var node_data : Node = node.save()
        save_game.store_line(to_json(node_data))

    save_game.close()


func load_game():
    var save_game := File.new()
    if not save_game.file_exists(SAVE_FILE):
        return

    # warning-ignore:return_value_discarded
    save_game.open(SAVE_FILE, File.READ)

    if not save_game.eof_reached():
        custom_data = parse_json(save_game.get_line())

    # We're going to re-add them based on the save file
    var persistingNodes := get_tree().get_nodes_in_group("Persists")
    for node in persistingNodes:
        node.queue_free()

    while not save_game.eof_reached():
        var current_line := save_game.get_line()
        if current_line == "":
            continue

        var node_obj : Dictionary = parse_json(current_line)
        if node_obj == null:
            continue

        # Saved nodes must have a filename and parent
        # They may have an optional position
        assert("filename" in node_obj)
        assert("parent" in node_obj)

        # warning-ignore:unsafe_method_access
        var new_node : Node2D = load(node_obj["filename"]).instance()
        get_node(node_obj["parent"]).add_child(new_node, true)

        if "position" in node_obj:
            var x_pos : float = node_obj["position"]["x_pos"]
            var y_pos : float = node_obj["position"]["y_pos"]
            new_node.position = Vector2(x_pos, y_pos)

        for prop in node_obj.keys():
            if prop in ["parent", "position", "filename"]:
                continue

            new_node.set(prop, node_obj[prop])

        # TODO: Any other logic needed to load a line from the save file

    save_game.close()







