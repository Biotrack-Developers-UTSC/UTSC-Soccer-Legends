class_name QuizGameScreen
extends Screen

const POINTS_PER_CORRECT_ANSWER := 10

# --- RECURSOS DE UI (VIDAS) ---
const TEXTURE_HEART_FULL = preload("res://assets/art/ui/quiz/heart_full.tres")
const TEXTURE_HEART_EMPTY = preload("res://assets/art/ui/quiz/heart_empty.tres")

# --- REFERENCIAS A NODOS ---
@onready var label_question: Control = $SeleccionBotonesBracketFlag 
@onready var ball: Ball = $Ball
@onready var players: Array[Player] = [$Player, $Player2]
@onready var goals: Array[Goal] = [$Goal, $Goal2, $Goal3, $Goal4]
@onready var option_buttons: Array[Control] = [
	$BotonBracketFlag, 
	$BotonBracketFlag2, 
	$BotonBracketFlag3, 
	$BotonBracketFlag4
]
@onready var hearts_ui : Array[TextureRect] = [
	%Heart1,
	%Heart2,
	%Heart3
]

# --- BANCOS DE PREGUNTAS ---
const QUESTIONS_ANIMALS : Array[Dictionary] = [
	{ "text": "¿Cuál es el animal terrestre más rápido?", "options": ["Guepardo", "León", "Elefante", "Tortuga"], "correct": 0 },
	{ "text": "¿Qué tecnología usa BioTrack?", "options": ["Microondas", "IoT y GPS", "Solo Bluetooth", "Rayos X"], "correct": 1 },
	{ "text": "¿Cuál es el rey de la selva?", "options": ["Tigre", "Oso", "León", "Lobo"], "correct": 2 },
	{ "text": "¿Qué animal tiene trompa?", "options": ["Jirafa", "Elefante", "Hipopótamo", "Rinoceronte"], "correct": 1 },
	{ "text": "¿Qué detecta el sensor PIR?", "options": ["Humedad", "Sonido", "Movimiento", "Luz"], "correct": 2 },
	{ "text": "¿Cuál es el mamífero más grande?", "options": ["Ballena Azul", "Elefante", "Tiburón", "Jirafa"], "correct": 0 },
	{ "text": "¿Qué animal es nocturno?", "options": ["Águila", "Búho", "Perro", "Canario"], "correct": 1 },
	{ "text": "¿Qué comen los herbívoros?", "options": ["Carne", "Insectos", "Plantas", "Peces"], "correct": 2 },
	{ "text": "¿Para qué sirve el collar GPS?", "options": ["Para jugar", "Rastrear ubicación", "Dar calor", "Alimentar"], "correct": 1 },
	{ "text": "¿Cuántas patas tiene una araña?", "options": ["6", "4", "8", "10"], "correct": 2 },
	{ "text": "¿Qué animal es un anfibio?", "options": ["Rana", "Cocodrilo", "Pez", "Gato"], "correct": 0 },
	{ "text": "¿Cuál es el objetivo de BioTrack?", "options": ["Cazar", "Vender", "Conservación", "Cocinar"], "correct": 2 },
	{ "text": "¿Qué animal vuela y es mamífero?", "options": ["Pato", "Murciélago", "Águila", "Avestruz"], "correct": 1 },
	{ "text": "¿Dónde viven los osos polares?", "options": ["Selva", "Desierto", "Ártico", "Sabana"], "correct": 2 },
	{ "text": "¿Qué alerta emite el Arduino?", "options": ["Luz y Sonido", "Agua", "Humo", "Nada"], "correct": 0 }
]

const QUESTIONS_SOCCER : Array[Dictionary] = [
	{ "text": "¿Quién es el portero de Argentina?", "options": ["Messi", "Otamendi", "E. Martinez", "Di Maria"], "correct": 2 },
	{ "text": "¿Qué potencia tiene Mbappé?", "options": ["100", "150", "185", "200"], "correct": 2 },
	{ "text": "¿En qué selección juega Pulisic?", "options": ["USA", "Inglaterra", "Brasil", "Francia"], "correct": 0 },
	{ "text": "¿Cuántos jugadores hay en cancha?", "options": ["9", "10", "11", "12"], "correct": 2 },
	{ "text": "¿Quién es conocido como 'El Rey'?", "options": ["Maradona", "Pelé", "Messi", "CR7"], "correct": 1 },
	{ "text": "¿Quién es el capitán de Portugal?", "options": ["Pepe", "Bruno", "Ronaldo", "Felix"], "correct": 2 },
	{ "text": "¿Qué país ganó el mundial 2022?", "options": ["Francia", "Brasil", "Argentina", "Alemania"], "correct": 2 },
	{ "text": "¿Quién es el portero de Alemania?", "options": ["M. Neuer", "Ter Stegen", "Leno", "Kahn"], "correct": 0 },
	{ "text": "¿Qué posición juega Harry Kane?", "options": ["Defensa", "Portero", "Delantero", "Medio"], "correct": 2 },
	{ "text": "¿En qué equipo juega Neymar?", "options": ["Argentina", "Brasil", "España", "Italia"], "correct": 1 },
	{ "text": "¿Cuánto dura un partido estándar?", "options": ["45 min", "60 min", "90 min", "100 min"], "correct": 2 },
	{ "text": "¿Qué tarjeta expulsa al jugador?", "options": ["Amarilla", "Roja", "Azul", "Verde"], "correct": 1 },
	{ "text": "¿Quién juega en España?", "options": ["Morata", "Messi", "Neymar", "Kane"], "correct": 0 },
	{ "text": "¿Qué significa VAR?", "options": ["Video Assistant Referee", "Vamos A Reir", "Video Area Real", "Vision Art"], "correct": 0 },
	{ "text": "¿Desde dónde se tira un penal?", "options": ["9 pasos", "11 metros", "Media cancha", "Corner"], "correct": 1 }
]

# --- VARIABLES DE ESTADO ---
var current_questions_set : Array[Dictionary] = []
var current_round := 0
var current_scores := [0, 0]
var is_waiting_for_answer := false
var spawn_positions : Array[Vector2] = []
var lives : int = 3
var current_correct_goal_index : int = -1

func _ready() -> void:
	randomize()
	
	spawn_positions.append(players[0].position)
	if players.size() > 1: spawn_positions.append(players[1].position)
	
	ball.z_index = 10 
	for p in players:
		p.z_index = 5
	
	select_theme_mode()
	setup_goals()
	setup_players()
	
	lives = 3
	update_hearts_display()
	
	start_round()

func select_theme_mode() -> void:
	var pool = QUESTIONS_ANIMALS.duplicate()
	pool.shuffle()
	var amount = min(5, pool.size())
	current_questions_set = pool.slice(0, amount)
	print("🐾 Modo Animales Activado (Base - 5 Preguntas)")

func setup_goals() -> void:
	for i in range(goals.size()):
		var goal = goals[i]
		var scoring_area = goal.get_scoring_area()
		if scoring_area.body_entered.is_connected(goal.on_ball_enter_scoring_area):
			scoring_area.body_entered.disconnect(goal.on_ball_enter_scoring_area)
		
		if not scoring_area.body_entered.is_connected(on_answer_submitted):
			scoring_area.body_entered.connect(on_answer_submitted.bind(i))

func setup_players() -> void:
	var p1_country = GameManager.player_setup[0]
	if p1_country == "": p1_country = "Argentina" 
	var p2_country = "Brazil" 
	if GameManager.player_setup.size() > 1 and GameManager.player_setup[1] != "":
		p2_country = GameManager.player_setup[1]

	var p1_squad = DataLoader.get_squad(p1_country)
	var p2_squad = DataLoader.get_squad(p2_country)
	
	var p1_data = p1_squad[5] if p1_squad.size() > 5 else p1_squad[0]
	var p2_data = p2_squad[5] if p2_squad.size() > 5 else p2_squad[0]

	players[0].initialize(spawn_positions[0], spawn_positions[0], ball, goals[0], goals[3], p1_data, p1_country)
	players[0].set_control_scheme(Player.ControlScheme.P1)
	players[0].is_dummy = false
	players[0].set_shader_properties()
	
	if players.size() > 1:
		players[1].initialize(spawn_positions[1], spawn_positions[1], ball, goals[3], goals[0], p2_data, p2_country)
		players[1].set_shader_properties()
		var is_cpu_mode = false
		if screen_data != null and screen_data.has_meta("is_p2_dummy"):
			is_cpu_mode = screen_data.get_meta("is_p2_dummy")
		if is_cpu_mode:
			players[1].set_control_scheme(Player.ControlScheme.CPU)
			players[1].is_dummy = true 
		else:
			players[1].set_control_scheme(Player.ControlScheme.P2)
			players[1].is_dummy = false

func start_round() -> void:
	if current_round >= current_questions_set.size():
		finish_quiz()
		return
		
	var q = current_questions_set[current_round]
	
	if label_question.has_node("Label"):
		var lbl = label_question.get_node("Label")
		lbl.text = q["text"]
		lbl.modulate = Color(1, 1, 1)
		label_question.self_modulate = Color(1, 1, 1) 
	elif label_question.has_method("set_text"):
		label_question.set_text(q["text"])
		label_question.modulate = Color(1, 1, 1)
	
	var indices = [0, 1, 2, 3]
	indices.shuffle()
	
	var original_correct_idx = q["correct"]
	
	for i in range(option_buttons.size()):
		if i < q["options"].size():
			var target_btn_idx = indices[i]
			if option_buttons[target_btn_idx].has_method("set_text"):
				option_buttons[target_btn_idx].set_text(q["options"][i])
			option_buttons[target_btn_idx].visible = true
			
			if i == original_correct_idx:
				current_correct_goal_index = target_btn_idx
		else:
			option_buttons[indices[i]].visible = false

	reset_positions()
	is_waiting_for_answer = true

func reset_positions() -> void:
	ball.stop()
	ball.position = Vector2(135, 120) 
	ball.height = 0
	ball.switch_state(Ball.State.FREEFORM)
	ball.z_index = 10
	ball.visible = true
	
	players[0].position = spawn_positions[0]
	players[0].velocity = Vector2.ZERO
	players[0].switch_state(Player.State.MOVING) 
	
	if players.size() > 1:
		players[1].position = spawn_positions[1]
		players[1].velocity = Vector2.ZERO
		players[1].switch_state(Player.State.MOVING)

func on_answer_submitted(body: Node2D, goal_index: int) -> void:
	if not is_waiting_for_answer: return
	if not body is Ball: return
	
	is_waiting_for_answer = false
	SoundPlayer.play(SoundPlayer.Sound.WHISTLE)
	
	if goal_index == current_correct_goal_index:
		handle_correct_answer()
		current_round += 1
		get_tree().create_timer(2.0).timeout.connect(start_round)
	else:
		handle_incorrect_answer()

func handle_correct_answer() -> void:
	print("✅ ¡CORRECTO!")
	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
	
	# En modo Co-Op, sumamos puntos a ambos o simplemente al índice 0 como acumulador global
	# Para mantener compatibilidad, sumamos según quién anote, pero al final mostraremos la suma.
	if ball.carrier != null and ball.carrier.control_scheme == Player.ControlScheme.P2:
		current_scores[1] += POINTS_PER_CORRECT_ANSWER
	else:
		current_scores[0] += POINTS_PER_CORRECT_ANSWER
	
	if label_question.has_node("Label"):
		label_question.get_node("Label").text = "¡CORRECTO!"
		label_question.get_node("Label").modulate = Color(0, 1, 0)
	elif label_question.has_method("set_text"):
		label_question.set_text("¡CORRECTO!")
		label_question.modulate = Color(0, 1, 0)

# --- FUNCIÓN AUXILIAR: MODE CO-OP (SUMA TOTAL) ---
func _get_score_text_for_ui(is_game_over: bool) -> String:
	var total_questions = current_questions_set.size()
	
	# SUMA COOPERATIVA: Puntos P1 + Puntos P2
	var total_points = current_scores[0] + current_scores[1]
	var total_correct_answers = total_points / POINTS_PER_CORRECT_ANSWER
	
	# Texto único para todo el equipo
	var score_line = "ACIERTOS: %d / %d" % [total_correct_answers, total_questions]
	
	var title = "GAME OVER" if is_game_over else "QUIZ COMPLETADO"
	
	if is_game_over:
		return "%s\n%s" % [title, score_line]
	else:
		return "%s\n%s\nVIDAS RESTANTES: %d" % [title, score_line, lives]

func handle_incorrect_answer() -> void:
	lives -= 1
	update_hearts_display()
	
	if lives <= 0:
		# === GAME OVER ===
		print("💀 GAME OVER")
		SoundPlayer.play(SoundPlayer.Sound.HURT)
		
		var msg = _get_score_text_for_ui(true)
		
		if label_question.has_node("Label"):
			var lbl = label_question.get_node("Label")
			lbl.text = msg
			lbl.modulate = Color(1, 0, 0) # Rojo
		elif label_question.has_method("set_text"):
			label_question.set_text(msg)
			label_question.modulate = Color(1, 0, 0)
		
		get_tree().create_timer(3.0).timeout.connect(func():
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)
		)
		
	else:
		print("❌ ¡INCORRECTO!")
		SoundPlayer.play(SoundPlayer.Sound.HURT)
		
		if label_question.has_node("Label"):
			var lbl = label_question.get_node("Label")
			lbl.text = "¡INCORRECTO!"
			lbl.modulate = Color(1, 0, 0)
		elif label_question.has_method("set_text"):
			label_question.set_text("¡INCORRECTO!")
			label_question.modulate = Color(1, 0, 0)
			
		get_tree().create_timer(2.0).timeout.connect(start_round)

func update_hearts_display() -> void:
	for i in range(hearts_ui.size()):
		if i < lives:
			hearts_ui[i].texture = TEXTURE_HEART_FULL
		else:
			hearts_ui[i].texture = TEXTURE_HEART_EMPTY

func finish_quiz() -> void:
	print("🏁 Quiz Terminado.")
	
	var final_msg = _get_score_text_for_ui(false)
	
	if label_question.has_node("Label"):
		var lbl = label_question.get_node("Label")
		lbl.text = final_msg
		lbl.modulate = Color(0, 0, 0) # Texto Negro
		label_question.self_modulate = Color(1, 0.84, 0) # Fondo Dorado
		
	elif label_question.has_method("set_text"):
		label_question.set_text(final_msg)
		label_question.modulate = Color(1, 0.84, 0)

	get_tree().create_timer(4.0).timeout.connect(func():
		transition_screen(SoccerGame.ScreenType.MAIN_MENU)
	)
