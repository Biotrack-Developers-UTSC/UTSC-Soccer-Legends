class_name GameModeSelectionScreen
extends Screen

const NB_COLS := 5
const NB_ROWS := 1

const BUTTON_GAME_MODE_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_game_mode_selector.tscn")
# Asegúrate de que estas texturas existan, si no, comenta las lineas de set_icon
const ANIMALS_ICON := preload("res://assets/art/ui/game_mode_selection/animals_icon.png")
const SOCCER_ICON := preload("res://assets/art/ui/game_mode_selection/soccer_icon.png")
const BACK_ICON := preload("res://assets/art/ui/game_mode_selection/back_icon.png")
const CUSTOM_ICON := preload("res://assets/art/ui/game_mode_selection/custom_icon.png")
const TROPHY_ICON := preload("res://assets/art/ui/game_mode_selection/trophy_icon.png")

@onready var game_modes_container: Control = %GameModesContainer
var options := ["ANIMALS_QUIZ", "SOCCER_QUIZ", "BACK", "CUSTOM_MATCH", "TOURNAMENT"]

var selection: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
var selectors: Array[FlagSelector] = []

var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.UP: Vector2i.UP,
	KeyUtils.Action.DOWN: Vector2i.DOWN,
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT
}

func _ready() -> void:
	setup_game_mode_buttons()
	place_selectors()
	update_labels()

func _process(_delta: float) -> void:
	for i in range(selectors.size()):
		var scheme : Player.ControlScheme = selectors[i].control_scheme

		for action in move_dirs.keys():
			if KeyUtils.is_action_just_pressed(scheme, action):
				try_navigate(i, move_dirs[action])

		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.SHOOT):
			SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
			handle_selection(selection[i].x)

		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.PASS):
			SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)

# --- Botones ---
func setup_game_mode_buttons() -> void:
	for i in range(min(game_modes_container.get_child_count(), options.size())):
		var node := game_modes_container.get_child(i)
		# Verificamos si el nodo tiene los métodos necesarios antes de llamar
		if node.has_method("set_text"):
			match i:
				0:
					node.set_text("ANIMALS QUIZ")
					if node.has_method("set_icon"): node.set_icon(ANIMALS_ICON)
					if node.has_method("set_background_color"): node.set_background_color(Color8(50, 180, 70))
				1:
					node.set_text("SOCCER QUIZ")
					if node.has_method("set_icon"): node.set_icon(SOCCER_ICON)
					if node.has_method("set_background_color"): node.set_background_color(Color8(30, 90, 255))
				2:
					node.set_text("BACK")
					if node.has_method("set_icon"): node.set_icon(BACK_ICON)
					if node.has_method("set_background_color"): node.set_background_color(Color8(153, 102, 230))
				3:
					node.set_text("CUSTOM MATCH")
					if node.has_method("set_icon"): node.set_icon(CUSTOM_ICON)
					if node.has_method("set_background_color"): node.set_background_color(Color8(255, 180, 60))
				4:
					node.set_text("TOURNAMENT")
					if node.has_method("set_icon"): node.set_icon(TROPHY_ICON)
					if node.has_method("set_background_color"): node.set_background_color(Color8(255, 215, 0))

# --- Selección ---
func place_selectors() -> void:
	add_selector(Player.ControlScheme.P1)
	if GameManager.player_setup.size() > 1 and not GameManager.player_setup[1].is_empty():
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	var sel: FlagSelector = BUTTON_GAME_MODE_SELECTOR_PREFAB.instantiate()
	sel.control_scheme = control_scheme
	selectors.append(sel)
	game_modes_container.add_child(sel)
	sel.position = game_modes_container.get_child(0).position

# --- Navegación ---
func try_navigate(index: int, direction: Vector2i) -> void:
	var current_idx := selection[index].x
	var current_node := game_modes_container.get_child(current_idx)
	var current_pos: Vector2 = current_node.global_position
	var best_idx := -1
	var best_dist := INF
	
	for j in range(game_modes_container.get_child_count()):
		if j == current_idx: continue
		
		var node := game_modes_container.get_child(j)
		var pos: Vector2 = node.global_position
		var delta: Vector2 = pos - current_pos
		
		if direction == Vector2i.RIGHT and delta.x <= 0: continue
		if direction == Vector2i.LEFT and delta.x >= 0: continue
		if direction == Vector2i.UP and delta.y >= 0: continue
		if direction == Vector2i.DOWN and delta.y <= 0: continue
		
		var dist: float = delta.length()
		if dist < best_dist:
			best_dist = dist
			best_idx = j
			
	if best_idx != -1:
		selection[index] = Vector2i(best_idx, 0)
		selectors[index].position = game_modes_container.get_child(best_idx).position
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

# --- Actualiza etiquetas ---
func update_labels() -> void:
	for j in range(game_modes_container.get_child_count()):
		var node := game_modes_container.get_child(j)
		if node.has_method("set_highlighted"):
			node.set_highlighted(false)
			
	var current_idx := selection[0].x
	var current_node := game_modes_container.get_child(current_idx)
	if current_node.has_method("set_highlighted"):
		current_node.set_highlighted(true)

# --- Acción al seleccionar una opción ---
func handle_selection(index: int) -> void:
	var data := ScreenData.build()
	match index:
		0:
			data.set_mode("animals_quiz")
			print("🐾 Seleccionado modo: ANIMALS QUIZ")
			# Vamos a Team Selection primero para elegir P1/P2
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION, data)
		1:
			data.set_mode("soccer_quiz")
			print("⚽ Seleccionado modo: SOCCER QUIZ")
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION, data)
		2:
			print("⬅️ Regresando al menú principal")
			transition_screen(SoccerGame.ScreenType.MAIN_MENU, data)
		3:
			data.set_mode("custom_match")
			print("🟧 Seleccionado modo: CUSTOM MATCH")
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION, data)
		4:
			data.set_mode("tournament")
			print("🏆 Seleccionado modo: TOURNAMENT")
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION, data)
		_:
			push_warning("❌ Opción desconocida en GameModeSelectionScreen")
