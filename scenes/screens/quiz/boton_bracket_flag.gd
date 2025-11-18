class_name BotonBracketFlag
extends TextureRect

@onready var button_label : Label = %BotonLabel

# Cambia el texto del label
func set_text(new_text: String) -> void:
	button_label.text = new_text

# Cambia el color del texto (opcional)
func set_highlighted(is_selected: bool) -> void:
	if is_selected:
		button_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		button_label.add_theme_color_override("font_color", Color.WHITE)
