## MIRA (botao direito): leva a arma pro centro da tela e fecha o FOV da camera.
class_name GunAim
extends Node

## Posicao da arma (local da camera) quando mirando. Alinha a mira com o centro da tela.
@export var aim_position := Vector3(0.0, -0.12, -0.45)
@export var fov := 55.0
@export var smooth := 14.0
## O quanto sway/bob/coice diminuem ao mirar (0 a 1).
@export var stability := 0.7

## 0 = na cintura, 1 = mirando.
var amount := 0.0
var _hip_fov := 0.0

func update(delta: float, cam: Camera3D, wants_aim: bool) -> void:
	if _hip_fov == 0.0:
		_hip_fov = cam.fov
	amount = lerpf(amount, 1.0 if wants_aim else 0.0, 1.0 - exp(-smooth * delta))
	cam.fov = lerpf(_hip_fov, fov, amount)

## 1 = solto, menor = mais firme (usado por sway, bob e recoil).
func steady() -> float:
	return 1.0 - stability * amount
