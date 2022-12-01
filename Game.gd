extends Node
class_name MainGame

const LEFT_SIDE_WALL_X_POS = 28
const RIGHT_SIDE_WALL_X_POS = 128

const BlockScene = preload("res://World/Blocks/DirtBlock.tscn")
const RockScene = preload("res://World/Blocks/Rock.tscn")
const BombBlockScene = preload("res://World/Blocks/BombBlock.tscn")
const PlayerScene = preload("res://Player/Player.tscn")
const PlayerDeathEffectScene = preload("res://Effects/PlayerDeathEffect.tscn")
const RockDropScene = preload("res://World/Blocks/RockDrop.tscn")
const WarningArrowScene = preload("res://Effects/WarningArrow.tscn")
const SideWallSpriteScene = preload("res://World/SideWallSprite.tscn")
const ChestBlockScene = preload("res://World/Blocks/ChestBlock.tscn")
const GoalBlockScene = preload("res://World/Blocks/GoalBlock.tscn")
const EndgameBlockScene = preload("res://World/Blocks/EndgameBlock.tscn")

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
# This is also the screen height in blocks. 144 pixels high is 18 blocks
export(int) var ROW_BUFFER = 18

# The depth (in number of rows) before caves begin to generate
export(int) var CAVE_DEPTH = 24

# Chance that the tunnel generator goes down rather than across. For a tunnel
# that's mostly verticle (V_TUNNEL) we default to 65% of the time the generator
# chooses to go down. While for a horizontal tunnel (H_TUNNEL) we default to
# 45% of the time so that the generator usually goes across.
export(float) var V_TUNNEL_DOWN_FACTOR = 0.65
export(float) var H_TUNNEL_DOWN_FACTOR = 0.45

# Chances for different game events/hazards/gifts/etc.
export(float) var ROCK_CHANCE = 0.03
export(float) var MIN_BOMB_CHANCE = 0.03
export(float) var MAX_BOMB_CHANCE = 0.07
export(float) var CHEST_CHANCE = 0.005
export(float) var EVENT_COOLDOWN_MAX = 10.0
export(float) var EVENT_COOLDOWN_MIN = 1.5
export(int) var MAX_DIFFICULTY_DEPTH = 1500

# The depth (in blocks) at which more than just dirt spawns and then at
# which point bombs will spawn
export(int) var ONLY_DIRT_UNTIL = 10
export(int) var ONLY_ROCKS_UNTIL = 100

# The depth (in blocks) at which GameEvents will start
export(int) var EVENT_START_DEPTH = 200

# The depth goal posts (in blocks) are this far apart
export(int) var DEPTH_GOAL_INTERVAL = 250

# Depth the game ends when not in endless mode in meters
export(int) var ENDGAME_DEPTH = 2000

onready var camera = $Camera2D
onready var leftWall = $LeftWall
onready var rightWall = $RightWall
onready var newRowSpawn = $NewRowSpawn
onready var gameUI = $Camera2D/CanvasLayer/GameUI
onready var eventCooldownTimer = $EventCooldownTimer
onready var canvasLayer = $Camera2D/CanvasLayer

var event_cooldown_time: float = 0.0
var spawn_point: Vector2 = Vector2.ZERO
var player: Player = null
var playerStats: PlayerStats = Utils.get_player_stats()
var mainInstances: MainInstances = Utils.get_main_instances()
var zero_depth: float = 0.0
var current_depth_blocks: float = 0.0
var current_depth_pixels: float = 0.0
var current_depth_meters: float = 0.0
var cave_depth: float = 0.0
var cave_carve_pos = Vector2.ZERO
var cave_carve_type = CaveType.H_LINE
var cave_carve_state = CaveCarving.NOT_CARVING
var cave_type_data = {}
var left_x_pos: float = 0.0
var target_depth_goal: int = 0
var endless_mode: bool = false
var generated_endgame_floor: bool = false
var endgame_depth_blocks = 0
var win_game = false
var start_time = 0
var time_now = 0


func _ready():
    # warning-ignore-all:return_value_discarded
    playerStats.connect("player_died", self, "_on_PlayerStats_player_died")
    playerStats.connect("game_over", self, "_on_PlayerStats_game_over")
    playerStats.connect("player_dirt_changed", self, "_on_PlayerStats_dirt_changed")
    playerStats.connect("lives_changed", self, "_on_PlayerStats_lives_changed")
    playerStats.connect("player_depth_changed", self, "_on_PlayerStats_player_depth_changed")
    Events.connect("depth_goal_reached", self, "_on_Events_depth_goal_reached")
    Events.connect("win_game", self, "_on_Events_win_game")

    if SaveAndLoad.custom_data.game_completed:
        endless_mode = true

    gameUI.set_dirt(0)
    gameUI.set_lives(playerStats.lives)
    spawn_point = Vector2((Utils.NUM_COLS * Utils.BLOCK_SIZE) / 1.25, newRowSpawn.global_position.y - Utils.BLOCK_SIZE * 8)
    left_x_pos = newRowSpawn.global_position.x
    zero_depth = newRowSpawn.global_position.y

    # Spawn initial left and right side walls
    Utils.instance_scene_on_main(SideWallSpriteScene, Vector2(LEFT_SIDE_WALL_X_POS, newRowSpawn.global_position.y))
    Utils.instance_scene_on_main(SideWallSpriteScene, Vector2(RIGHT_SIDE_WALL_X_POS, newRowSpawn.global_position.y))

    cave_depth = zero_depth + (CAVE_DEPTH * Utils.BLOCK_SIZE)
    event_cooldown_time = EVENT_COOLDOWN_MAX
    target_depth_goal = DEPTH_GOAL_INTERVAL
    endgame_depth_blocks = meters_to_blocks(ENDGAME_DEPTH)
    generate_more_blocks()

    respawn_player()

    start_time = OS.get_unix_time()


func _on_Events_win_game():
    time_now = OS.get_unix_time()
    win_game = true
    SaveAndLoad.custom_data.completion_time = time_now - start_time
    SaveAndLoad.custom_data.game_completed = true
    SaveAndLoad.save_game()
    if player and is_instance_valid(player) and not player.is_queued_for_deletion():
        player.unassign_camera_follow()


func pos_to_pixel_depth(pos: Vector2) -> float:
    return pos.y - zero_depth


func pos_to_block_depth(pos: Vector2) -> float:
    return pos_to_pixel_depth(pos) / float(Utils.BLOCK_SIZE)


func get_depth_difficulty_factor(depth_in_blocks: float) -> float:
    return depth_in_blocks / float(MAX_DIFFICULTY_DEPTH)


func meters_to_pixels(meters: int) -> int:
    # Convert a number of meters in depth to a y position.
    return int(zero_depth) + int((meters / float(Utils.BLOCK_SIZE_IN_METERS)) * Utils.BLOCK_SIZE)


func meters_to_blocks(meters: int) -> int:
    return int(meters / float(Utils.BLOCK_SIZE_IN_METERS))


func _process(_delta: float) -> void:
    if not player or not is_instance_valid(player):
        return

    var y_pos : float = player.global_position.y
    leftWall.global_position.y = y_pos
    rightWall.global_position.y = y_pos

    if abs(newRowSpawn.global_position.y - player.global_position.y) < REGENERATE_BLOCK_THRESHOLD:
        generate_more_blocks(true)

    current_depth_pixels = pos_to_pixel_depth(player.global_position)
    current_depth_blocks = pos_to_block_depth(player.global_position)
    current_depth_meters = current_depth_blocks * Utils.BLOCK_SIZE_IN_METERS
    playerStats.set_depth(int(ceil(current_depth_meters)))

    if current_depth_blocks >= EVENT_START_DEPTH and eventCooldownTimer.time_left == 0:
        eventCooldownTimer.start(event_cooldown_time)

    if current_depth_blocks <= MAX_DIFFICULTY_DEPTH:
        var new_cooldown_time = (EVENT_COOLDOWN_MAX - EVENT_COOLDOWN_MIN) * (1 - get_depth_difficulty_factor(current_depth_blocks))
        event_cooldown_time = clamp(new_cooldown_time, EVENT_COOLDOWN_MIN, EVENT_COOLDOWN_MAX)
    else:
        event_cooldown_time = EVENT_COOLDOWN_MIN

    if current_depth_meters >= ENDGAME_DEPTH and not endless_mode:
        player.start_invincibility(100)


func _on_Events_depth_goal_reached():
    target_depth_goal += DEPTH_GOAL_INTERVAL


func _on_PlayerStats_dirt_changed(value: int):
    gameUI.set_dirt(value)


func _on_PlayerStats_player_died():
    spawn_point = player.global_position

    # Pause the game for a second
    get_tree().paused = true
    Events.emit_signal("add_screenshake", 0.075, 0.5)
    SoundFx.play("player_hit", 1, -10)
    yield(get_tree().create_timer(1.0), "timeout")

    # warning-ignore:unsafe_property_access
    mainInstances.player = null
    player.queue_free()

    Engine.time_scale = 0.5
    var death_effect: CPUParticles2D = Utils.instance_scene_on_main(PlayerDeathEffectScene, spawn_point)
    death_effect.emitting = true

    get_tree().paused = false
    Engine.time_scale = 0.30
    Events.emit_signal("add_screenshake", 0.075, 0.5)
    SoundFx.play("death_sound", 0.65, -20)
    yield(get_tree().create_timer(0.75), "timeout")
    Engine.time_scale = 1

    playerStats.lives -= 1
    if playerStats.lives > 0:
        respawn_player()


func _on_PlayerStats_lives_changed(value):
    gameUI.set_lives(value)
    # TODO: Play sound, maybe particles

func _on_PlayerStats_player_depth_changed(value):
    gameUI.set_depth(value)

func _on_PlayerStats_game_over():
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Menus/GameOverMenu.tscn")


func _on_Player_player_exited_screen():
    if win_game:
        get_tree().change_scene("res://Menus/WinMenu.tscn")


func respawn_player():
    playerStats.respawn()
    player = Utils.instance_scene_on_main(PlayerScene, spawn_point)
    player.assign_camera_follow(camera.get_path())
    player.connect("player_exited_screen", self, "_on_Player_player_exited_screen")
    # warning-ignore:unsafe_property_access
    mainInstances.player = player


func should_place_block(pos: Vector2) -> bool:
    # Wait to make caves until we're initially deep enough
    if newRowSpawn.global_position.y < cave_depth:
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
    var pos: Vector2 = newRowSpawn.global_position

    # Update the row spawn position
    newRowSpawn.global_position.y += (ROW_BUFFER * Utils.BLOCK_SIZE)

    # Place the left and right side walls
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(SideWallSpriteScene, Vector2(LEFT_SIDE_WALL_X_POS, newRowSpawn.global_position.y))
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(SideWallSpriteScene, Vector2(RIGHT_SIDE_WALL_X_POS, newRowSpawn.global_position.y))

    if generated_endgame_floor:
        return

    cave_carve_state = CaveCarving.NEW_CAVE

    for row in range(ROW_BUFFER):
        var y : float = pos.y + (row * Utils.BLOCK_SIZE) + Utils.HALF_BLOCK_SIZE
        var block_depth = pos_to_block_depth(Vector2(0, y))

        if row < 6 and block_depth >= endgame_depth_blocks and not endless_mode:
            print("Making empty space for endgame")
            generated_endgame_floor = true
            continue  # Make a big empty space for the ends game area
        if generated_endgame_floor:
            Utils.instance_scene_on_main(EndgameBlockScene, Vector2(pos.x + Utils.HALF_BLOCK_SIZE, y))
            return

        for col in range(Utils.NUM_COLS):
            var x : float = pos.x + (col * Utils.BLOCK_SIZE) + Utils.HALF_BLOCK_SIZE
            var new_pos: Vector2 = Vector2(x, y)

            if col == 0 and block_depth >= target_depth_goal:
                print("Generating goal blocks")
                target_depth_goal += DEPTH_GOAL_INTERVAL
                Utils.instance_scene_on_main(GoalBlockScene, new_pos)
                break  # Goal blocks take a whole row

            if should_place_block(new_pos):
                place_world_block(new_pos)
        if slow:
            yield(get_tree(), "idle_frame")
        if cave_carve_state == CaveCarving.NOT_CARVING and randf() <= 0.4:
            cave_carve_state = CaveCarving.NEW_CAVE

    cave_type_data.clear()
    cave_carve_state = CaveCarving.NOT_CARVING


func spawn_rock_drop():
    # If the player dies at or around the same moment we try to spawn
    # an event, there's a chance we try to access an attribute from the player
    # but it would be an invalid instance until the player respawns. So we spin
    # here until we have the player back.
    while player == null or not is_instance_valid(player):
        yield(get_tree(), "idle_frame")

    SoundFx.play("event_warning", 1, -15)

    var col = Utils.rand_int_incl(0, Utils.NUM_COLS - 1)
    var col_x = left_x_pos + (col * Utils.BLOCK_SIZE) + Utils.HALF_BLOCK_SIZE
    var y_pos = player.global_position.y - (Utils.BLOCK_SIZE * CAVE_DEPTH)

    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(RockDropScene, Vector2(col_x, y_pos))

    var warning_arrow = WarningArrowScene.instance()
    canvasLayer.add_child(warning_arrow)
    warning_arrow.global_position.y = Utils.BLOCK_SIZE
    warning_arrow.global_position.x = col_x


func place_world_block(pos: Vector2) -> void:
    var block_depth = pos_to_block_depth(pos)
    if block_depth < ONLY_DIRT_UNTIL:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(BlockScene, pos)
        return

    var rock_percent = ROCK_CHANCE * 100.0
    var chest_percent = CHEST_CHANCE * 100.0
    var bomb_percent = 0
    var current_bomb_chance = 0

    if block_depth >= ONLY_ROCKS_UNTIL:
        if block_depth <= MAX_DIFFICULTY_DEPTH:
            var new_bomb_chance = (MAX_BOMB_CHANCE - MIN_BOMB_CHANCE) * (1 - get_depth_difficulty_factor(block_depth))
            current_bomb_chance = clamp(new_bomb_chance, MIN_BOMB_CHANCE, MAX_BOMB_CHANCE)
        else:
            current_bomb_chance = MAX_BOMB_CHANCE
        bomb_percent = current_bomb_chance * 100.0

    # Weighted randomization (I think)
    var rock_range = Vector2(0.0, rock_percent)
    var chest_range = Vector2(rock_percent, rock_percent + chest_percent)
    var bomb_range = Vector2(rock_percent + chest_percent, rock_percent + chest_percent + bomb_percent)
    var selection = randf() * 100.0

    if selection >= rock_range.x and selection < rock_range.y:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(RockScene, pos)
    elif selection >= chest_range.x and selection < chest_range.y:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(ChestBlockScene, pos)
    elif selection >= bomb_range.x and selection < bomb_range.y:
         # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(BombBlockScene, pos)
    else:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(BlockScene, pos)


func _on_EventCooldownTimer_timeout() -> void:
    if not win_game:
        spawn_rock_drop()
