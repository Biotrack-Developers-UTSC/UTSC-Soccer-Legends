class_name Tournament
extends Node

enum Stage { QUARTER_FINALS, SEMI_FINALS, FINALS, COMPLETE }

var current_stage: Stage = Stage.QUARTER_FINALS
var matches := {}
var winner := ""
var is_custom := false

func _init(custom_mode: bool = false) -> void:
	is_custom = custom_mode
	if is_custom:
		matches = { Stage.FINALS: [] }
		current_stage = Stage.FINALS
		return
	
	# Obtener países y filtrar "DEFAULT"
	var raw_countries := DataLoader.get_countries()
	var valid_countries: Array[String] = []
	for c in raw_countries:
		if c != "DEFAULT" and c != "":
			valid_countries.append(c)
			
	valid_countries.shuffle()
	create_bracket(Stage.QUARTER_FINALS, valid_countries.slice(0, 8))

func create_bracket(stage: Stage, countries: Array[String]) -> void:
	matches[stage] = []

	if countries.size() == 2:
		matches[stage].append(Match.new(countries[0], countries[1]))
		return

	if stage == Stage.QUARTER_FINALS:
		# Relleno de seguridad
		var raw_pool := DataLoader.get_countries()
		var safe_pool: Array[String] = []
		for c in raw_pool:
			if c != "DEFAULT" and c != "":
				safe_pool.append(c)
		while countries.size() < 8:
			countries.append(safe_pool[randi() % safe_pool.size()])

		# 🔥 LÓGICA DE ENFRENTAMIENTO DIRECTO (P1 vs P2) 🔥
		# Si hay 2 jugadores, los forzamos a las posiciones 0 y 1
		# para que se enfrenten en el primer Match.
		if GameManager.player_setup.size() >= 2:
			var p1 = GameManager.player_setup[0]
			var p2 = GameManager.player_setup[1]
			
			if not p2.is_empty(): # Solo si P2 existe
				# Quitamos a P1 y P2 de donde estén en la lista aleatoria
				if countries.has(p1): countries.erase(p1)
				if countries.has(p2): countries.erase(p2)
				
				# Los insertamos al principio juntos
				countries.insert(0, p1)
				countries.insert(1, p2)
				print("⚔️ MODIFICACIÓN: P1 vs P2 forzados en Cuartos de Final.")

	# Emparejar
	for i in range(0, countries.size(), 2):
		var h = countries[i]
		var a = countries[i+1] if i+1 < countries.size() else h
		matches[stage].append(Match.new(h, a))

func advance() -> void:
	if current_stage == Stage.COMPLETE: return

	var stage_matches = matches.get(current_stage, [])
	var winners: Array[String] = []

	for m: Match in stage_matches:
		m.resolve()
		winners.append(m.winner)

	current_stage += 1

	if current_stage == Stage.COMPLETE:
		winner = winners[0]
	elif not is_custom:
		create_bracket(current_stage, winners)
