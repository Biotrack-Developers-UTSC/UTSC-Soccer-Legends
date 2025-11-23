class_name ScreenData

var tournament: Tournament = null
var mode: String = ""  # <-- nuevo campo

static func build() -> ScreenData:
	return ScreenData.new()

func set_tournament(context_tournament: Tournament) -> ScreenData:
	tournament = context_tournament
	return self

func set_mode(game_mode: String) -> ScreenData:  # <-- nuevo método
	mode = game_mode
	return self
