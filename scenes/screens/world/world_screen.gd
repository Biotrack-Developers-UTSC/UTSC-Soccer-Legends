class_name WorldScreen
extends Screen

@onready var game_over_timer := %GameOverTimer

# 🌟 1. REFERENCIA AL PREFAB DE CONTROLES
# Asegúrate de que esta ruta sea correcta:
const MOBILE_CONTROLS_PREFAB := preload("res://scenes/ui/mobile_controls.tscn")
var mobile_controls_instance: CanvasLayer = null

# 🌟 FUNCIÓN HELPER PARA DETECTAR ENTORNO TÁCTIL (Móvil/Web)
func is_touch_environment() -> bool:
	var os_name := OS.get_name()
	# Verifica si estamos en Android, iOS, o en Web (asumiendo que la exportación web es táctil)
	return os_name == "Android" or os_name == "iOS" or os_name == "Web"

func _ready() -> void:
	game_over_timer.timeout.connect(on_transition.bind())
	GameEvents.game_over.connect(on_game_over.bind())
	
	# 🎯 2. INSTANCIAR Y AÑADIR CONTROLES MÓVILES
	# Usamos la nueva función para determinar si necesitamos la UI táctil.
	if is_touch_environment():
		mobile_controls_instance = MOBILE_CONTROLS_PREFAB.instantiate()
		# Añadirlo como hijo de WorldScreen. El CanvasLayer lo mantendrá fijo.
		add_child(mobile_controls_instance)
		
	GameManager.start_game()
	

func on_game_over(_winner: String) -> void:
	game_over_timer.start()

func on_transition() -> void:
	# 🎯 3. LIMPIAR CONTROLES ANTES DE LA TRANSICIÓN
	if mobile_controls_instance:
		mobile_controls_instance.queue_free()
		mobile_controls_instance = null
	
	if screen_data.tournament != null and GameManager.current_match.winner == GameManager.player_setup[0]:
		screen_data.tournament.advance()
		transition_screen(SoccerGame.ScreenType.TOURNAMENT, screen_data)
	else:
		transition_screen(SoccerGame.ScreenType.MAIN_MENU)
