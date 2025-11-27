class_name GameStateKickoff
extends GameState

var valid_control_schemes := []
var time_since_entered := 0.0 # 🌟 Nueva variable para tracking de tiempo
const INPUT_DELAY := 0.2 # 🌟 Ignorar input por 0.2 segundos

func _enter_tree() -> void:
	var country_starting := state_data.country_scored_on
	if country_starting.is_empty():
		country_starting = manager.current_match.country_home
	# Reiniciar la lista de esquemas de control válidos
	valid_control_schemes.clear()
	var is_single_player := manager.is_single_player()
	# 1. Determinar el esquema de control del equipo que saca (P1 si es humano, o CPU/P2 si aplica)
	# A. Si el equipo que saca es el equipo de P1 (country_starting == P1's country)
	if country_starting == manager.player_setup[0]:
		valid_control_schemes.append(Player.ControlScheme.P1)
	# B. Si el equipo que saca es el equipo de P2 Humano
	# (Solo ocurre en modo Versus (P1 vs P2), ya que en 1P vs CPU P2 es CPU y no necesita input)
	elif not is_single_player and country_starting == manager.player_setup[1]:
		valid_control_schemes.append(Player.ControlScheme.P2)
	# C. Si el juego es Single Player (1P vs CPU), P1 siempre puede iniciar el saque
	#    para evitar que el juego se detenga esperando el input de la CPU o P2.
	if is_single_player and not valid_control_schemes.has(Player.ControlScheme.P1):
		# Agregamos P1 si es Single Player y P1 no es el equipo que saca.
		valid_control_schemes.append(Player.ControlScheme.P1)
		
	# D. Fallback: si no se encontró ningún esquema válido (e.g., inicio de partido, o equipos no configurados)
	if valid_control_schemes.is_empty():
		valid_control_schemes.append(Player.ControlScheme.P1)
	
	# 🌟 Inicializar el tiempo al entrar al estado
	time_since_entered = 0.0 

func _process(_delta: float) -> void:
	# 🌟 Acumular tiempo
	time_since_entered += _delta
	
	# 🌟 Ignorar Input si está dentro del delay (previene el disparo automático por inputs residuales)
	if time_since_entered < INPUT_DELAY:
		return
		
	for control_scheme : Player.ControlScheme in valid_control_schemes:
		if KeyUtils.is_action_just_pressed(control_scheme, KeyUtils.Action.PASS):
			SoundPlayer.play(SoundPlayer.Sound.WHISTLE)
			GameEvents.kickoff_started.emit()
			transition_state(GameManager.State.IN_PLAY)
