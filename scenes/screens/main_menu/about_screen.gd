class_name AboutScreen
extends Screen

# --- Constantes y Datos ---

# Constantes de Preload
const GITHUB_ICON := preload("res://assets/art/ui/mainmenu/github_icon.jpg")
const BACK_ICON := preload("res://assets/art/ui/game_mode_selection/back_icon.png")

# Prefabs
const SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_game_mode_selector.tscn")

# Datos para los botones
const BUTTON_DATA = {
	"BIOTRACK": {
		"text": "Biotrack Repo",
		"icon": GITHUB_ICON,
		"url": "https://github.com/Biotrack-Developers-UTSC/Biotrack",
		"color": Color8(20, 60, 150) # Azul Rey Profundo
	},
	"UTSC_SOCCER": {
		"text": "Game Repo",
		"icon": GITHUB_ICON,
		"url": "https://github.com/Biotrack-Developers-UTSC/UTSC-Soccer-Legends",
		"color": Color8(0, 100, 0) # Verde Oscuro
	},
	"BACK": {
		"text": "Settings Menu",
		"icon": BACK_ICON,
		"url": "",
		"color": Color8(153, 102, 230) # Morado para "Back"
	}
}

# --- Nodos y Variables de Navegación ---

@onready var background_node: TextureRect = %Background
@onready var about_container: Control = %AboutContainer

# 💡 1. REFERENCIAS A LOS NODOS AREA2D (Los que detectan input)
@onready var selectable_area_nodes: Array[Area2D] = [
	%SeleccionBotonesBracketFlagArea2D,
	%SeleccionBotonesBracketFlag2Area2D,
	%SeleccionBotonesBracketFlag3Area2D
]

var options: Array[String] = ["BIOTRACK", "UTSC_SOCCER", "BACK"]
var selection: Array[Vector2i] = [Vector2i.ZERO]
var selectors: Array[FlagSelector] = [] # Selector de jugador (cursor)
var all_visual_buttons: Array[Control] = [] # Lista unificada de nodos visuales (Control)

var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT
}

# --- Ciclo de Vida del Screen ---

func _ready() -> void:
	if not background_node:
		push_error("ERROR: El nodo Background ('%Background') no se encontró en la escena.")
		return
		
	# 1. Recolectar botones visuales (hijos de Area2D) y configurarlos
	collect_and_setup_buttons()
	
	# 2. Conectar los eventos de mouse/clic/hover de los Area2D
	connect_input_events()
	
	# 3. Colocar el selector (cursor)
	place_selectors()
	
	# 4. Actualizar resaltado
	update_labels()


func _process(_delta: float) -> void:
	if selectors.is_empty(): return

	for i in range(selectors.size()):
		var scheme: Player.ControlScheme = selectors[i].control_scheme

		for action in move_dirs.keys():
			if KeyUtils.is_action_just_pressed(scheme, action):
				try_navigate(i, move_dirs[action])

		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.SHOOT):
			SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
			handle_selection(selection[i].x)

		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.PASS):
			SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
			# El botón "BACK" es el último índice (2)
			var back_index = options.size() - 1
			
			if selection[i].x != back_index:
				# Si el foco NO está en BACK, navegamos hacia atrás (teclado/mando)
				try_navigate(i, Vector2i.RIGHT) # O simplemente navegamos al último botón
			
			# Ejecutamos la acción de regreso
			handle_selection(back_index)

# ----------------------------------------------------------------------
# 🎯 FUNCIONES DE POSICIÓN Y CURSOR (Adaptada de SettingSelectionScreen)
# ----------------------------------------------------------------------

func get_cursor_position(index: int) -> Vector2:
	if index >= all_visual_buttons.size():
		return Vector2.ZERO

	# Usamos el nodo visual para calcular la posición
	var visual_node: Control = all_visual_buttons[index]

	var base_pos: Vector2 = visual_node.global_position
	
	# Transforma la posición GLOBAL del botón a la posición LOCAL del Background (donde está el selector)
	if is_instance_valid(background_node):
		base_pos = background_node.get_global_transform_with_canvas().affine_inverse() * base_pos

	return base_pos

# ----------------------------------------------------------------------
# 🎯 LÓGICA DE CONEXIÓN Y MANEJO DE TOQUE/HOVER (Mismos que Settings)
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
	# Usamos la acción SHOOT (si el ratón está mapeado a SHOOT/clic izquierdo)
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
# 🔹 LÓGICA DE NAVEGACIÓN Y MENÚ
# ----------------------------------------------------------------------

## 🚀 Recolecta, Configura y Estiliza los Botones
func collect_and_setup_buttons() -> void:
	all_visual_buttons.clear()

	# Iteramos sobre los Area2D para encontrar sus hijos Control (los botones visuales)
	for i in range(selectable_area_nodes.size()):
		var area_node: Area2D = selectable_area_nodes[i]
		
		# 1. Obtener el nodo visual (Control) dentro del Area2D
		var node: Control = null
		for child in area_node.get_children():
			# Asumimos que SeleccionBotonesBracketFlag es el Control visual
			if child is Control: 
				node = child
				break
		
		if not node:
			push_warning("No se encontró el nodo visual dentro del Area2D en índice %d." % i)
			continue
			
		all_visual_buttons.append(node)
		
		var key: String = options[i]
		var data: Dictionary = BUTTON_DATA[key]
		
		# 2. Aplicar Configuración visual
		if node.has_method("set_text"):
			node.set_text(data.text)
		if node.has_method("set_icon"):
			node.set_icon(data.icon)
		if node.has_method("set_background_color"):
			node.set_background_color(data.color)


## 🔗 Acción al seleccionar una opción (Clic o Control)
func handle_selection(index: int) -> void:
	var key: String = options[index]
	var data: Dictionary = BUTTON_DATA[key]

	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)

	if key == "BACK":
		transition_screen(SoccerGame.ScreenType.OPTIONS_SELECTION)
	else:
		var url: String = data.url
		if not url.is_empty():
			OS.shell_open(url)
		else:
			push_warning("❌ La opción '" + key + "' no tiene una URL válida.")


## Coloca el indicador de selección
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

	var sel: FlagSelector = SELECTOR_PREFAB.instantiate()
	
	sel.control_scheme = control_scheme
	
	if sel.has_method("update_indicators"):
		sel.update_indicators()
	
	selectors.append(sel)
	# Agregado al Background, que es el padre de los Area2D
	background_node.add_child(sel) 
	sel.z_index = 100 # Asegura que esté por encima del Background
	
	var current_idx = 0
	if control_scheme == Player.ControlScheme.P2 and selection.size() > 1:
		current_idx = selection[1].x
	
	if current_idx < all_visual_buttons.size():
		sel.position = get_cursor_position(current_idx)

# ... (try_navigate y update_labels, que ahora usan las nuevas funciones)

## Intenta navegar en la dirección dada
func try_navigate(index: int, direction: Vector2i) -> void:
	if all_visual_buttons.is_empty(): return

	var current_idx := selection[index].x
	var best_idx := -1

	if direction == Vector2i.LEFT:
		best_idx = wrapi(current_idx - 1, 0, all_visual_buttons.size())
	elif direction == Vector2i.RIGHT:
		best_idx = wrapi(current_idx + 1, 0, all_visual_buttons.size())
	else:
		return

	if best_idx != current_idx:
		selection[index] = Vector2i(best_idx, 0)
		selectors[index].position = get_cursor_position(best_idx)
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

## Actualiza el estado visual de los botones (resaltado)
func update_labels() -> void:
	if all_visual_buttons.is_empty(): return
	
	for node in all_visual_buttons:
		if node.has_method("set_highlighted"):
			node.set_highlighted(false)

	for i in range(selectors.size()):
		var current_idx := selection[i].x
		if current_idx < all_visual_buttons.size():
			var current_node = all_visual_buttons[current_idx]
			if current_node.has_method("set_highlighted"):
				current_node.set_highlighted(true)

# --- Funciones Generadas por el Editor (DEBEN ESTAR VACÍAS) ---
# La lógica de HOVER y CLIC se maneja a través de connect_input_events.

func _on_seleccion_botones_bracket_flag_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass

func _on_seleccion_botones_bracket_flag_2_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass

func _on_seleccion_botones_bracket_flag_3_area_2d_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	pass
