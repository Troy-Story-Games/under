extends Resource
class_name PlayerStats

# New life every 5000 dirt
const NEW_LIFE_DIRT = 5000

signal game_over()
signal player_died()
signal player_health_changed(value)
signal player_dirt_changed(value)
signal player_depth_changed(value)
signal lives_changed(value)

var lives: int = 3 setget set_lives
var dirt: int = 0 setget set_dirt
var health : int = 1 setget set_health
var next_life: int = NEW_LIFE_DIRT
var depth: int = 0 setget set_depth


func set_depth(value: int):
    depth = value
    emit_signal("player_depth_changed")


func set_dirt(value: int):
    dirt = value
    if dirt >= next_life:
        self.lives += 1
        next_life += NEW_LIFE_DIRT
    emit_signal("player_dirt_changed", dirt)


func set_lives(value: int):
    lives = int(max(value, 0))
    emit_signal("lives_changed", value)
    if lives == 0:
        emit_signal("game_over")


func set_health(value : int):
    health = int(clamp(value, 0, 1))
    emit_signal("player_health_changed", health)
    if health == 0:
        emit_signal("player_died")


func respawn():
    self.health = 1


func refill_stats():
    self.health = 1
    self.dirt = 0
    self.lives = 3
    self.depth = 0
