extends RefCounted

const Creek = preload("res://cauce.gd")
const Museum = preload("res://museo.gd")
const Trail = preload("res://travesia.gd")
const Departure = preload("res://salida.gd")

const VISIT_PERCENT := 60

const HERNAN_STARTS := ["piedras", "vaguada", "sueno", "cable", "regreso"]
const RESERVED_ANSWERS := ["cielo", "pircas"]

# Respuesta de cercanía, apertura, respuestas de Hernán y réplicas de Mara.
const TOPICS = {
	"cauce": [
		1, "La semana pasada te largué con dos encargos encima. Hoy vamos con más tiempo. ¿Cómo te está tratando el camino?",
		["Por ahora me viene bien el silencio. Te aviso cuando llegue.", "Me vendría bien que me acompañes hasta el cruce."],
		[
			["Dale. Dejo el equipo en el canal. Cuando llegues dejame un clic, así sé que estás del otro lado."],
			["Dale. Contame si ya pasaste las lajas.", "Si tardás en volver a llamar, me quedo en el canal un rato."]
		]
	],
	"piedras": [
		0, "Che, ¿por acá se encuentran fósiles? Estuve mirando las piedras del cauce.",
		["¿Me la mostrás algún día?", "Voy a mirar mejor las capas cuando vuelva al cauce."],
		[
			["Te la mando con las pilas. Mirala de costado. Se le ven hasta las nervaduras."],
			["Fijate en la piedra que se abre en láminas. Ahí a veces queda una impresión que parece hecha a lápiz."]
		]
	],
	"museo": [
		0, "¿Ya estás cerca del museo? Hay una sala sobre los comechingones. Si tenés tiempo, entrá antes de seguir.",
		["No sé nada de los comechingones. ¿Qué hay adentro?", "¿Son los que, según dicen, tuvieron contacto con extraterrestres?"],
		[
			["Vasijas, piedras de moler y un dibujo de cómo eran las casas. Acá vivían mucho antes de que llegaran los españoles."],
			["Los que dicen eso venden excursiones. Entrá y fijate en las cosas que dejaron. Hay bastante para mirar sin ponerles un OVNI arriba."]
		]
	],
	"antena": [
		1, "Antes de que bajes de la antena, ¿hacemos una prueba? Quiero saber en qué parte de la vuelta se pierde tu voz.",
		["Te aviso si vuelve a cortarse.", "Dejá el volumen como está. Te voy diciendo desde dónde te hablo."],
		[
			["Dale. Si te falla una vez, esperá unos segundos antes de repetir."],
			["Eso me sirve. Cuando cambiaron el mástil, me tocó hacer esa caminata sola. Es raro hablarle al aparato cuando del otro lado nadie puede decirte si te oye."]
		]
	],
	"vaguada": [
		0, "Llegué al cartel de la laja. Las dos huellas suben. ¿Cuál tengo que mirar?",
		["Voy por el rodeo. ¿Dónde se vuelven a juntar?", "Voy a probar la cuerda. Desde acá parece firme."],
		[
			["Seguí el desvío de la derecha. Rodea el resalte y vuelve a la huella principal más arriba. Fijate si se puede hacer con las manos ocupadas."],
			["Probala sin apuro. Si para subir necesitás las dos manos, eso ya nos dice algo sobre llevar herramientas."]
		]
	],
	"sueno": [
		0, "Anoche soñé que estaba en otro planeta. Saltaba y tardaba una eternidad en volver al suelo.",
		["Te vas a reír, pero traté de dibujarlo antes de que se me borrara.", "Entonces cobrame la excursión cuando baje."],
		[
			["Algún día me gustaría ver esos dibujos. A ver si en tu planeta también había que caminar tanto."],
			["Si volvés con un dibujo, te hago precio. En serio, algún día me gustaría verlo."]
		]
	],
	"cielo": [
		0, "Decime una cosa. ¿Cómo fue que terminaste acá arriba? ¿Perdiste una apuesta?",
		["Mi viejo murió en julio. Me ofrecieron el puesto un tiempo después. Me hizo bien tener algo que hacer.", "Fue una buena excusa para salir de casa. Por ahora prefiero contarte hasta ahí."],
		[
			["Ah. No sabía. Gracias por decírmelo.", "¿Me avisás cuando llegues al hito? Yo sigo acá."],
			["Está bien. Nos queda bastante cerro para hablar de otra cosa."]
		]
	],
	"duelo": [
		0, "Me quedó dando vueltas una cosa que te pregunté el otro día.",
		["Está bien, Mara. Podés preguntar.", "Prefiero que quede ahí. Te agradezco que me lo digas."],
		[
			["Gracias. A mí a veces me cuesta saber cuándo seguir y cuándo dejar un silencio."],
			["Dale. Avisame cuando llegues al malacate."]
		]
	],
	"cable": [
		1, "Mirá hacia el sur si podés. Ya se ve la Cruz del Sur sobre la ladera.",
		["Dejé la investigación. Pasaron cosas en casa y al final fui dando clases.", "Me gustaría volver a la investigación. En casa se complicaron las cosas y lo fui dejando."],
		[
			["Mirá vos. Yo con suerte me acuerdo de cuál es la del medio del cinturón.", "Si te vuelvo a preguntar cuál es la Cruz del Sur, hacé de cuenta que soy alumna nueva."],
			["Bueno, ahora ya sé a quién llamar cuando quiera entender lo que estoy mirando.", "Y me vas a tener que mostrar cuál de las cuatro buscás primero."]
		]
	],
	"pircas": [
		0, "Me quedé pensando en lo que hablamos el otro día. ¿Nunca pensaste en formar una familia?",
		["Se llama Paula. Estudiábamos juntos y se fue a Alemania. Hace tiempo que no hablamos.", "Prefiero dejarlo ahí por ahora. Hubo alguien, sí."],
		[
			["Tenías ganas de hablarle, por cómo lo decís.", "Bueno. Si un día te salen las palabras, mandale aunque sea una línea."],
			["Entiendo. Perdón si te agarré de sorpresa. Podemos seguir hablando de otra cosa."]
		]
	],
	"bajada": [
		1, "Cuando veas el banco ya estás fuera de la parte fea de la bajada. Si querés, me quedo un rato.",
		["Ya veo por dónde sigo. Acá abajo aflojó un poco el viento.", "Quedate un rato. Cada vez que suelto el botón vuelve a oírse el viento."],
		[
			["Acá también paró. Si te agarra otra ráfaga, esperá al reparo de las piedras. Avisame cuando veas el puesto."],
			["Dale. Yo sigo lavando unos platos. Cuando llegues me avisás.", "En el próximo cajón te mando un tinto que tenía guardado. Abrilo cuando entregues la llave."]
		]
	],
	"lluvia": [
		0, "Si te llega a tapar la lluvia, frená donde puedas apoyar bien los dos pies. La última vez perdí un guante por apurarme en esa bajada.",
		["Puedo esperar acá. ¿Me avisás si escuchás algo de la pasarela?", "Veo bien las pircas. Te llamo desde la orilla."],
		[
			["Sí. Desde acá oigo el agua en el techo nada más. Si cambia algo, te doy dos llamados cortos."],
			["Dale. Probá la radio antes de asomarte al agua. Si se corta, volvé por donde viniste."]
		]
	],
	"ventana": [
		0, "Probé el equipo de repuesto. En ese tramo se pisan dos frecuencias. Sigo sin ubicar la voz de la advertencia. ¿Ya ves la tranquera?",
		["¿Te quedás conmigo hasta que entre al patio?", "Veo la tranquera. Si vuelve a entrar la voz, te anoto la hora."],
		[
			["Sí. Yo me quedo acá. Avisame cuando estés del otro lado de la verja."],
			["Dale. Yo voy a dejar anotada la hora que escuché el primer golpe."]
		]
	],
	"regreso": [
		1, "Ya salí. Me cuesta creer que sea la última vez que vengo por esta huella.",
		["Cuando llegue a casa voy a abrir la ventana y dejar todo en el bolso.", "Creo que voy a salir a mirar el cielo desde la vereda. Hace mucho que no lo hago."],
		[
			["Si te olvidaste de algo, yo subo al puesto después."],
			["Ojalá esté despejado. Si llegás a ver la cruz, pensá que desde acá va a estar para el mismo lado."]
		]
	],
	"ultima_curva": [
		1, "Si te das vuelta en la bajada, vas a ver el techo del puesto entre los árboles. Yo siempre lo busco desde ahí.",
		["Voy a sentarme del lado de la sierra.", "Voy a extrañar más que la vista. Vos también me vas a hacer falta."],
		[
			["Sentate adelante si hay lugar. De atrás a veces sólo se ve el polvo."],
			["A mí también me va a faltar oírte llegar. Hoy dejé la radio prendida un rato antes de que salieras."]
		]
	]
}

static func opening(topic: String, answered: Dictionary, abra_told: bool, paula_told: bool) -> String:
	match topic:
		"antena":
			if abra_told: return "Dejé la luz y la voz en renglones separados, como me las contaste. Quedate un segundo en la antena. ¿Probamos hasta dónde llega el canal?"
		"duelo":
			if not answered.has("cielo"): return "Estos días me di cuenta de que nunca te pregunté si te está haciendo bien el puesto."
		"pircas":
			if not answered.has("cielo") and not answered.has("duelo"):
				return "Ya falta poco para que bajes. Siempre te pregunto del trabajo. ¿Nunca pensaste en formar una familia?"
		"regreso":
			if paula_told: return "Salí con ganas de escribirle a Paula. Pero eso puede esperar. Ahora me cuesta creer que sea la última vez que vengo por esta huella."
	return TOPICS[topic][1]

static func farewell_memory(answered: Dictionary) -> String:
	if answered.get("cielo", -1) == 0:
		return "Desde que me contaste lo de tu viejo, alguna noche dejé el equipo al lado de la ventana. Por si salías a mirar y te daban ganas de llamar."
	if answered.get("ventana", -1) == 0:
		return "El día de la crecida no apagué el equipo hasta que llegaste a la tranquera. Lo habría dejado prendido toda la noche."
	if answered.get("sueno", -1) == 0:
		return "Llevate el cuaderno en el bolso de mano. Si te acordás de esas estrellas otra vez, así lo tenés cerca."
	if answered.get("cauce", -1) == 1:
		return "Me acuerdo de cuando me pediste que te acompañara hasta el cruce. A mí también me vino bien oír a alguien del otro lado."
	if answered.get("museo", -1) == 0:
		return "Si volvés al museo, fijate en las fichas de las casas. Me acordé de lo que hablamos por radio."
	return ""

static func available(stage: int, position: Vector3, bedtime: bool, sighting: bool, answered: Dictionary) -> String:
	var topic := ""
	match stage:
		5:
			if near(position, Creek.trail_point(0.53), 18.0): topic = "piedras"
		7:
			if on_ridge(position, 142.0, 33.0):
				topic = "cauce"
			elif on_ridge(position, Museum.DISTANCE, 33.0):
				topic = "museo"
			elif sighting and bedtime and on_ridge(position, 389.0, 27.0):
				topic = "antena"
		8:
			if on_ridge(position, 164.0, 49.0): topic = "vaguada"
			elif on_ridge(position, 342.0, 52.0): topic = "cielo"
		9:
			if bedtime and on_ridge(position, 596.0, 91.0): topic = "sueno"
		10:
			if near(position, Trail.quarry_point(Trail.WEST_JOIN), 56.0): topic = "duelo"
		12:
			if near(position, Trail.quarry_point(0.72), 45.0): topic = "cable"
		15:
			if near(position, Trail.summit_point(0.82), 52.0): topic = "pircas"
			elif near(position, Trail.ascent_point(0.53), 73.0): topic = "bajada"
		16:
			if near(position, Creek.crossing_point(0.42), 24.0): topic = "lluvia"
		18:
			if near(position, Vector3(1.0, 0.0, -10.0), 25.0): topic = "ventana"
		19:
			if near(position, Vector3(21.0, 0.0, -3.0), 13.0):
				topic = "regreso"
			elif near(position, Departure.RADIO_STOP, 13.0):
				topic = "ultima_curva"
	return topic if not answered.has(topic) else ""

static func on_ridge(position: Vector3, distance: float, radius: float) -> bool:
	return near(position, Vector3(Trail.trail(distance), 0.0, Trail.ORIGIN_Z - distance), radius)

static func distance_between_calls(day: int) -> float:
	match day:
		2: return 12.0
		41: return 15.0
		_: return 26.0

static func seconds_between_calls(day: int) -> float:
	return 8.0 if day in [2, 41] else 16.0

static func near(position: Vector3, center: Vector3, radius: float) -> bool:
	return Vector2(position.x - center.x, position.z - center.z).length_squared() < radius * radius

static func closeness(answered: Dictionary) -> int:
	var connected := 0
	for topic in TOPICS:
		var answer: int = answered.get(topic, -1)
		if answer == TOPICS[topic][0] or (answer == 1 and topic in RESERVED_ANSWERS):
			connected += 1
	return connected

static func can_visit(answered: Dictionary) -> bool:
	return closeness(answered) * 100 >= TOPICS.size() * VISIT_PERCENT

static func saved_replies(state: Dictionary) -> Dictionary:
	var replies: Dictionary = state.get("trail_replies", {}).duplicate()
	replies.erase("alero")
	replies.erase("primera_noche")
	var legacy := {7: "museo", 27: "cielo", 32: "bajada"}
	for day in legacy:
		if replies.has(day):
			replies[legacy[day]] = replies[day]
			replies.erase(day)
	if state.get("trail_check_in", false):
		replies["cauce"] = int(state.get("asked_mara_to_stay", false))
	return replies
