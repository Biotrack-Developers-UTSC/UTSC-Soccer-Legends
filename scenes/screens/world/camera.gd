class_name Camera
extends Camera2D

const DISTANCE_TARGET := 100.0
const SMOOTHING_BALL_CARRIED := 2
const SMOOTHING_BALL_DEFAULT := 8
const DURATION_SHAKE := 120
const SHAKE_INTENSITY := 5

var is_shaking := false
var time_start_shake := Time.get_ticks_msec()
var is_resetting_or_kickoff := false # 🌟 NUEVA VARIABLE DE ESTADO

@export var ball : Ball

func _init() -> void:
	GameEvents.impact_received.connect(on_impact_received.bind())
	# 🌟 CONECTAR A EVENTOS DE RESET/KICKOFF
	GameEvents.team_reset.connect(on_team_reset.bind())
	GameEvents.kickoff_ready.connect(on_kickoff_ready.bind())
	GameEvents.kickoff_started.connect(on_kickoff_started.bind()) # 🎯 CAMBIO: CONEXIÓN A KICKOFF_STARTED

func _process(_delta: float) -> void:
	# 🌟 Lógica de seguimiento modificada
	if is_resetting_or_kickoff:
		# Durante el reset/kickoff, forzar el seguimiento de la posición central del balón
		position = ball.position 
		position_smoothing_speed = SMOOTHING_BALL_DEFAULT
	elif ball.carrier != null:
		# Si hay un portador y NO estamos en reset, seguir al portador
		position = ball.carrier.position + ball.carrier.heading * DISTANCE_TARGET
		position_smoothing_speed = SMOOTHING_BALL_CARRIED
	else:
		# Por defecto, seguir al balón
		position = ball.position
		position_smoothing_speed = SMOOTHING_BALL_DEFAULT
		
	# Lógica de Shake (no cambia)
	if is_shaking and Time.get_ticks_msec() - time_start_shake < DURATION_SHAKE:
		offset = Vector2(randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY), randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY))
	else:
		is_shaking = false
		offset = Vector2.ZERO

func on_impact_received(_impact_position: Vector2, _is_high_impact: bool) -> void:
	if _is_high_impact:
		is_shaking = true
		time_start_shake = Time.get_ticks_msec()

# 🌟 NUEVOS MÉTODOS PARA MANEJAR EL ESTADO DE RESET
func on_team_reset() -> void:
	# Se activa cuando el juego entra en GameStateReset, antes de que los jugadores se muevan.
	is_resetting_or_kickoff = true

func on_kickoff_ready() -> void:
	# Se activa cuando todos los jugadores llegan a su posición de kickoff (GameStateReset/Kickoff)
	is_resetting_or_kickoff = true # Mantenemos activo hasta que inicie el juego

func on_kickoff_started() -> void:
	# Este evento se emite desde GameStateKickoff cuando P1/P2 presiona PASS.
	# Aquí es donde volvemos al seguimiento normal.
	is_resetting_or_kickoff = false
