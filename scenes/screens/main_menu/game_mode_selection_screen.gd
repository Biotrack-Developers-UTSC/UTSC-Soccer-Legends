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

# 💡 NODOS REFERENCIADOS (Asegúrate de que el Background exista en la escena)
@onready var background_node: TextureRect = $Background 
@onready var game_modes_container: Control = %GameModesContainer 

# 💡 REFERENCIAS A LOS NODOS AREA2D (Los 5 botones)
@onready var selectable_area_nodes: Array[Area2D] = [
	%SeleccionBotonesBracketFlagArea2D, 
	%SeleccionBotonesBracketFlag2Area2D, 
	%SeleccionBotonesBracketFlag3Area2D,
	%SeleccionBotonesBracketFlag4Area2D,
	%SeleccionBotonesBracketFlag5Area2D
]

var options := ["ANIMALS_QUIZ", "SOCCER_QUIZ", "BACK", "CUSTOM_MATCH", "TOURNAMENT"]

var selection: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
var selectors: Array[FlagSelector] = []
var all_visual_buttons: Array[Control] = [] # 💡 Lista de nodos visuales

var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.UP: Vector2i.UP,
	KeyUtils.Action.DOWN: Vector2i.DOWN,
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT
}

func _ready() -> void:
	# 1. Configurar botones visuales y recolectar referencias
	collect_and_setup_buttons() 
	
	# 2. Conectar los eventos de mouse/clic/hover de los Area2D
	connect_input_events() 
	
	# 3. Colocar el selector (cursor)
	place_selectors()
	
	# 4. Actualizar resaltado
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
			# Opción 2 (BACK)
			if selection[i].x != 2:
				# Si el foco NO está en BACK, navegamos hacia atrás
				try_navigate(i, Vector2i.RIGHT) 
			handle_selection(2) # El índice 2 es BACK

# ----------------------------------------------------------------------
# 🎯 FUNCIONES DE POSICIÓN Y CURSOR (Copiado de Settings)
# ----------------------------------------------------------------------

func get_cursor_position(index: int) -> Vector2:
	if index >= all_visual_buttons.size():
		return Vector2.ZERO

	var visual_node: Control = all_visual_buttons[index]

	var base_pos: Vector2 = visual_node.global_position
	
	# Transforma la posición GLOBAL del botón a la posición LOCAL del Background 
	if is_instance_valid(background_node):
		base_pos = background_node.get_global_transform_with_canvas().affine_inverse() * base_pos

	return base_pos

# ----------------------------------------------------------------------
# 🎯 LÓGICA DE CONEXIÓN Y MANEJO DE TOQUE/HOVER (Copiado de Settings)
# ----------------------------------------------------------------------

func connect_input_events() -> void:
	for i in range(selectable_area_nodes.size()):
		var area_node: Area2D = selectable_area_nodes[i]
		
		area_node.input_pickable = true
		
		# Conexión de HOVER (Ratón en PC)
		area_node.mouse_entered.connect(func(): on_mouse_enter_area(i))
		area_node.mouse_exited.connect(func(): on_mouse_exit_area(i))
		
		# Conexión de TOQUE/CLIC
		area_node.input_event.connect(func(_viewport, event, _shape_idx):
			on_area_input(i, _viewport, event, _shape_idx)
		)

func on_area_input(index: int, _viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Usa la acción SHOOT (que ahora incluye el clic del ratón)
	if event.is_action_pressed(KeyUtils.ACTIONS_MAP[Player.ControlScheme.P1][KeyUtils.Action.SHOOT]) and event.is_pressed() and not event.is_echo():
		SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
		
		selection[0] = Vector2i(index, 0) # Actualiza el foco
		
		if selectors.size() > 0:
			selectors[0].position = get_cursor_position(index) # Mueve el selector
		
		handle_selection(index)
		get_viewport().set_input_as_handled()

func on_mouse_enter_area(index: int) -> void:
	if selectors.size() > 0:
		selection[0] = Vector2i(index, 0) # Actualiza el foco
		selectors[0].position = get_cursor_position(index) # Mueve el selector

		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

func on_mouse_exit_area(_index: int) -> void:
	pass

# ----------------------------------------------------------------------
# 🔹 LÓGICA DE CONFIGURACIÓN Y NAVEGACIÓN
# ----------------------------------------------------------------------

# 💡 FUNCIÓN ACTUALIZADA: Ahora recolecta los nodos visuales de dentro de los Area2D
func collect_and_setup_buttons() -> void:
	all_visual_buttons.clear()

	# Iteramos sobre los Area2D para encontrar sus hijos Control (los botones visuales)
	for i in range(selectable_area_nodes.size()):
		var area_node: Area2D = selectable_area_nodes[i]
		
		# 1. Obtener el nodo visual (Control) dentro del Area2D
		var node: Control = null
		for child in area_node.get_children():
			if child is Control: # Asumimos que el botón visual es el Control
				node = child
				break
		
		if not node:
			push_warning("No se encontró el nodo visual en el Area2D %d. Saltando configuración." % i)
			continue
			
		all_visual_buttons.append(node)
		
		# 2. Aplicar Configuración visual
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
	if all_visual_buttons.is_empty(): return
	
	add_selector(Player.ControlScheme.P1)
	if GameManager.player_setup.size() > 1 and not GameManager.player_setup[1].is_empty():
		if selection.size() < 2:
			selection.resize(2)
			selection[1] = Vector2i.ZERO
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	if all_visual_buttons.is_empty(): return
	
	var sel: FlagSelector = BUTTON_GAME_MODE_SELECTOR_PREFAB.instantiate()
	sel.control_scheme = control_scheme
	selectors.append(sel)
	
	if is_instance_valid(background_node):
		background_node.add_child(sel)
		sel.z_index = 100
	else:
		return
		
	var current_idx = 0
	if control_scheme == Player.ControlScheme.P2 and selection.size() > 1:
		current_idx = selection[1].x
	
	if current_idx < all_visual_buttons.size():
		sel.position = get_cursor_position(current_idx)

# --- Navegación (Ahora usa get_cursor_position) ---
func try_navigate(index: int, direction: Vector2i) -> void:
	var current_idx := selection[index].x
	var current_node := all_visual_buttons[current_idx]
	var current_pos: Vector2 = current_node.global_position
	var best_idx := -1
	var best_dist := INF
	
	for j in range(all_visual_buttons.size()):
		if j == current_idx: continue
		
		var node := all_visual_buttons[j]
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
		# 💡 Usa get_cursor_position para mover el selector
		selectors[index].position = get_cursor_position(best_idx) 
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

# --- Actualiza etiquetas ---
func update_labels() -> void:
	for j in range(all_visual_buttons.size()):
		var node := all_visual_buttons[j]
		if node.has_method("set_highlighted"):
			node.set_highlighted(false)
			
	for i in range(selectors.size()):
		var current_idx := selection[i].x
		var current_node := all_visual_buttons[current_idx]
		if current_node.has_method("set_highlighted"):
			current_node.set_highlighted(true)

# --- Acción al seleccionar una opción ---
func handle_selection(index: int) -> void:
	var data := ScreenData.build()
	match index:
		0:
			data.set_mode("animals_quiz")
			print("🐾 Seleccionado modo: ANIMALS QUIZ")
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION, data)
		1:
			data.set_mode("soccer_quiz")
			print("⚽ Seleccionado modo: SOCCER QUIZ")
			transition_screen(SoccerGame.ScreenType.TEAM_SELECTION, data)
		2:
			print("⬅️ Regresando al menú principal")
			transition_screen(SoccerGame.ScreenType.OPTIONS_SELECTION, data)
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

# --- Funciones Generadas por el Editor (DEBEN ESTAR VACÍAS) ---

func _on_seleccion_botones_bracket_flag_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	on_area_input(0, _viewport, _event, _shape_idx)

func _on_seleccion_botones_bracket_flag_2_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	on_area_input(1, _viewport, _event, _shape_idx)

func _on_seleccion_botones_bracket_flag_3_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	on_area_input(2, _viewport, _event, _shape_idx)

func _on_seleccion_botones_bracket_flag_4_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	on_area_input(3, _viewport, _event, _shape_idx)

func _on_seleccion_botones_bracket_flag_5_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	on_area_input(4, _viewport, _event, _shape_idx)
