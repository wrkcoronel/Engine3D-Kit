## PAREDE: quando a camera chega perto de uma parede, a arma recua e levanta
## (estilo R6/Bodycam). So calcula o quanto (amount, 0 a 1) e a pose; quem aplica e o gun.gd.
class_name GunWallAvoid
extends Node

## Distancia da camera em que a arma comeca a recuar.
@export var check_distance := 1.1
## Distancia da camera em que a arma ja esta totalmente levantada.
@export var min_distance := 0.45
## Deslocamento da arma quando totalmente encostada (x direita, y cima, z tras).
@export var offset := Vector3(0.0, -0.1, 0.35)
## Rotacao da arma encostada, em graus (x = aponta pra cima).
@export var rotation_deg := Vector3(65.0, -15.0, 0.0)
@export var smooth := 12.0

## 0 = longe da parede, 1 = colado.
var amount := 0.0

func update(delta: float, cam: Camera3D) -> void:
	amount = lerpf(amount, _closeness(cam), 1.0 - exp(-smooth * delta))

## Pose da arma para uma intensidade k (0 a 1).
func pos(k: float) -> Vector3:
	return offset * k

func rot(k: float) -> Vector3:
	return Vector3(deg_to_rad(rotation_deg.x), deg_to_rad(rotation_deg.y), deg_to_rad(rotation_deg.z)) * k

func _closeness(cam: Camera3D) -> float:
	var d := RayUtil.dist(cam.get_world_3d(), cam.global_position, -cam.global_basis.z, check_distance)
	if d < 0.0:
		return 0.0
	return clampf(inverse_lerp(check_distance, min_distance, d), 0.0, 1.0)
