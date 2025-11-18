class_name SettingSelectionScreen
extends Screen

const NB_COLS := 2
const NB_ROWS := 2
const BUTTON_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_selector.tscn")

@onready var options_container: Control = %OptionsContainer

var options: Array[String] = ["PLAY", "CONTROLS", "ABOUT", "MENU"]

var selection: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO] # selección de P1 y P2
var selectors: Array[FlagSelector] = []                         # selectores visibles

var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.UP: Vector2i.UP,
	KeyUtils.Action.DOWN: Vector2i.DOWN,
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT
}

func _ready() -> void:
	setup_bracketflags()
	place_selectors()
	update_labels()

func _process(_delta: float) -> void:
	for i in range(selectors.size()):
		var scheme: Player.ControlScheme = selectors[i].control_scheme

		# Navegación
		for action in move_dirs.keys():
			if KeyUtils.is_action_just_pressed(scheme, action):
				try_navigate(i, move_dirs[action])

		# Confirmar con cualquiera
		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.SHOOT):
			SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
			var index: int = selection[i].x + selection[i].y * NB_COLS
			handle_selection(index)

		# Retroceder con cualquiera
		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.PASS):
			SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)

func setup_bracketflags() -> void:
	for i in range(min(options_container.get_child_count(), options.size())):
		var node := options_container.get_child(i)
		if node.has_node("Label"):
			node.get_node("Label").text = options[i]

# --- 🔹 Crea los selectores de P1 y P2 ---
func place_selectors() -> void:
	add_selector(Player.ControlScheme.P1)
	if not GameManager.player_setup[1].is_empty():
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	var selector: FlagSelector = BUTTON_SELECTOR_PREFAB.instantiate()
	selector.control_scheme = control_scheme
	selectors.append(selector)
	options_container.add_child(selector)
	var base_pos: Vector2 = options_container.get_child(0).position
	if control_scheme == Player.ControlScheme.P2:
		base_pos = base_pos
	selector.position = base_pos

func try_navigate(index: int, direction: Vector2i) -> void:
	var rect := Rect2i(0, 0, NB_COLS, NB_ROWS)
	if rect.has_point(selection[index] + direction):
		selection[index] += direction
		var idx: int = selection[index].x + selection[index].y * NB_COLS
		selectors[index].position = options_container.get_child(idx).position
		if selectors[index].control_scheme == Player.ControlScheme.P2:
			selectors[index].position += Vector2(0, 0)
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

func update_labels() -> void:
	for j in range(options_container.get_child_count()):
		var node := options_container.get_child(j)
		if node is BotonBracketFlag:
			node.set_text(options[j])
			node.set_highlighted(false)

	var current_index: int = selection[0].x + selection[0].y * NB_COLS
	var current_node := options_container.get_child(current_index)
	if current_node is BotonBracketFlag:
		current_node.set_text("* " + options[current_index])
		current_node.set_highlighted(true)

func handle_selection(index: int) -> void:
	match index:
		0:
			transition_screen(SoccerGame.ScreenType.GAME_MODE_SELECTION)
		1:
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)
		2:
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)
		3:
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)
