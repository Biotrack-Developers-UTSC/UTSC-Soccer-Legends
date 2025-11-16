class_name GameStateFactory
extends GameState

var states : Dictionary

func _init() -> void:
	states = { 
		GameManager.State.GAMEOVER: GameStateGameOver,
		GameManager.State.IN_PLAY: GameStateInPlay,
		GameManager.State.OVERTIME: GameStateOvertime,
		GameManager.State.SCORED: GameStateScored,
		GameManager.State.RESET: GameStateReset,
		GameManager.State.KICKOFF: GameStateKickoff,
	}

func get_fresh_state(state: GameManager.State) -> GameState:
	assert(states.has(state), "state doesn´t exist!")
	return states.get(state).new()
