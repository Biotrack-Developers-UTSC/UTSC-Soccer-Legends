class_name GameModeSelectionScreen
extends Screen

const NB_COLS := 2
const NB_ROWS := 2

const BUTTON_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_selector.tscn")
const BUTTON_GAME_MODE_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_game_mode_selector.tscn")
const TROPHY_ICON := preload("res://assets/art/ui/game_mode_selection/trophy_icon.png")
const QUIZ_ICON := preload("res://assets/art/ui/game_mode_selection/quiz_icon.png")

@onready var game_modes_container: Control = %GameModesContainer
var options := ["QUIZ", "TOURNAMENT", "BACK"]

# Selección de ambos jugadores
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
		var scheme := selectors[i].control_scheme

		for action in move_dirs.keys():
			if KeyUtils.is_action_just_pressed(scheme, action):
				try_navigate(i, move_dirs[action])

		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.SHOOT):
			SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
			var idx: int = selection[i].x + selection[i].y * NB_COLS
			handle_selection(idx)

		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.PASS):
			SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)

# --- Configura botones ---
func setup_game_mode_buttons() -> void:
	for i in range(min(game_modes_container.get_child_count(), options.size())):
		var node := game_modes_container.get_child(i)
		if node is BotonBracketFlag:
			node.set_text(options[i])
		if i == 0 and node is SeleccionBotonBracketFlag:
			node.set_text("QUIZ")
			node.set_icon(QUIZ_ICON)
			node.set_background_color(Color(0.6, 0.4, 0.9))

# --- Coloca selectores ---
func place_selectors() -> void:
	add_selector(Player.ControlScheme.P1)
	if not GameManager.player_setup[1].is_empty():
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	var sel: FlagSelector
	sel = BUTTON_GAME_MODE_SELECTOR_PREFAB.instantiate()
	sel.control_scheme = control_scheme
	selectors.append(sel)
	game_modes_container.add_child(sel)

	var base_pos: Vector2 = game_modes_container.get_child(0).position
	if control_scheme == Player.ControlScheme.P2:
		base_pos = base_pos
	sel.position = base_pos

# --- Movimiento sincronizado con navegación especial ---
func try_navigate(index: int, direction: Vector2i) -> void:
	var rect := Rect2i(0, 0, NB_COLS, NB_ROWS)
	var next_pos = selection[index] + direction
	var idx := selection[index].x + selection[index].y * NB_COLS
	# --- Casos especiales ---
	if idx == 2:
		# BACK: navegación lateral vuelve a QUIZ/TOURNAMENT
		if direction == Vector2i.LEFT:
			next_pos = Vector2i(0, 0)  # QUIZ
		elif direction == Vector2i.RIGHT:
			next_pos = Vector2i(1, 0)  # TOURNAMENT
	elif idx == 0 and direction == Vector2i.DOWN:
		# QUIZ -> BACK
		next_pos = Vector2i(0, 1)
	elif idx == 1 and direction == Vector2i.DOWN:
		# TOURNAMENT -> BACK
		next_pos = Vector2i(0, 1)
	# Actualiza solo si la nueva posición es válida
	if rect.has_point(next_pos):
		selection[index] = next_pos
		# Forzar que P1 siempre controle el resaltado
		selection[0] = selection[index]
		idx = selection[0].x + selection[0].y * NB_COLS
		# Reemplaza el selector visual
		selectors[index].queue_free()
		selectors[index] = BUTTON_SELECTOR_PREFAB.instantiate() if idx == 2 else BUTTON_GAME_MODE_SELECTOR_PREFAB.instantiate()
		selectors[index].control_scheme = Player.ControlScheme.P1 if index == 0 else Player.ControlScheme.P2
		game_modes_container.add_child(selectors[index])
		selectors[index].position = game_modes_container.get_child(idx).position
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

# --- Actualiza etiquetas ---
func update_labels() -> void:
	# Primero, todos los botones normales
	for j in range(game_modes_container.get_child_count()):
		var node := game_modes_container.get_child(j)
		if node is BotonBracketFlag or node is SeleccionBotonBracketFlag:
			node.set_text(options[j])
			node.set_highlighted(false)

	# Luego, el botón actual de P1 (el que decide resaltado)
	var current_idx: int = selection[0].x + selection[0].y * NB_COLS
	var current_node := game_modes_container.get_child(current_idx)
	if current_node is BotonBracketFlag:
		current_node.set_text("* " + options[current_idx])
		current_node.set_highlighted(true)
	elif current_node is SeleccionBotonBracketFlag:
		current_node.set_highlighted(true)

# --- Acción al seleccionar ---
func handle_selection(index: int) -> void:
	match index:
		0:
			transition_screen(SoccerGame.ScreenType.MAIN_MENU) # QUIZ
		1:
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION)
		2:
			transition_screen(SoccerGame.ScreenType.OPTIONS_SELECTION)
