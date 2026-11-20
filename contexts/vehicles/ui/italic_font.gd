class_name ItalicFont
extends RefCounted

const SLANT := 0.22


static func create(embolden: float) -> FontVariation:
	var variation := FontVariation.new()
	variation.base_font = ThemeDB.fallback_font
	variation.variation_embolden = embolden
	var slant_axis := Vector2(SLANT, 1.0)
	variation.variation_transform = Transform2D(Vector2(1.0, 0.0), slant_axis, Vector2.ZERO)
	return variation
