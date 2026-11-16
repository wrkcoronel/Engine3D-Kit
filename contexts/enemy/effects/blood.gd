## SANGUE: respingo de particulas vermelhas. Quem cria e o enemy.gd.
##   spurt_time = 0: um estouro so (tiro acertando);
##   spurt_time > 0: fica jorrando por esse tempo, em segundos (pedaco arrancado).
## Se apaga sozinho quando as particulas acabam.
class_name Blood
extends CPUParticles3D

var spurt_time := 0.0

func _ready() -> void:
	if spurt_time <= 0.0:
		finished.connect(queue_free)
		emitting = true
		return
	one_shot = false
	explosiveness = 0.0
	emitting = true
	await get_tree().create_timer(spurt_time).timeout
	emitting = false
	await get_tree().create_timer(lifetime).timeout # deixa as ultimas gotas cairem
	queue_free()
