extends Node2D

const saltoSpeed: float = 600.0
const impulsoSpeed: float = 400.0

const acelCorrer: float = 6000.0
const velociCorrer: float = 600.0

var miColi: Area2D
var enColi: Area2D = null
const velociColision: float = 500.0

var vida: int = 10
var miColor: Color = Color(1, 0.75, 0.08)

var velocity: Vector2 = Vector2(0, 0)
var limitSuelo: float
var limitLados: Vector2

const tiempoPata: float = 0.333
var relojHit: float = -1.0

@export var mando = "1"

func _ready() -> void:
	miColi = $Solidisimo
	cambioEstado("ImgIdle")
	if mando != "1":
		$Estados.scale.x = -1
		miColor = Color(0.6, 0.75, 0.9)
	$Estados.modulate = miColor
	limitSuelo = get_parent().get_node("Suelo").position.y
	limitLados = Vector2(
		get_parent().get_node("LimitLeft").position.x,
		get_parent().get_node("LimitRight").position.x
	)

func _process(delta: float) -> void:
	fisicas(delta)
	limites()
	stateMachine(getEstado())
	comandos(delta)

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
	if enColi != null:
		var pp = miColi.get_node("Coli1").global_position
		var repulsion = enColi.get_node("Coli1").global_position.direction_to(pp)
		position += repulsion * velociColision * delta
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
				isColliHit(msk)

func isColliHit(msk: Area2D) -> bool:
	var r1 = $Estados/ImgHit/Hit/Coli1.global_position.distance_to(
		$Estados/ImgHit/Hit/Coli1/Radio.global_position)
	var r2 = $Estados/ImgIdle/Msk/Coli1.global_position.distance_to(
		$Estados/ImgIdle/Msk/Coli1/Radio.global_position)
	var pp = msk.get_node("Coli1").global_position
	var ppp: Vector2
	for bdy in get_tree().get_nodes_in_group("body"):
		if not bdy.get_parent().visible:
			continue
		if bdy.get_parent().get_parent().get_parent() == self:
			continue
		for c in bdy.get_children():
			ppp = c.global_position
			if ppp.distance_to(pp) < r1 + r2:
				bdy.get_parent().get_parent().get_parent().damage()
				return true
	return false

func damage():
	vida -= 1
	$Estados.modulate = Color("red")
	$RelojDamage.start()
	get_parent().get_node("Control/Vida" + mando).value = vida
	if vida <= 0:
		queue_free()

func getHitMsk() -> Area2D:
	for hit in get_tree().get_nodes_in_group("hit"):
		if hit.get_parent().visible:
			if hit.get_parent().get_parent().get_parent() == self:
				return hit
	return null

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
		"ImgDown":
			pass
		"ImgHit":
			pass

func comandos(delta: float) -> void:
	if Input.is_action_pressed("key_jump" + mando):
		if getEstado() in ["ImgIdle", "ImgRun", "ImgUp"]:
			saltar()
	if Input.is_action_pressed("key_right" + mando):
		if getEstado() in ["ImgIdle", "ImgRun"]:
			correr(true, delta)
		elif getEstado() in ["ImgJump", "ImgLadojump"]:
			velocity.x = clamp(velocity.x + acelCorrer * 0.2 * delta,
				-impulsoSpeed, impulsoSpeed)
		elif getEstado() in ["ImgDown", "ImgUp"]:
			$Estados.scale.x = 1
	if Input.is_action_pressed("key_left" + mando):
		if getEstado() in ["ImgIdle", "ImgRun"]:
			correr(false, delta)
		elif getEstado() in ["ImgJump", "ImgLadojump"]:
			velocity.x = clamp(velocity.x - acelCorrer * 0.2 * delta,
				-impulsoSpeed, impulsoSpeed)
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

func correr(isRigth: bool, delta: float) -> void:
	cambioEstado("ImgRun")
	var giro = -1
	if isRigth:
		giro = 1
	velocity.x = clamp(velocity.x + acelCorrer * giro * delta,
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
		if img.visible:
			var coli = img.get_node("Solid/Coli1")
			miColi.reparent(img.get_node("Solid"))
			miColi.get_node("Coli1")
			miColi.get_node("Coli1").global_transform  = coli.global_transform
			miColi.get_node("Coli1").shape.radius = coli.shape.radius
			miColi.get_node("Coli1").shape.height = coli.shape.height

func _on_reloj_damage_timeout() -> void:
	$Estados.modulate = miColor

func _on_solid_area_entered(area: Area2D) -> void:
	enColi = area

func _on_solid_area_exited(_area: Area2D) -> void:
	enColi = null

"""
- falta ImgSuelo cuando cae al piso
"""
