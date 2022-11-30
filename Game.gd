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

# Endless or levels for game mode. Endless unlocked after first completion
enum GameMode {
    LEVELS,
    ENDLESS
}

# Cave generation mode
enum CaveCarving {
    NOT_CARVING,
    NEW_CAVE,
    CARVING
}

# Type of caves that can be generated
enum CaveType {
    H_LINE,
    V_LINE,
    BOX,
    GAP,
    V_TUNNEL,
    H_TUNNEL
}

# Blocks that spawn as part of level generation
enum GameHazard {
    ROCK,
    BOMB
}

# Blocks that spawn as part of level generation (but are good)
enum GameGift {
    CHEST
}

# Events that happen outside of level generation
enum GameEvent {
    ROCK_DROP
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

# Chance that a hazard or gift is generated.
export(float) var HAZARD_OR_GIFT_CHANCE = 0.05

# Chance that a gift is generated when HAZARD_OR_GIFT_CHANCE happens
# Translated: 5% of 5% of the time...a gift will be generated
export(float) var GIFT_CHANCE = 0.05

# Max time to wait b/w game events
export(int) var EVENT_COOLDOWN_MAX = 20

# Min time to wait b/w game events
export(int) var EVENT_COOLDOWN_MIN = 1

# The depth (in blocks) at which GameEvents will start
export(int) var ENDLESS_EVENT_START_DEPTH = 24

# The depth (in blocks) at which the event cooldown should be at its minimum value
export(int) var EVENT_MAX_DIFFICULTY_DEPTH = 500

# Offset on the screen for the goal flag (in pixels)
export(int) var DEPTH_GOAL_FLAG_X_OFFSET = 50
export(int) var ENDLESS_DEPTH_GOAL_INTERVAL = 1000

onready var camera = $Camera2D
onready var leftWall = $LeftWall
onready var rightWall = $RightWall
onready var newRowSpawn = $NewRowSpawn
onready var gameUI = $Camera2D/CanvasLayer/GameUI
onready var eventCooldownTimer = $EventCooldownTimer
onready var canvasLayer = $Camera2D/CanvasLayer
onready var depthGoalFlag = $DepthGoalFlagSprite

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
var current_level = 0
var mode = GameMode.LEVELS

# Game levels (depth in meters)
#   level 0: nothing, just dirt
#   level 1: 10 meters, rocks only
#   level 2: 200 meters, rocks and bombs
#   level 3: 500 meters, rocks, bombs, and falling rocks
var levels = [
    {
        "start_depth": 0,
        "hazards": [],
        "events": [],
        "rock_chance": Vector2.ZERO,
        "bomb_chance": Vector2.ZERO,
        "chest_chance": Vector2.ZERO,
        "event_cooldown": Vector2.ZERO
    },
    {
        "start_depth": 10,
        "hazards": [GameHazard.ROCK],
        "events": [],
        "rock_chance": Vector2(0.05, 0.06),
        "bomb_chance": Vector2.ZERO,
        "chest_chance": Vector2(0.05, 0.05),
        "event_cooldown": Vector2.ZERO
    },
    {
        "start_depth": 200,
        "hazards": [GameHazard.ROCK, GameHazard.BOMB],
        "events": [],
        "rock_chance": Vector2(0.05, 0.06),
        "bomb_chance": Vector2(0.05, 0.08),
        "chest_chance": Vector2(0.05, 0.05),
        "event_cooldown": Vector2.ZERO
    },
    {
        "start_depth": 500,
        "hazards": [GameHazard.ROCK, GameHazard.BOMB],
        "events": [GameEvent.ROCK_DROP],
        "rock_chance": Vector2(0.05, 0.06),
        "bomb_chance": Vector2(0.05, 0.08),
        "chest_chance": Vector2(0.05, 0.05),
        "event_cooldown": Vector2(20, 2)
    }
]


func _ready():
    # warning-ignore:return_value_discarded
    playerStats.connect("player_died", self, "_on_PlayerStats_player_died")
    # warning-ignore:return_value_discarded
    playerStats.connect("game_over", self, "_on_PlayerStats_game_over")
    # warning-ignore:return_value_discarded
    playerStats.connect("player_dirt_changed", self, "_on_PlayerStats_dirt_changed")
    # warning-ignore:return_value_discarded
    playerStats.connect("lives_changed", self, "_on_PlayerStats_lives_changed")
    # warning-ignore:return_value_discarded
    playerStats.connect("player_depth_changed", self, "_on_PlayerStats_player_depth_changed")

    # Set game mode and depth goal flag
    if SaveAndLoad.custom_data.game_completed:
        mode = GameMode.ENDLESS
        target_depth_goal = ENDLESS_DEPTH_GOAL_INTERVAL
    else:
        target_depth_goal = levels[1].start_depth

    depthGoalFlag.global_position = Vector2(DEPTH_GOAL_FLAG_X_OFFSET, meters_to_pixels(target_depth_goal))

    gameUI.set_dirt(0)
    gameUI.set_lives(playerStats.lives)
    spawn_point = Vector2((Utils.NUM_COLS * Utils.BLOCK_SIZE) / 2.0, newRowSpawn.global_position.y - Utils.BLOCK_SIZE * 2)
    left_x_pos = newRowSpawn.global_position.x
    zero_depth = newRowSpawn.global_position.y

    # Spawn initial left and right side walls
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(SideWallSpriteScene, Vector2(LEFT_SIDE_WALL_X_POS, newRowSpawn.global_position.y))
    # warning-ignore:return_value_discarded
    Utils.instance_scene_on_main(SideWallSpriteScene, Vector2(RIGHT_SIDE_WALL_X_POS, newRowSpawn.global_position.y))

    cave_depth = zero_depth + (CAVE_DEPTH * Utils.BLOCK_SIZE)
    event_cooldown_time = EVENT_COOLDOWN_MAX
    generate_more_blocks()

    respawn_player()


func pos_to_pixel_depth(pos: Vector2) -> float:
    return pos.y - zero_depth


func pos_to_block_depth(pos: Vector2) -> float:
    return pos_to_pixel_depth(pos) / float(Utils.BLOCK_SIZE)


func meters_to_pixels(meters: int) -> int:
    # Convert a number of meters in depth to a y position.
    return int(zero_depth) + int((meters / float(Utils.BLOCK_SIZE_IN_METERS)) * Utils.BLOCK_SIZE)


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

    match mode:
        GameMode.ENDLESS:
            if current_depth_blocks >= ENDLESS_EVENT_START_DEPTH and eventCooldownTimer.time_left == 0:
                eventCooldownTimer.start(event_cooldown_time)

            if current_depth_blocks <= EVENT_MAX_DIFFICULTY_DEPTH:
                var depth_difficulty_factor: float = current_depth_blocks / float(EVENT_MAX_DIFFICULTY_DEPTH)
                var new_cooldown_time = (EVENT_COOLDOWN_MAX - EVENT_COOLDOWN_MIN) * (1 - depth_difficulty_factor)
                event_cooldown_time = clamp(new_cooldown_time, EVENT_COOLDOWN_MIN, EVENT_COOLDOWN_MAX)
        GameMode.LEVELS:
            pass


    if current_depth_meters >= target_depth_goal:
        depth_goal_reached()


func depth_goal_reached():
    match mode:
        GameMode.ENDLESS:
            target_depth_goal += ENDLESS_DEPTH_GOAL_INTERVAL
        GameMode.LEVELS:
            current_level += 1
            if current_level >= (len(levels) - 1):
                # Last level
                depthGoalFlag.visible = false
            else:
                target_depth_goal = levels[current_level + 1].start_depth

            if current_level == len(levels):
                print("GAME COMPLETE")
                SaveAndLoad.custom_data.game_completed = true

    depthGoalFlag.global_position = Vector2(DEPTH_GOAL_FLAG_X_OFFSET, meters_to_pixels(target_depth_goal))


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


func respawn_player():
    playerStats.respawn()
    player = Utils.instance_scene_on_main(PlayerScene, spawn_point)
    player.assign_camera_follow(camera.get_path())
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

    cave_carve_state = CaveCarving.NEW_CAVE

    for row in range(ROW_BUFFER):
        for col in range(Utils.NUM_COLS):
            var x : float = pos.x + (col * Utils.BLOCK_SIZE) + Utils.HALF_BLOCK_SIZE
            var y : float = pos.y + (row * Utils.BLOCK_SIZE) + Utils.HALF_BLOCK_SIZE
            var new_pos: Vector2 = Vector2(x, y)
            if should_place_block(new_pos):
                place_world_block(new_pos)
        if slow:
            yield(get_tree(), "idle_frame")
        if cave_carve_state == CaveCarving.NOT_CARVING and randf() <= 0.4:
            cave_carve_state = CaveCarving.NEW_CAVE

    cave_type_data.clear()
    cave_carve_state = CaveCarving.NOT_CARVING


func spawn_hazard_or_gift(pos: Vector2):
    var spawn_gift: bool = false
    if randf() < GIFT_CHANCE:
        spawn_gift = true

    var hazard_types = GameHazard.values()
    hazard_types.shuffle()
    var hazard = hazard_types[0]

    var gift_types = GameGift.values()
    gift_types.shuffle()
    var gift = gift_types[0]

    if not spawn_gift:
        match hazard:
            GameHazard.ROCK:
                # warning-ignore:return_value_discarded
                Utils.instance_scene_on_main(RockScene, pos)
            GameHazard.BOMB:
                # warning-ignore:return_value_discarded
                Utils.instance_scene_on_main(BombBlockScene, pos)
    else:
        match gift:
            GameGift.CHEST:
                # warning-ignore:return_value_discarded
                Utils.instance_scene_on_main(ChestBlockScene, pos)


func spawn_event():
    # If the player dies at or around the same moment we try to spawn
    # an event, there's a chance we try to access an attribute from the player
    # but it would be an invalid instance until the player respawns. So we spin
    # here until we have the player back.
    while player == null or not is_instance_valid(player):
        yield(get_tree(), "idle_frame")

    var event_types = GameEvent.values()
    event_types.shuffle()
    var event = event_types[0]

    # TODO: Remove this line - it forces all events to be rock drop
    event = GameEvent.ROCK_DROP
    # TODO: Remove the above line - it forces all events to be rock drop

    SoundFx.play("event_warning", 1, -15)

    match event:
        GameEvent.FLOOD:
            print("FLOOD")
        GameEvent.ROCK_DROP:
            print("ROCK DROP")
            var col = Utils.rand_int_incl(0, Utils.NUM_COLS - 1)
            var col_x = left_x_pos + (col * Utils.BLOCK_SIZE) + Utils.HALF_BLOCK_SIZE
            var y_pos = player.global_position.y - (Utils.BLOCK_SIZE * CAVE_DEPTH)

            # warning-ignore:return_value_discarded
            Utils.instance_scene_on_main(RockDropScene, Vector2(col_x, y_pos))

            var warning_arrow = WarningArrowScene.instance()
            canvasLayer.add_child(warning_arrow)
            warning_arrow.global_position.y = Utils.BLOCK_SIZE
            warning_arrow.global_position.x = col_x
        GameEvent.TRIP_WIRE:
            print("TRIP WIRE")


func place_world_block(pos: Vector2) -> void:
    if randf() < HAZARD_OR_GIFT_CHANCE and pos_to_block_depth(pos) > HAZARD_OR_GIFT_START_DEPTH:
        spawn_hazard_or_gift(pos)
    else:
        # warning-ignore:return_value_discarded
        Utils.instance_scene_on_main(BlockScene, pos)


func _on_EventCooldownTimer_timeout() -> void:
    spawn_event()
