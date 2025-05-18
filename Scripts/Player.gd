extends CharacterBody2D

const SALTO: float = 600.0
const CORRER: float = 400.0
const FRICCION: float = 0.9

var vida: int = 10
var miColor: Color = Color(1, 0.75, 0.08) # rojo

const TIEMPO_HIT: float = 0.333
var relojHitMax: float = 0.0
var relojHit: float = -1.0
var impactado = []

@export var mando = "1"

func _ready() -> void:
	cambioEstado("ImgIdle")
	if mando != "1":
		$Estados.scale.x = -1
		miColor = Color(0.6, 0.75, 0.9) # azul
	$Estados.modulate = miColor

func _physics_process(delta: float) -> void:
	fisicas(delta)

func _process(delta: float) -> void:
	atacar(delta)
	manager()

func fisicas(delta: float) -> void:
	# caer y saltar
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_pressed("key_jump" + mando):
		if isEstado(["ImgIdle", "ImgRun", "ImgUp"]):
			cambioEstado("ImgJump")
			velocity.y = -SALTO
	# agacharse y volver a subir
	if Input.is_action_pressed("key_down" + mando):
		if isEstado(["ImgIdle", "ImgRun"]):
			cambioEstado("ImgDown")
			velocity.x = 0
	elif isEstado(["ImgDown"]):
		cambioEstado("ImgIdle")
	# mirar arriba y volver a bajar
	if Input.is_action_pressed("key_up" + mando):
		if isEstado(["ImgIdle"]):
			cambioEstado("ImgUp")
	elif isEstado(["ImgUp"]):
		cambioEstado("ImgIdle")
	# moverse en horizontal, sea en suelo o aire
	var direction = Input.get_axis("key_left" + mando, "key_right" + mando)
	if direction != 0:
		if isEstado(["ImgIdle", "ImgRun", "ImgJump", "ImgLadojump",
				"ImgLadocae", "ImgCae"]):
			velocity.x = direction * CORRER
		else:
			if isEstado(["ImgDown", "ImgUp"]):
				$Estados.scale.x = direction
			direction = 0
	# frenar el movimiento horizontal
	if direction != 0:
		if is_on_floor():
			velocity.x *= FRICCION
		else:
			velocity.x *= (FRICCION + 2) / 3
	# ajustar hacia que lado mira el personaje
	if velocity.x > 10:
		$Estados.scale.x = 1
	elif velocity.x < -10:
		$Estados.scale.x = -1
	# ejecutar los movimientos, colision automatica
	move_and_slide()

func atacar(delta: float) -> void:
	if Input.is_action_pressed("key_hit" + mando):
		match getEstado():
			"ImgIdle":
				relojHitMax = TIEMPO_HIT
				relojHit = relojHitMax
				cambioEstado("ImgHit")
	# ejecutar el ataque
	if relojHit != -1:
		var antHit = relojHit
		relojHit -= delta
		if antHit > relojHitMax * 0.666 and relojHit <= relojHitMax * 0.666:
			getSprite().get_node("Hit/Coli1").disabled = false
		if antHit > relojHitMax * 0.333 and relojHit <= relojHitMax * 0.333:
			getSprite().get_node("Hit/Coli1").disabled = true
			# calcular damages
			var yaImpactado = []
			for imp in impactado:
				if not imp in yaImpactado:
					yaImpactado.append(imp)
					imp.damage()
		if relojHit <= 0:
			relojHit = -1
			cambioEstado("ImgIdle")

func manager() -> void:
	match getEstado():
		"ImgIdle":
			pass

func damage() -> void:
	vida -= 1
	$Estados.modulate = Color("red")
	$RelojDamage.start()
	get_parent().get_node("Control/Vida" + mando).value = vida
	if vida <= 0:
		queue_free()

func isEstado(estados=[]) -> bool:
	return getEstado() in estados

func getEstado() -> String:
	for img in $Estados.get_children():
		if img.visible:
			return img.name
	return "ImgIdle"

func getSprite() -> Sprite2D:
	for img in $Estados.get_children():
		if img.visible:
			return img
	return null

func cambioEstado(nameEstado: String) -> void:
	for img in $Estados.get_children():
		img.visible = img.name == nameEstado

func _on_reloj_damage_timeout() -> void:
	$Estados.modulate = miColor

func _on_hit_area_entered(area: Area2D) -> void:
	var quien = area.get_parent().get_parent().get_parent()
	if quien != self:
		impactado.append(quien)

func _on_hit_area_exited(area: Area2D) -> void:
	var quien = area.get_parent().get_parent().get_parent()
	impactado.erase(quien)
