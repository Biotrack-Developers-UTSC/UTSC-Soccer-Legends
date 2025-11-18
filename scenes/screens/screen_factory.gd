class_name ScreenFactory

var screens : Dictionary

func _init() -> void:
	screens = { 
		SoccerGame.ScreenType.MAIN_MENU: preload("res://scenes/screens/main_menu/main_menu_screen.tscn"),
		SoccerGame.ScreenType.TOURNAMENT: preload("res://scenes/screens/tournament/tournament_screen.tscn"),
		SoccerGame.ScreenType.TEAM_SELECTION: preload("res://scenes/screens/team_selection/team_selection_screen.tscn"),
		SoccerGame.ScreenType.IN_GAME: preload("res://scenes/screens/world/world_screen.tscn"),
		SoccerGame.ScreenType.GAME_MODE_SELECTION: preload("res://scenes/screens/main_menu/game_mode_selection_screen.tscn"),
		SoccerGame.ScreenType.OPTIONS_SELECTION: preload("res://scenes/screens/main_menu/settings_selection_screen.tscn"),
		#SoccerGame.ScreenType.CONTROLS: preload("res://scenes/screens/main_menu/controls_screen.tscn"),
		#SoccerGame.ScreenType.ABOUT: preload("res://scenes/screens/main_menu/about_screen.tscn"),
		#SoccerGame.ScreenType.QUIZ: preload(),
	}

func get_fresh_screen(screen: SoccerGame.ScreenType) -> Screen:
	assert(screens.has(screen), "screen doesn't exist!")
	return screens.get(screen).instantiate()
