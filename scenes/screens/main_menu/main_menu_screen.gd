class_name MainMenuScreen
extends Screen

const BUTTON_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_selector.tscn")
const MENU_TEXTURES := [
	[preload("res://assets/art/ui/mainmenu/1-player.png"), preload("res://assets/art/ui/mainmenu/1-player-selected.png")],
	[preload("res://assets/art/ui/mainmenu/2-players.png"), preload("res://assets/art/ui/mainmenu/2-players-selected.png")]
]

# Nota: Asumimos que $SinglePlayerArea2D y $TwoPlayerArea2D son los nombres CORRECTOS de los nodos Area2D.
@onready var selectable_menu_nodes : Array[Node2D] = [
	%SinglePlayerArea2D, # Índice 0
	%TwoPlayerArea2D, # Índice 1
	%BotonBracketFlagArea2D, # Índice 2: Botón de salir
]

@onready var selection_icon : TextureRect = %SelectionIcon

var current_selected_index := 0
var is_active := false
var selector_exit : FlagSelector = null

func _ready() -> void:
	# 🌟 CONEXIONES DE EVENTOS DE TOQUE/CLIC (EXISTENTES)
	%SinglePlayerArea2D.input_event.connect(on_single_player_input.bind())
	%TwoPlayerArea2D.input_event.connect(on_two_player_input.bind())
	%BotonBracketFlagArea2D.input_event.connect(on_exit_button_input.bind())
	
	# 🌟 CONEXIONES DE HOVER (RATÓN)
	%SinglePlayerArea2D.mouse_entered.connect(on_mouse_enter_1p.bind())
	%SinglePlayerArea2D.mouse_exited.connect(on_mouse_exit_1p.bind())
	%TwoPlayerArea2D.mouse_entered.connect(on_mouse_enter_2p.bind())
	%TwoPlayerArea2D.mouse_exited.connect(on_mouse_exit_2p.bind())
	%BotonBracketFlagArea2D.mouse_entered.connect(on_mouse_enter_exit.bind())
	%BotonBracketFlagArea2D.mouse_exited.connect(on_mouse_exit_exit.bind())
	
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
	# Añadir soporte para ui_back (cancelar/salir)
	elif Input.is_action_just_pressed("ui_cancel"):
		change_selected_index(2)
		submit_selection()

func refresh_ui() -> void:
	selection_icon.visible = is_active 

	for i in range(selectable_menu_nodes.size()):
		var area_node = selectable_menu_nodes[i] # Area2D (contenedor)
		
		# 1. OBTENER EL NODO VISUAL Y LA POSICIÓN BASE
		var visual_node : Node = null
		if area_node.get_child_count() > 0:
			visual_node = area_node.get_child(0) 
		
		# 🎯 Cálculo de la Posición Local Base
		# Sumamos la posición LOCAL del Area2D + la posición LOCAL del visual_node (su hijo)
		var pos_to_use: Vector2 = area_node.position
		if visual_node:
			# Sumamos el offset del Area2D más el offset del visual_node dentro del Area2D
			pos_to_use = area_node.position + visual_node.position
		
		
		if i < MENU_TEXTURES.size(): 
			# --- 🎯 1P y 2P (TextureRect) ---
			if visual_node is TextureRect:
				var texture_node: TextureRect = visual_node
				
				if current_selected_index == i:
					texture_node.texture = MENU_TEXTURES[i][1] # Seleccionado
					# Balón al lado del botón
					selection_icon.position = pos_to_use + Vector2.LEFT * 25 
				else:
					texture_node.texture = MENU_TEXTURES[i][0] # Normal
		
		else: 
			# --- 🔹 BOTÓN SALIR (Índice 2) ---
			# El problema de que no aparece el texto es porque el nodo visual es BotonBracketFlag.
			if visual_node != null and visual_node.has_method("set_highlighted"):
				var exit_button: BotonBracketFlag = visual_node as BotonBracketFlag
				
				if current_selected_index == i:
					exit_button.set_highlighted(true)
					# Balón al lado del botón
					selection_icon.position = pos_to_use + Vector2.LEFT * 25

					if selector_exit == null:
						place_selector()
					
					# Posicionar el marco selector y hacerlo visible
					selector_exit.position = pos_to_use
					selector_exit.visible = true
				else:
					exit_button.set_highlighted(false)
			
	# ⚠️ Ocultar selector de salida si la selección no es el botón de salir
	if current_selected_index != 2 and selector_exit != null:
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
		
		if current_selected_index == 1: # 2 Players
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

# ------------------------------------------------------------------
# 🎯 MANEJADORES DE INPUT DE TOQUE/CLIC (CONECTADOS POR CÓDIGO)
# ------------------------------------------------------------------

func _handle_touch_submission(node_index: int, event: InputEvent) -> void:
	# Verificamos si es un evento de clic/toque que se acaba de presionar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 1. Fijar el foco al elemento tocado
		change_selected_index(node_index)
		
		# 2. Forzar la selección del elemento
		submit_selection()
		
		# 🎯 CORRECCIÓN: Usar get_viewport() para acceder a set_input_as_handled()
		get_viewport().set_input_as_handled()

# Conexión para el botón 1 Player (Índice 0)
func on_single_player_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_touch_submission(0, event)

# Conexión para el botón 2 Players (Índice 1)
func on_two_player_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_touch_submission(1, event)

# Conexión para el botón Salir (Índice 2)
func on_exit_button_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	_handle_touch_submission(2, event)

# --- MANEJADORES DE HOVER (RATÓN) ---

func _handle_mouse_enter(node_index: int) -> void:
	# Si el menú está activo, simulamos la navegación al índice del botón
	if is_active:
		change_selected_index(node_index)

func _handle_mouse_exit(node_index: int) -> void:
	# Si el ratón sale, no hacemos nada a menos que desees que vuelva
	# al estado inicial, pero generalmente es mejor dejarlo en el estado de 'hover'.
	pass 

# Conexiones 1P
func on_mouse_enter_1p() -> void:
	_handle_mouse_enter(0)

func on_mouse_exit_1p() -> void:
	_handle_mouse_exit(0)

# Conexiones 2P
func on_mouse_enter_2p() -> void:
	_handle_mouse_enter(1)

func on_mouse_exit_2p() -> void:
	_handle_mouse_exit(1)

# Conexiones Salir
func on_mouse_enter_exit() -> void:
	_handle_mouse_enter(2)
func on_mouse_exit_exit() -> void:
	_handle_mouse_exit(2)
