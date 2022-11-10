extends Resource
class_name PlayerStats

# Basic PlayerStats resource, modify as needed.
# Retrieve a shared instance with Utils.get_player_stats()
# from anywhere this is needed.

signal player_died()
signal player_health_changed(value)
signal player_max_health_changed(value)
signal player_dirt_changed(value)

var dirt: int = 0 setget set_dirt
var max_health : int = 1 setget set_max_health
onready var health : int = max_health setget set_health


func set_dirt(value: int):
    dirt = value
    emit_signal("player_dirt_changed", dirt)


func set_health(value : int):
    health = int(clamp(value, 0, max_health))
    emit_signal("player_health_changed", health)
    if health == 0:
        emit_signal("player_died")


func set_max_health(value : int):
    max_health = value
    self.health = int(min(self.health, max_health))
    emit_signal("player_max_health_changed", max_health)


func refill_stats():
    self.health = self.max_health
    # TODO: Add any other stats that need to be refilled.
