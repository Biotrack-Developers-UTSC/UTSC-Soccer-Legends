class_name AboutScreen
extends Screen

# --- Constantes y Datos ---

# Constantes de Preload
const GITHUB_ICON := preload("res://assets/art/ui/mainmenu/github_icon.jpg")
const BACK_ICON := preload("res://assets/art/ui/game_mode_selection/back_icon.png")

# Prefabs
const BUTTON_DISPLAY_PREFAB := preload("res://scenes/screens/quiz/boton_bracket_flag.tscn")
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

# ATENCIÓN: Usamos la nueva referencia al contenedor principal de botones.
@onready var about_container: Control = %AboutContainer 

var options: Array[String] = ["BIOTRACK", "UTSC_SOCCER", "BACK"]
var selection: Array[Vector2i] = [Vector2i.ZERO]
var selectors: Array[FlagSelector] = [] # Selector de jugador (cursor)
var all_visual_buttons: Array[SeleccionBotonBracketFlag] = [] # Lista unificada de botones

# Direcciones de movimiento para la navegación con control/teclado
var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT
	# Solo necesitamos Left/Right ya que los botones están en una fila (HBox)
}

# --- Ciclo de Vida del Screen ---

func _ready() -> void:
	if not about_container:
		push_error("ERROR: El nodo AboutContainer ('%AboutContainer') no se encontró en la escena.")
		return
		
	# 1. Recolectar y configurar los botones
	collect_and_setup_buttons()
	
	# 2. Colocar el selector (cursor) - LÓGICA DE P1/P2 ACTUALIZADA AQUÍ
	place_selectors()
	
	# 3. Actualizar resaltado
	update_labels()


func _process(_delta: float) -> void:
	# Usamos about_container
	if not about_container: return

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
			transition_screen(SoccerGame.ScreenType.MAIN_MENU) 


## 🚀 Recolecta, Configura y Estiliza los Botones
func collect_and_setup_buttons() -> void:
	# Recolecta todos los hijos directos del nuevo contenedor
	var children = about_container.get_children()
	all_visual_buttons.clear()

	# Iteramos sobre los hijos y los configuramos si son el botón correcto
	for i in range(min(children.size(), options.size())):
		# 1. Intentamos obtener el nodo y tiparlo
		var node: SeleccionBotonBracketFlag = children[i] as SeleccionBotonBracketFlag
		
		# Si la obtención falla (no es el script correcto o no es un nodo), saltamos
		if not node:
			push_warning("Child at index %d is not a SeleccionBotonBracketFlag. Skipping configuration." % i)
			continue
			
		all_visual_buttons.append(node)
		
		var key: String = options[i]
		var data: Dictionary = BUTTON_DATA[key]
		
		# 2. Aplicar Configuración
		if node.has_method("set_text"):
			node.set_text(data.text)
		if node.has_method("set_icon"):
			node.set_icon(data.icon)
		if node.has_method("set_background_color"):
			node.set_background_color(data.color)

		# 3. Conectar eventos
		if node.has_signal("pressed"):
			node.connect("pressed", Callable(self, "handle_selection").bind(i))


## 🔗 Acción al seleccionar una opción (Clic o Control)
func handle_selection(index: int) -> void:
	var key: String = options[index]
	var data: Dictionary = BUTTON_DATA[key]

	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)

	if key == "BACK":
		print("⬅️ Regresando al menú de opciones")
		# Se asume que BACK regresa a Settings/Options Menu
		transition_screen(SoccerGame.ScreenType.OPTIONS_SELECTION)
	else:
		var url: String = data.url
		if not url.is_empty():
			print("🔗 Abriendo URL: " + url)
			OS.shell_open(url)
		else:
			push_warning("❌ La opción '" + key + "' no tiene una URL válida.")

# --- Lógica de Navegación ---

## Coloca el indicador de selección
func place_selectors() -> void:
	if all_visual_buttons.is_empty(): return
	
	# Agregamos el selector del Jugador 1
	add_selector(Player.ControlScheme.P1)
	
	# LÓGICA AÑADIDA: Agrega el selector P2 si hay un segundo jugador configurado
	if GameManager.player_setup.size() > 1 and not GameManager.player_setup[1].is_empty():
		# Asegúrate de que el índice 1 del array de selección esté inicializado
		if selection.size() < 2:
			selection.resize(2)
			selection[1] = Vector2i.ZERO # Inicializa la posición de selección de P2
		add_selector(Player.ControlScheme.P2)


func add_selector(control_scheme: Player.ControlScheme) -> void:
	if all_visual_buttons.is_empty(): return

	# Instanciar el prefab del SELECTOR (cursor)
	var sel: FlagSelector = SELECTOR_PREFAB.instantiate()
	
	# 1. Asignar el esquema de control
	sel.control_scheme = control_scheme 
	
	# 2. Llamar EXPLICITAMENTE a update_indicators() para forzar la visibilidad de P1/P2
	# Esto es CRÍTICO, ya que quitamos el setget/set_control_scheme del selector.
	if sel.has_method("update_indicators"):
		sel.update_indicators() 
	
	selectors.append(sel)
	# Agregamos el selector al contenedor principal de la pantalla
	about_container.get_parent().add_child(sel) 
	
	# Mueve el selector a la posición inicial (Primer botón para P1, o la posición guardada para P2)
	var current_idx = 0
	if control_scheme == Player.ControlScheme.P2 and selection.size() > 1:
		# Si es P2, usamos su posición de selección guardada
		current_idx = selection[1].x
	
	# Mueve el selector a la posición global del botón
	if current_idx < all_visual_buttons.size():
		sel.position = all_visual_buttons[current_idx].global_position


## Intenta navegar en la dirección dada
func try_navigate(index: int, direction: Vector2i) -> void:
	if all_visual_buttons.is_empty(): return

	var current_idx := selection[index].x
	var best_idx := -1

	# Navegación izquierda/derecha
	if direction == Vector2i.LEFT:
		best_idx = wrapi(current_idx - 1, 0, all_visual_buttons.size())
	elif direction == Vector2i.RIGHT:
		best_idx = wrapi(current_idx + 1, 0, all_visual_buttons.size())
	else:
		return # Ignoramos UP/DOWN ya que es una sola fila

	if best_idx != current_idx:
		selection[index] = Vector2i(best_idx, 0)
		selectors[index].position = all_visual_buttons[best_idx].global_position
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

## Actualiza el estado visual de los botones (resaltado)
func update_labels() -> void:
	if all_visual_buttons.is_empty(): return
	
	# Deshabilita el resaltado en todos los botones
	for node in all_visual_buttons:
		if node.has_method("set_highlighted"):
			node.set_highlighted(false)

	# Resalta los botones actualmente seleccionados por P1 y P2
	for i in range(selectors.size()):
		var current_idx := selection[i].x
		if current_idx < all_visual_buttons.size():
			var current_node = all_visual_buttons[current_idx]
			if current_node.has_method("set_highlighted"):
				current_node.set_highlighted(true)
