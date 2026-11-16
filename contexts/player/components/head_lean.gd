## INCLINACAO DA CABECA: sai pro lado e inclina (peek de cover).
## Fica no no Head. Quem define o lean e o GunCoverPeek da arma.
class_name HeadLean
extends Node3D

## Quanto a cabeca sai pro lado (m) e o quanto inclina (graus).
@export var lean_distance := 0.5
@export var lean_angle_deg := 10.0

## -1 (esquerda) a +1 (direita).
var lean := 0.0
## Posicao da cabeca sem inclinacao.
var rest_position: Vector3

func _ready() -> void:
	rest_position = position

func _process(_delta: float) -> void:
	position.x = rest_position.x + lean * lean_distance
	rotation.z = -lean * deg_to_rad(lean_angle_deg)
