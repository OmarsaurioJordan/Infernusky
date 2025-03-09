extends Node2D

const saltoSpeed: float = 800.0
const impulsoSpeed: float = 500.0

const acelCorrer: float = 60.0
const velociCorrer: float = 600.0

var velocity: Vector2 = Vector2(0, 0)
var limitSuelo: float
var limitLados: Vector2

const tiempoPata: float = 0.333
var relojHit: float = -1.0

@export var mando = "1"

func _ready() -> void:
	cambioEstado("ImgIdle")
	if mando != "1":
		$Estados.scale.x = -1
	limitSuelo = get_parent().get_node("Suelo").position.y
	limitLados = Vector2(
		get_parent().get_node("LimitLeft").position.x,
		get_parent().get_node("LimitRight").position.x
	)

func _process(delta: float) -> void:
	fisicas(delta)
	limites()
	stateMachine(getEstado())
	comandos()

func getEstado() -> String:
	for img in $Estados.get_children():
		if img.visible:
			return img.name
	return "ImgIdle"

func getSpriteEst() -> Sprite2D:
	for img in $Estados.get_children():
		if img.visible:
			return img
	return null

func fisicas(delta: float) -> void:
	velocity.y += 9.8
	position += velocity * delta
	if isSuelo():
		velocity.x *= 0.9
	else:
		velocity.x *= 0.99
	if relojHit != -1:
		var antReloj = relojHit
		relojHit -= delta
		if relojHit <= 0:
			relojHit = -1
			cambioEstado("ImgIdle")
		var msk = getHitMsk()
		if msk != null:
			if antReloj > tiempoPata / 2 and relojHit <= tiempoPata / 2:
				if isColliHit(msk):
					print("golpeado")

func isColliHit(msk: Area2D) -> bool:
	var r1 = msk.get_node("Coli1").shape.radius
	var pp = msk.get_node("Coli1").global_position
	var r2: float
	var ppp: Vector2
	for bdy in get_tree().get_nodes_in_group("body"):
		# for con colis de msk, hallar r2, ppp para comparar y queda menor dist interna
		pass
	return false

func getHitMsk() -> Area2D:
	return getSpriteEst().get_node("Hit")

func limites() -> void:
	position.y = min(position.y, limitSuelo)
	position.x = clamp(position.x, limitLados.x, limitLados.y)
	if velocity.x > 10:
		$Estados.scale.x = 1
	elif velocity.x < -10:
		$Estados.scale.x = -1

func isSuelo() -> bool:
	return position.y == limitSuelo

func stateMachine(estado: String) -> void:
	match estado:
		"ImgIdle":
			if not isSuelo():
				cambioEstado("ImgCae")
		"ImgDown":
			pass
		"ImgHit":
			pass
		"ImgCae":
			if isSuelo():
				cambioEstado("ImgIdle")
			elif abs(velocity.x) > 30:
				cambioEstado("ImgLadocae")
		"ImgJump":
			if velocity.y >= 0:
				cambioEstado("ImgCae")
			elif abs(velocity.x) > 30:
				cambioEstado("ImgLadojump")
		"ImgLadocae":
			if isSuelo():
				cambioEstado("ImgIdle")
			elif abs(velocity.x) < 30:
				cambioEstado("ImgCae")
		"ImgLadojump":
			if velocity.y >= 0:
				cambioEstado("ImgLadocae")
			elif abs(velocity.x) < 30:
				cambioEstado("ImgJump")
		"ImgRun":
			velocity.x *= 0.75
			if not isSuelo():
				cambioEstado("ImgJump")
			elif abs(velocity.x) < 10:
				cambioEstado("ImgIdle")
		"ImgSuelo":
			pass
		"ImgUp":
			pass

func comandos() -> void:
	if Input.is_action_pressed("key_jump" + mando):
		if getEstado() in ["ImgIdle", "ImgRun", "ImgUp"]:
			saltar()
	if Input.is_action_pressed("key_right" + mando):
		if getEstado() in ["ImgIdle", "ImgRun"]:
			correr(true)
		elif getEstado() in ["ImgDown", "ImgUp"]:
			$Estados.scale.x = 1
	if Input.is_action_pressed("key_left" + mando):
		if getEstado() in ["ImgIdle", "ImgRun"]:
			correr(false)
		elif getEstado() in ["ImgDown", "ImgUp"]:
			$Estados.scale.x = -1
	if Input.is_action_pressed("key_down" + mando):
		if getEstado() in ["ImgIdle", "ImgRun"]:
			cambioEstado("ImgDown")
			velocity.x = 0
	else:
		if getEstado() == "ImgDown":
			cambioEstado("ImgIdle")
	if Input.is_action_pressed("key_up" + mando):
		if getEstado() in ["ImgIdle"]:
			cambioEstado("ImgUp")
			velocity.x = 0
	else:
		if getEstado() == "ImgUp":
			cambioEstado("ImgIdle")
	if Input.is_action_pressed("key_hit" + mando):
		match getEstado():
			"ImgIdle":
				setHit("ImgHit")

func setHit(nameHit: String) -> void:
	relojHit = tiempoPata
	cambioEstado(nameHit)

func correr(isRigth: bool) -> void:
	cambioEstado("ImgRun")
	var giro = -1
	if isRigth:
		giro = 1
	velocity.x = clamp(velocity.x + acelCorrer * giro,
		-velociCorrer, velociCorrer)

func saltar() -> void:
	if Input.is_action_pressed("key_left" + mando):
		cambioEstado("ImgLadojump")
		velocity.x = -impulsoSpeed
	elif Input.is_action_pressed("key_right" + mando):
		cambioEstado("ImgLadojump")
		velocity.x = impulsoSpeed
	else:
		cambioEstado("ImgJump")
	velocity.y = -saltoSpeed

func cambioEstado(nameEstado: String) -> void:
	for img in $Estados.get_children():
		img.visible = img.name == nameEstado

"""
- falta ImgSuelo cuando cae al piso
"""
