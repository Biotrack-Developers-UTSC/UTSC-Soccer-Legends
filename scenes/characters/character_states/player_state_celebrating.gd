class_name PlayerStateCelebrating
extends PlayerState

const AIR_FRICTION := 35.0
const CELEBRATING_HEIGHT := 2.0

func _enter_tree() -> void:
	celeabrate() 
	GameEvents.team_reset.connect(on_team_reset.bind())

func _process(delta: float) -> void:
	if player.height == 0:
		celeabrate()
	player.velocity = player.velocity.move_toward(Vector2.ZERO, delta * AIR_FRICTION)

func celeabrate() -> void:
	animation_player.play("celebrate")
	player.height = 0.1
	player.height_velocity = CELEBRATING_HEIGHT

func on_team_reset() -> void:
	transition_state(Player.State.RESETTING, PlayerStateData.build().set_reset_position(player.spawn_position))
