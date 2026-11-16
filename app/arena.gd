## ARENA de teste de tiro: piso, muro e um inimigo parado. R recarrega a cena (inimigo inteiro de novo).
extends Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()
