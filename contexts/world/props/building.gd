## PREDIO: uma caixa solida. Muda o tamanho e a cor no Inspector de cada instancia.
## A origem fica no CHAO, no centro do predio.
extends StaticBody3D

@export var size := Vector3(20, 15, 20)
@export var color := Color(0.6, 0.6, 0.65)

@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision: CollisionShape3D = $Collision

func _ready() -> void:
	# os resources sao "local to scene": cada predio tem a sua propria caixa e cor
	(_mesh.mesh as BoxMesh).size = size
	(_collision.shape as BoxShape3D).size = size
	(_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color = color
	_mesh.position.y = size.y / 2.0
	_collision.position.y = size.y / 2.0
