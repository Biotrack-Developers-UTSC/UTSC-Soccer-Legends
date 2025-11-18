class_name MainMenuScreen
extends Screen

const BUTTON_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_selector.tscn")
const MENU_TEXTURES := [
	[preload("res://assets/art/ui/mainmenu/1-player.png"), preload("res://assets/art/ui/mainmenu/1-player-selected.png")],
	[preload("res://assets/art/ui/mainmenu/2-players.png"), preload("res://assets/art/ui/mainmenu/2-players-selected.png")]
]

@onready var selectable_menu_nodes : Array[TextureRect] = [
	%SinglePlayerTexture,
	%TwoPlayerTexture,
	%BotonBracketFlag   # Botón de salir
]

@onready var selection_icon : TextureRect = %SelectionIcon

var current_selected_index := 0
var is_active := false
var selector_exit : FlagSelector = null

func _ready() -> void:
	refresh_ui()

func _process(_delta: float) -> void:
	if not is_active:
		return

	if KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.UP):
		change_selected_index(current_selected_index - 1)
	elif KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.DOWN):
		change_selected_index(current_selected_index + 1)
	elif KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.SHOOT):
		submit_selection()

func refresh_ui() -> void:
	for i in range(selectable_menu_nodes.size()):
		var node = selectable_menu_nodes[i]

		if i < MENU_TEXTURES.size():
			# Solo 1P y 2P tienen texturas alternas
			if current_selected_index == i:
				node.texture = MENU_TEXTURES[i][1]
				selection_icon.position = node.position + Vector2.LEFT * 25
			else:
				node.texture = MENU_TEXTURES[i][0]
		else:
			# --- 🔹 BOTÓN SALIR ---
			if node is BotonBracketFlag:
				# Si el selector está encima del botón de salir
				if current_selected_index == i:
					node.set_highlighted(true)
					selection_icon.position = node.position + Vector2.LEFT * 25

					if selector_exit == null:
						place_selector()
					selector_exit.position = node.position
					selector_exit.visible = true
				else:
					node.set_highlighted(false)
					if selector_exit != null:
						selector_exit.visible = false

func change_selected_index(new_index) -> void:
	current_selected_index = clamp(new_index, 0, selectable_menu_nodes.size() - 1)
	SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
	refresh_ui()

func place_selector() -> void:
	selector_exit = BUTTON_SELECTOR_PREFAB.instantiate()
	add_child(selector_exit)

	# Ocultar indicadores solo en el menú
	if selector_exit.has_node("%Indicator1P"):
		selector_exit.get_node("%Indicator1P").visible = false
	if selector_exit.has_node("%Indicator2P"):
		selector_exit.get_node("%Indicator2P").visible = false

func submit_selection() -> void:
	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
	
	if current_selected_index == 2:
		exit_game()
	else:
		var country_default = DataLoader.get_countries()[1]
		var player_two = ""
		if current_selected_index != 0:
			player_two = country_default
		
		GameManager.player_setup = [country_default, player_two]
		transition_screen(SoccerGame.ScreenType.OPTIONS_SELECTION)

func on_set_active() -> void:
	refresh_ui()
	is_active = true
	if selector_exit != null:
		selector_exit.visible = false

func exit_game() -> void:
	get_tree().quit()
