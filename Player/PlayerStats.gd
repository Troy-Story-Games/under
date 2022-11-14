extends Resource
class_name PlayerStats

# Basic PlayerStats resource, modify as needed.
# Retrieve a shared instance with Utils.get_player_stats()
# from anywhere this is needed.

signal game_over()
signal player_died()
signal player_health_changed(value)
signal player_dirt_changed(value)

var lives: int = 3 setget set_lives
var dirt: int = 0 setget set_dirt
var health : int = 1 setget set_health


func set_dirt(value: int):
    dirt = value
    emit_signal("player_dirt_changed", dirt)


func set_lives(value: int):
    lives = int(max(value, 0))
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
