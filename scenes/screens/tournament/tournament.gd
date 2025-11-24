class_name Tournament
extends Node

enum Stage { QUARTER_FINALS, SEMI_FINALS, FINALS, COMPLETE }

var current_stage: Stage = Stage.QUARTER_FINALS
var matches := {} # Diccionario Stage -> Array[Match]
var winner: String = ""
var is_custom: bool = false

func _init(custom_mode: bool = false) -> void:
	is_custom = custom_mode
	if is_custom:
		matches = { Stage.FINALS: [] }
		current_stage = Stage.FINALS
		print("🏁 Torneo custom inicializado (solo final).")
		return

	var countries := DataLoader.get_countries().slice(1, 9)
	countries.shuffle()
	create_bracket(Stage.QUARTER_FINALS, countries)

func create_bracket(stage: Stage, countries: Array[String]) -> void:
	matches[stage] = []

	if countries.size() == 2:
		matches[stage].append(Match.new(countries[0], countries[1]))
		print("🏁 Bracket directo con 2 países:", countries)
		return

	if stage == Stage.QUARTER_FINALS:
		var all_countries := DataLoader.get_countries().slice(1)
		var used := countries.duplicate()
		for c in all_countries:
			if c not in used:
				used.append(c)
			if used.size() >= 8:
				break
		countries = used

	if countries.size() >= 8 and GameManager.player_setup.size() >= 2:
		var p1 = GameManager.player_setup[0]
		var p2 = GameManager.player_setup[1]
		if countries.has(p1) and countries.has(p2):
			countries.erase(p1)
			countries.erase(p2)
			countries.insert(0, p1)
			countries.insert(1, p2)
			print("🎯 Emparejamiento forzado: P1 vs P2 en el primer match de cuartos.")

	if countries.size() % 2 != 0:
		countries.append(countries[-1])

	while countries.size() < 8:
		countries.append(countries[randi() % countries.size()])

	for i in range(0, countries.size(), 2):
		var home := countries[i]
		var away := countries[i + 1] if i + 1 < countries.size() else countries[i]
		matches[stage].append(Match.new(home, away))

	print("✅ Bracket creado en stage", stage, "con", matches[stage].size(), "matches y", countries.size(), "países.")

func advance() -> void:
	if current_stage < Stage.COMPLETE:
		var stage_matches: Array = matches.get(current_stage, [])
		var stage_winners: Array[String] = []

		for current_match: Match in stage_matches:
			current_match.resolve()
			stage_winners.append(current_match.winner)

		current_stage = current_stage + 1 as Stage

		if current_stage == Stage.COMPLETE:
			winner = stage_winners[0]
		elif not is_custom:
			create_bracket(current_stage, stage_winners)
