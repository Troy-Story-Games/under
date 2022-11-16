extends CenterContainer
class_name MainMenu

export(int) var LITTLE_GUY_MAX_SPEED = 32

var run_little_guy := false
var little_guy_start_x = 0

onready var playButton = $"%Play"
onready var dirtSpawner = $DirtSpawner
onready var dirtSpawner2 = $DirtSpawner2
onready var littleGuy = $LittleGuy
onready var littleGuyCollectDirtCollider = $LittleGuy/CollectDirtArea/CollisionShape2D
onready var littleGuyTriggerCollider = $LittleGuy/TriggerArea/CollisionShape2D
onready var dirtStopTimer = $DirtStopTimer
onready var littleGuyAnimationPlayer = $LittleGuy/AnimationPlayer



func _ready() -> void:
    playButton.grab_focus()
    littleGuyCollectDirtCollider.disabled = true
    littleGuyTriggerCollider.disabled = true
    dirtStopTimer.start()
    littleGuyAnimationPlayer.play("Run")
    little_guy_start_x = littleGuy.position.x


func _process(delta):
    if run_little_guy:
        littleGuy.position.x += LITTLE_GUY_MAX_SPEED * delta


func _on_Play_pressed() -> void:
    # warning-ignore:return_value_discarded
    get_tree().change_scene("res://Game.tscn")


func _on_Options_pressed() -> void:
    print("Options pressed")


func _on_Quit_pressed() -> void:
    get_tree().quit()


func _on_DirtStopTimer_timeout() -> void:
    dirtSpawner.stop()
    dirtSpawner2.stop()
    run_little_guy = true
    littleGuyCollectDirtCollider.disabled = false
    littleGuyTriggerCollider.disabled = false


func _on_CollectDirtArea_body_entered(body):
    if body is PhysicsDirt:
        body.queue_free()


func _on_VisibilityNotifier2D_screen_exited():
    if run_little_guy:
        run_little_guy = false
        littleGuy.position.x = little_guy_start_x
        littleGuyCollectDirtCollider.disabled = true
        littleGuyTriggerCollider.disabled = true
        dirtSpawner.start()
        dirtSpawner2.start()
        dirtStopTimer.start()


func _on_TriggerArea_body_entered(body):
    if body is PhysicsDirt:
        body.trigger(littleGuy)
