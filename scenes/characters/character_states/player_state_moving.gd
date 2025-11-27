class_name PlayerStateMoving
extends PlayerState

func _process(_delta: float) -> void:
	# 1. CASO CPU ACTIVA (Juega normal)
	if player.control_scheme == Player.ControlScheme.CPU and not player.is_dummy:
		ai_behavior.process_ai()

	# 2. CASO CPU DUMMY (Se queda quieto)
	elif player.control_scheme == Player.ControlScheme.CPU and player.is_dummy:
		player.velocity = Vector2.ZERO # Forzamos velocidad cero

	# 3. CASO HUMANO (P1 o P2)
	else:
		handle_human_movement()

	# Animaciones y dirección
	player.set_movement_animation()
	player.set_heading()

func handle_human_movement() -> void:
	var direction := Vector2.ZERO
	
	# --- LÓGICA DE MOVIMIENTO DE 8 DIRECCIONES (TÁCTIL VS TECLADO) ---
	# 1. Intentar usar el vector de movimiento táctil (proveniente de MobileControls)
	if player.mobile_movement_vector != Vector2.ZERO:
		direction = player.mobile_movement_vector
	# 2. Si el vector táctil es cero (nadie toca la pantalla), usar la entrada de teclado
	else:
		direction = KeyUtils.get_input_vector(player.control_scheme)
	
	player.velocity = direction * player.speed
	
	if player.velocity != Vector2.ZERO:
		teammate_detection_area.rotation = player.velocity.angle()

	# --- LÓGICA DE ACCIONES (SHOOT/PASS) ---
	# Las acciones siguen usando KeyUtils para detectar si los botones A/B están siendo presionados.

	if KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.PASS):
		if player.has_ball():
			transition_state(Player.State.PASSING)
		elif can_teammate_pass_ball():
			ball.carrier.get_pass_request(player)
		else:
			player.swap_requested.emit(player)

	elif KeyUtils.is_action_just_pressed(player.control_scheme, KeyUtils.Action.SHOOT):
		if player.has_ball():
			transition_state(Player.State.PREPPING_SHOT)
		elif ball.can_air_interact():
			if player.velocity == Vector2.ZERO:
				if player.is_facing_target_goal():
					transition_state(Player.State.VOLLEY_KICK)
				else:
					transition_state(Player.State.BICYCLE_KICK)
			else:
				transition_state(Player.State.HEADER)
		elif player.velocity != Vector2.ZERO:
			state_transition_requested.emit(Player.State.TACKLING)

func can_carry_ball() -> bool:
	return player.role != Player.Role.GOALIE

func can_teammate_pass_ball() -> bool:
	return ball.carrier != null and ball.carrier.country == player.country and ball.carrier.control_scheme == Player.ControlScheme.CPU
	
func can_pass() -> bool:
	return true
