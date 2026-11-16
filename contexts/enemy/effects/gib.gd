## PEDACINHO de carne (da cabeca explodindo). Corpo fisico pequeno que some depois de um tempo.
## Fica na layer 4: colide so com o cenario. Tiros e o jogador passam por ele,
## entao nao atrapalha andar por cima.
extends RigidBody3D

@export var lifetime := 8.0

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()
