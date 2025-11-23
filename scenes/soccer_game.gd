class_name SoccerGame
extends Node

enum ScreenType{MAIN_MENU, TEAM_SELECTION, TOURNAMENT, IN_GAME, GAME_MODE_SELECTION, OPTIONS_SELECTION, CONTROLS, ABOUT, CUSTOM_MATCH, ANIMALS_QUIZ, SOCCER_QUIZ}

var current_screen : Screen = null
var screen_factory := ScreenFactory.new()

func _init() -> void:
	switch_screen(ScreenType.MAIN_MENU)

func switch_screen(screen: ScreenType, data: ScreenData = ScreenData.new()) -> void:
	if current_screen != null:
		current_screen.queue_free()
	current_screen = screen_factory.get_fresh_screen(screen)
	current_screen.setup(self, data)
	current_screen.screen_transition_requested.connect(switch_screen.bind())
	call_deferred("add_child", current_screen)
