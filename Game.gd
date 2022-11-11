extends Node
class_name MainGame

const Block = preload("res://World/Block.tscn")
const NUM_COLS = 12
const BLOCK_SIZE = 8
const BLOCK_SIZE_IN_METERS = 2

enum CaveCarving {
    NOT_CARVING,
    NEW_CAVE,
    CARVING
}

enum CaveType {
    H_LINE,
    V_LINE,
    BOX,
    GAP,
    V_TUNNEL,
    H_TUNNEL
}

export(int) var REGENERATE_BLOCK_THRESHOLD = 80
export(int) var ROW_BUFFER = 18
export(int) var CAVE_DEPTH = 24

onready var player = $Player
onready var leftWall = $LeftWall
onready var rightWall = $RightWall
onready var newRowSpawn = $NewRowSpawn
onready var gameUI = $Camera2D/CanvasLayer/GameUI

var playerStats: PlayerStats = Utils.get_player_stats()
var zero_depth: float = 0
var current_depth: float = 0
var cave_depth: float = 0
var cave_carve_pos = Vector2.ZERO
var cave_carve_type = CaveType.H_LINE
var cave_carve_state = CaveCarving.NOT_CARVING
var cave_type_data = {}


func _ready():
    player.connect("player_died", self, "_on_Player_player_died")
    # warning-ignore:return_value_discarded
    playerStats.connect("player_dirt_changed", self, "_on_PlayerStats_dirt_changed")
    gameUI.set_dirt(0)
    zero_depth = newRowSpawn.position.y
    cave_depth = zero_depth + (CAVE_DEPTH * BLOCK_SIZE)
    generate_more_blocks()


func _process(_delta: float) -> void:
    var y_pos : float = player.position.y
    leftWall.position.y = y_pos
    rightWall.position.y = y_pos

    if abs(newRowSpawn.global_position.y - player.global_position.y) < REGENERATE_BLOCK_THRESHOLD:
        generate_more_blocks(true)

    current_depth = (player.position.y - zero_depth) / float(BLOCK_SIZE)
    current_depth *= BLOCK_SIZE_IN_METERS
    gameUI.set_depth(ceil(current_depth))


func _on_PlayerStats_dirt_changed(value: int):
    gameUI.set_dirt(value)


func _on_Player_player_died():
    yield(get_tree().create_timer(1.0), "timeout")
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/GameOverMenu.tscn")


func should_place_block(pos: Vector2) -> bool:
    # Wait to make caves until we're initially deep enough
    if newRowSpawn.position.y < cave_depth:
        return true

    match cave_carve_state:
        CaveCarving.NOT_CARVING:
            return true
        CaveCarving.NEW_CAVE:
            var start_x_positions = []
            for idx in range(NUM_COLS):
                start_x_positions.push_back(pos.x + (idx * BLOCK_SIZE))
            start_x_positions.shuffle()

            var cave_types = CaveType.values()
            cave_types.shuffle()
            cave_carve_type = cave_types[0]
            cave_carve_pos = Vector2(start_x_positions[0], pos.y)
            cave_carve_state = CaveCarving.CARVING

    if cave_type_data.get("width") == null:
        match cave_carve_type:
            CaveType.H_LINE:
                cave_type_data.width = int(rand_range(4, NUM_COLS)) * BLOCK_SIZE
                cave_type_data.height = int(rand_range(1, 3)) * BLOCK_SIZE
            CaveType.V_LINE:
                cave_type_data.height = int(rand_range(4, ROW_BUFFER)) * BLOCK_SIZE
                cave_type_data.width = int(rand_range(1, 3)) * BLOCK_SIZE
            CaveType.BOX:
                var box_size = int(rand_range(3, 5)) * BLOCK_SIZE
                cave_type_data.width = box_size
                cave_type_data.height = box_size
            CaveType.GAP:
                cave_carve_pos = Vector2(pos.x, pos.y)
                cave_type_data.width = NUM_COLS * BLOCK_SIZE
                cave_type_data.height = int(rand_range(4, 6)) * BLOCK_SIZE
            CaveType.V_TUNNEL:
                cave_type_data.tunnel_down_factor = 0.65
                cave_type_data.width = 1 * BLOCK_SIZE
                cave_type_data.height = 1 * BLOCK_SIZE
            CaveType.H_TUNNEL:
                cave_type_data.tunnel_down_factor = 0.45
                cave_type_data.width = 1 * BLOCK_SIZE
                cave_type_data.height = 1 * BLOCK_SIZE

    if pos.x >= cave_carve_pos.x and pos.x < (cave_carve_pos.x + cave_type_data.width) and pos.y < (cave_carve_pos.y + cave_type_data.height):

        # Handle the tunneling case where we move the position each time
        if (cave_carve_type == CaveType.V_TUNNEL or cave_carve_type == CaveType.H_TUNNEL) and pos.x <= (cave_carve_pos.x + (NUM_COLS * BLOCK_SIZE)):
            if randf() <= cave_type_data.tunnel_down_factor:
                cave_carve_pos.y += BLOCK_SIZE
            else:
                cave_carve_pos.x += BLOCK_SIZE

        return false
    if pos.y >= (cave_carve_pos.y + cave_type_data.height):
        cave_type_data.clear()
        cave_carve_state = CaveCarving.NOT_CARVING

    return true


func generate_more_blocks(slow: bool = false):
    # Get position
    var pos: Vector2 = newRowSpawn.position

    # Update the row spawn position
    newRowSpawn.position.y += (ROW_BUFFER * BLOCK_SIZE)

    cave_carve_state = CaveCarving.NEW_CAVE

    for row in range(ROW_BUFFER):
        for col in range(NUM_COLS):
            var x : float = pos.x + (col * BLOCK_SIZE) + (BLOCK_SIZE / 2.0)
            var y : float = pos.y + (row * BLOCK_SIZE) + (BLOCK_SIZE / 2.0)
            var new_pos: Vector2 = Vector2(x, y)
            if should_place_block(new_pos):
                # warning-ignore:return_value_discarded
                Utils.instance_scene_on_main(Block, new_pos)
        if slow:
            yield(get_tree(), "idle_frame")
        if cave_carve_state == CaveCarving.NOT_CARVING and randf() <= 0.4:
            cave_carve_state = CaveCarving.NEW_CAVE

    cave_type_data.clear()
    cave_carve_state = CaveCarving.NOT_CARVING
