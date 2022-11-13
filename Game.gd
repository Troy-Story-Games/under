extends Node
class_name MainGame

const BlockScene = preload("res://World/Block.tscn")
const RockScene = preload("res://World/Rock.tscn")
const PlayerScene = preload("res://Player/Player.tscn")
const PlayerDeathEffectScene = preload("res://Effects/PlayerDeathEffect.tscn")

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

# Minimum number of pixels the player can be away from the last generated row
# before we generate a new row.
export(int) var REGENERATE_BLOCK_THRESHOLD = 80

# How many rows to generate each time we call "generate_more_blocks()"
export(int) var ROW_BUFFER = 18

# The depth (in number of rows) before caves begin to generate
export(int) var CAVE_DEPTH = 24

# Chance that the tunnel generator goes down rather than across. For a tunnel
# that's mostly verticle (V_TUNNEL) we default to 65% of the time the generator
# chooses to go down. While for a horizontal tunnel (H_TUNNEL) we default to
# 45% of the time so that the generator usually goes across.
export(float) var V_TUNNEL_DOWN_FACTOR = 0.65
export(float) var H_TUNNEL_DOWN_FACTOR = 0.45

# Chance that a rock is generated. Rock size is equal chance of 1, 2, and 3
export(float) var ROCK_CHANCE = 0.03

onready var camera = $Camera2D
onready var leftWall = $LeftWall
onready var rightWall = $RightWall
onready var newRowSpawn = $NewRowSpawn
onready var gameUI = $Camera2D/CanvasLayer/GameUI

var spawn_point: Vector2 = Vector2.ZERO
var player: Player = null
var playerStats: PlayerStats = Utils.get_player_stats()
var zero_depth: float = 0
var current_depth: float = 0
var cave_depth: float = 0
var cave_carve_pos = Vector2.ZERO
var cave_carve_type = CaveType.H_LINE
var cave_carve_state = CaveCarving.NOT_CARVING
var cave_type_data = {}


func _ready():
    # warning-ignore:return_value_discarded
    playerStats.connect("player_died", self, "_on_PlayerStats_player_died")
    # warning-ignore:return_value_discarded
    playerStats.connect("game_over", self, "_on_PlayerStats_game_over")
    # warning-ignore:return_value_discarded
    playerStats.connect("player_dirt_changed", self, "_on_PlayerStats_dirt_changed")

    gameUI.set_dirt(0)
    spawn_point = Vector2((Utils.NUM_COLS * Utils.BLOCK_SIZE) / 2.0, newRowSpawn.position.y - Utils.BLOCK_SIZE * 2)
    zero_depth = newRowSpawn.position.y
    cave_depth = zero_depth + (CAVE_DEPTH * Utils.BLOCK_SIZE)
    generate_more_blocks()

    respawn_player()


func _process(_delta: float) -> void:
    if not player or not is_instance_valid(player):
        return

    var y_pos : float = player.position.y
    leftWall.position.y = y_pos
    rightWall.position.y = y_pos

    if abs(newRowSpawn.global_position.y - player.global_position.y) < REGENERATE_BLOCK_THRESHOLD:
        generate_more_blocks(true)

    current_depth = (player.position.y - zero_depth) / float(Utils.BLOCK_SIZE)
    current_depth *= Utils.BLOCK_SIZE_IN_METERS
    gameUI.set_depth(ceil(current_depth))


func _on_PlayerStats_dirt_changed(value: int):
    gameUI.set_dirt(value)


func _on_PlayerStats_player_died():
    spawn_point = player.position

    # Pause the game for a second
    get_tree().paused = true
    yield(get_tree().create_timer(1.0), "timeout")

    player.queue_free()
    var death_effect: CPUParticles2D = Utils.instance_scene_on_main(PlayerDeathEffectScene, spawn_point)
    death_effect.emitting = true

    get_tree().paused = false
    yield(get_tree().create_timer(1.5), "timeout")

    playerStats.lives -= 1
    if playerStats.lives > 0:
        respawn_player()


func _on_PlayerStats_game_over():
    playerStats.refill_stats()
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/GameOverMenu.tscn")


func respawn_player():
    playerStats.respawn()
    player = Utils.instance_scene_on_main(PlayerScene, spawn_point)
    player.assign_camera_follow(camera.get_path())


func should_place_block(pos: Vector2) -> bool:
    # Wait to make caves until we're initially deep enough
    if newRowSpawn.position.y < cave_depth:
        return true

    match cave_carve_state:
        CaveCarving.NOT_CARVING:
            return true
        CaveCarving.NEW_CAVE:
            var start_x_positions = []
            for idx in range(Utils.NUM_COLS):
                start_x_positions.push_back(pos.x + (idx * Utils.BLOCK_SIZE))
            start_x_positions.shuffle()

            var cave_types = CaveType.values()
            cave_types.shuffle()
            cave_carve_type = cave_types[0]
            cave_carve_pos = Vector2(start_x_positions[0], pos.y)
            cave_carve_state = CaveCarving.CARVING

    if cave_type_data.get("width") == null:
        match cave_carve_type:
            CaveType.H_LINE:
                cave_type_data.width = Utils.rand_int_incl(4, Utils.NUM_COLS) * Utils.BLOCK_SIZE
                cave_type_data.height = Utils.rand_int_incl(1, 3) * Utils.BLOCK_SIZE
            CaveType.V_LINE:
                cave_type_data.height = Utils.rand_int_incl(4, ROW_BUFFER) * Utils.BLOCK_SIZE
                cave_type_data.width = Utils.rand_int_incl(1, 3) * Utils.BLOCK_SIZE
            CaveType.BOX:
                var box_size = Utils.rand_int_incl(3, 5) * Utils.BLOCK_SIZE
                cave_type_data.width = box_size
                cave_type_data.height = box_size
            CaveType.GAP:
                cave_carve_pos = Vector2(pos.x, pos.y)
                cave_type_data.width = Utils.NUM_COLS * Utils.BLOCK_SIZE
                cave_type_data.height = Utils.rand_int_incl(4, 6) * Utils.BLOCK_SIZE
            CaveType.V_TUNNEL:
                cave_type_data.tunnel_down_factor = V_TUNNEL_DOWN_FACTOR
                cave_type_data.width = 1 * Utils.BLOCK_SIZE
                cave_type_data.height = 1 * Utils.BLOCK_SIZE
            CaveType.H_TUNNEL:
                cave_type_data.tunnel_down_factor = H_TUNNEL_DOWN_FACTOR
                cave_type_data.width = 1 * Utils.BLOCK_SIZE
                cave_type_data.height = 1 * Utils.BLOCK_SIZE

    if (pos.x >= cave_carve_pos.x and
        pos.x < (cave_carve_pos.x + cave_type_data.width) and
        pos.y < (cave_carve_pos.y + cave_type_data.height)):

        # Handle the tunneling case where we move the position each time
        if ((cave_carve_type == CaveType.V_TUNNEL or cave_carve_type == CaveType.H_TUNNEL) and
            pos.x <= (cave_carve_pos.x + (Utils.NUM_COLS * Utils.BLOCK_SIZE))):
            if randf() <= cave_type_data.tunnel_down_factor:
                cave_carve_pos.y += Utils.BLOCK_SIZE
            else:
                cave_carve_pos.x += Utils.BLOCK_SIZE

        return false
    if pos.y >= (cave_carve_pos.y + cave_type_data.height):
        cave_type_data.clear()
        cave_carve_state = CaveCarving.NOT_CARVING

    return true


func generate_more_blocks(slow: bool = false):
    # Get position
    var pos: Vector2 = newRowSpawn.position

    # Update the row spawn position
    newRowSpawn.position.y += (ROW_BUFFER * Utils.BLOCK_SIZE)

    cave_carve_state = CaveCarving.NEW_CAVE

    for row in range(ROW_BUFFER):
        for col in range(Utils.NUM_COLS):
            var x : float = pos.x + (col * Utils.BLOCK_SIZE) + (Utils.BLOCK_SIZE / 2.0)
            var y : float = pos.y + (row * Utils.BLOCK_SIZE) + (Utils.BLOCK_SIZE / 2.0)
            var new_pos: Vector2 = Vector2(x, y)
            if should_place_block(new_pos):
                place_world_block(new_pos)
        if slow:
            yield(get_tree(), "idle_frame")
        if cave_carve_state == CaveCarving.NOT_CARVING and randf() <= 0.4:
            cave_carve_state = CaveCarving.NEW_CAVE

    cave_type_data.clear()
    cave_carve_state = CaveCarving.NOT_CARVING


func place_world_block(pos: Vector2) -> void:
    if randf() < ROCK_CHANCE:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(RockScene, pos)
    else:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(BlockScene, pos)
