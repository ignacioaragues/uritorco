extends RefCounted

const Creek = preload("res://cauce.gd")
const Museum = preload("res://museo.gd")
const Trail = preload("res://travesia.gd")
const LastNight = preload("res://final_night.gd")

const VISIT_PERCENT := 60

# Respuesta que genera cercanía, pregunta, opciones de Hernán y réplicas de Mara.
const TOPICS = {
	"alero": [
		0, "¿Escuchás un golpecito arriba de la ventana? En ese alero hizo nido un benteveo. Hace años que vuelve al mismo rincón.",
		["«Lo escuché al entrar».", "«Por ahora escucho más la heladera»."],
		[
			["Cuando se levanta viento mueve una chapita. La primera vez salí tres veces a ver quién golpeaba."],
			["Esa sí que no descansa. Si se queda callada de golpe, fijate si todavía hay luz en la cocina."]
		]
	],
	"primera_noche": [
		0, "¿Desde ahí se ve una luz amarilla abajo? Es la de mi cocina. Le dejé la cortina abierta.",
		["«Se agradece ver otra luz».", "«¿Vos también hacés el turno de noche?»"],
		[
			["Yo la dejaba prendida cuando mi vieja volvía tarde. Después se me hizo costumbre."],
			["Hoy ya terminé. Me quedé haciendo pan y perdí la cuenta de cuánto llevaba en el horno."]
		]
	],
	"cauce": [
		1, "¿Cómo te está tratando el camino?",
		["Se agradece el silencio.", "Me vendría bien un poco de charla."],
		[
			["Te entiendo. Hay días que bajo por ahí para escuchar los pasos."],
			["Te acompaño un rato. Desde acá se ve la curva antes del cauce."]
		]
	],
	"piedras": [
		0, "De chica llevaba una piedra de cada caminata. Una vez volví con tantas que tuve que dejar el agua para cerrar la mochila.",
		["«¿Todavía guardás alguna?»", "«Hoy casi me traigo una de acá»."],
		[
			["Una blanca y chata. La uso para que no se me vuele el mantel."],
			["Fijate si te vuelve a llamar la atención mañana. A veces es la luz de ese momento."]
		]
	],
	"museo": [
		0, "Si vas por el museo, probá la puerta. El de la llave se fue al pueblo. Acá decidimos llamarlo horario corrido.",
		["«¿Venías mucho al museo?»", "«Con razón le falta el cartel de horarios»."],
		[
			["Mi vieja me traía cuando llovía. Había un mortero que podías tocar.", "Un día nos dejaron encerradas. Mi vieja siguió leyendo las fichas hasta que volvieron."],
			["Sí, ése me lo llevé yo para que no se lo llevara el viento.", "Ahora está abajo de una pata de mi mesa. Horario corrido, mesa firme."]
		]
	],
	"antena": [
		1, "Mi vieja me enseñó a usar esa antena. La primera vez me hizo llamar desde el cerro para preguntarle qué había de comer.",
		["«¿Y qué había?»", "«¿Te quedaste sin saber qué decir?»"],
		[
			["Sopa. Yo esperaba que me dijera que se escuchaba clarito. Me dijo que no dejara enfriar la sopa."],
			["Le di al botón y me quedé muda. La oí decir «tomate tu tiempo». Eso me dio más vergüenza todavía."]
		]
	],
	"vaguada": [
		0, "Tenés dos huellas ahí. La vuelta por abajo la aprendí tarde. Antes me empecinaba con la laja hasta cuando estaba mojada.",
		["«¿Quién te mostró la otra vuelta?»", "«Mi viejo me decía que mirara dónde pisa el agua»."],
		[
			["Una vecina que subía con una bolsa de pan en cada mano. Yo estaba juntando coraje frente a la cuerda. Me gritó desde arriba."],
			["En eso tenía razón. Cuando vuelve el agua, las huellas que quedan son las que aprendiste a ver."]
		]
	],
	"sueno": [
		0, "Hoy me desperté antes que el despertador. Me quedé escuchando los pájaros y cuando sonó ya no sabía de qué lado venía el ruido.",
		["«Yo soñé con un cielo que no conocía».", "«Todavía me despierto buscando la ventana de casa»."],
		[
			["¿Te acordás de alguna parte? A mí me sirve dibujar una sola cosa, aunque sea una esquina."],
			["Me pasó cuando me mudé acá. Una mañana abrí la cortina y me sorprendió que la sierra siguiera en el mismo lugar."]
		]
	],
	"cielo": [
		0, "Desde acá veo el cable, así que calculo que vas bien. Te iba a preguntar algo. ¿Mirabas el cielo antes de venir acá?",
		["«Lo miraba con mi viejo. Desde que murió me cuesta un poco».", "«Estudié astronomía. Hace rato que miro más papel que cielo»."],
		[
			["Podés contarme de él si te dan ganas. A mí me gustaba escuchar a mi vieja reconocer pájaros.", "Ahora reconozco alguno. A veces me encuentro por decirle cuál es."],
			["Entonces te voy a pedir un favor. Hay una estrella que veo desde la pileta y nunca sé cómo se llama.", "Algún día te la señalo. Por radio terminaría señalándote media sierra."]
		]
	],
	"cable": [
		1, "Cuando el cable se mueve con el viento, desde mi patio parece que alguien hubiera dejado una cuerda de guitarra tirante.",
		["«Desde acá lo escucho distinto».", "«¿Tocás la guitarra?»"],
		[
			["Algún día me gustaría oírlo desde donde estás vos. Siempre me doy vuelta antes de llegar al corte."],
			["Tres acordes. Los aprendí para una canción y, cuando me salió, me dio pena tocar otra."]
		]
	],
	"pircas": [
		0, "En esa subida hay una pirca que armé con mi hermano. De chicos jugábamos a dejar la piedra más chiquita bien arriba.",
		["«¿Siguen subiendo juntos?»", "«Yo le voy a dejar una al lado»."],
		[
			["Ahora vive en el pueblo. Cuando viene a verme, nos quedamos hablando en el patio y se nos hace tarde."],
			["Haceme un favor. Si ves una verde, dejala donde está. Fue la única que encontré de ese color."]
		]
	],
	"bajada": [
		1, "Ya debe darte la sombra. Bajá tranquilo. El primer día que salí de ahí me apuré tanto que llegué con dos piedras adentro de la bota.",
		["«¿Dónde te dejo la llave el último día?»", "«¿Me dejás la radio abierta un rato?»"],
		[
			["En el buzón del puesto. La puerta de madera que te dije, antes de la parada.", "Le iba a poner un timbre. Por ahora tengo dos tornillos y un agujero."],
			["Sí. Estoy lavando los platos. Si escuchás que se cae algo, seguí caminando.", "Vos avisame cuando veas el banco."]
		]
	],
	"lluvia": [
		0, "Cuando llueve así saco las macetas del alero. Siempre me acuerdo de una que mi vieja ponía afuera en la primera lluvia de noviembre.",
		["«¿Qué tenía plantado?»", "«En casa poníamos una olla bajo la gotera»."],
		[
			["Malvones. Dejó uno en una lata de duraznos. Esa lata duró más que todas las macetas buenas."],
			["Acá uso una palangana. Cuando empieza a llenarse cambia el sonido. Así me doy cuenta de que tengo que vaciarla."]
		]
	],
	"ventana": [
		0, "Ya se ve la luz del refugio desde acá. Antes de que entres, ¿querés que te deje el canal abierto?",
		["«Sí. Quedate un rato».", "«Por hoy me alcanza con llegar»."],
		[
			["Bueno. Voy a poner agua. Si escuchás la pava, soy yo."],
			["Dale. Cerrá bien la ventana de la cocina. Con este viento vuelve a abrirse."]
		]
	],
	"regreso": [
		1, "¿Qué es lo primero que vas a hacer cuando llegues a casa?",
		["«Abrir la ventana de mi pieza».", "«Volver a mirar el cielo desde la vereda»."],
		[
			["La primera noche que volví al pueblo dormí con la ventana abierta. Quería ver si de día me acordaba del ruido de los árboles."],
			["Si encontrás las cuatro de la cruz, avisame otro día. Yo voy a mirar desde acá."]
		]
	],
	"ultima_curva": [
		1, "Los días que voy al pueblo me siento del lado de la ventanilla. En la última curva todavía se ve un pedazo de la sierra.",
		["«Voy a buscar ese asiento».", "«No sé si me dan ganas de mirar»."],
		[
			["El vidrio suele estar sucio. Con el puño del buzo alcanza para hacerte un huequito."],
			["Entonces llevá el libro a mano. Si querés, después me contás qué página te tocó en la última curva."]
		]
	]
}

static func available(stage: int, position: Vector3, bedtime: bool, sighting: bool, answered: Dictionary) -> String:
	var topic := ""
	match stage:
		0:
			if bedtime and absf(position.x) < 14.0:
				if position.z > 0.0 and position.z < 5.9: topic = "alero"
				elif position.z >= -14.0 and position.z <= 0.0: topic = "primera_noche"
		4:
			if position.z > 30.0 and Creek.trail_distance(Vector2(position.x, position.z)) < 14.0: topic = "cauce"
		5:
			if bedtime and near(position, Creek.trail_point(0.5), 27.0): topic = "piedras"
		7:
			if near(position, Vector3(Trail.trail(Museum.DISTANCE), 0.0, Trail.ORIGIN_Z - Museum.DISTANCE), 42.0):
				topic = "museo"
			elif sighting and near(position, Vector3(Trail.trail(389), 0.0, Trail.ORIGIN_Z - 389.0), 50.0):
				topic = "antena"
		8:
			if near(position, Vector3(Trail.trail(170), 0.0, Trail.ORIGIN_Z - 170.0), 57.0): topic = "vaguada"
		9:
			if bedtime and near(position, Vector3(Trail.trail(630), 0.0, Trail.ORIGIN_Z - 630.0), 112.0): topic = "sueno"
		10:
			if near(position, Trail.quarry_point(0.44), 86.0): topic = "cielo"
		12:
			if near(position, Trail.quarry_point(0.67), 105.0): topic = "cable"
		13:
			if near(position, Trail.ascent_point(0.24), 115.0): topic = "pircas"
		15:
			if near(position, Trail.ascent_point(0.67), 155.0): topic = "bajada"
		16:
			if near(position, Creek.crossing_point(0.42), 42.0): topic = "lluvia"
		18:
			if near(position, Vector3.ZERO, 36.0): topic = "ventana"
		19:
			if near(position, Vector3.ZERO, 52.0):
				topic = "regreso"
			elif LastNight.near_stop(position) or near(position, Vector3(Trail.trail(Museum.DISTANCE), 0.0, Trail.ORIGIN_Z - Museum.DISTANCE), 65.0):
				topic = "ultima_curva"
	return topic if not answered.has(topic) else ""

static func near(position: Vector3, center: Vector3, radius: float) -> bool:
	return Vector2(position.x - center.x, position.z - center.z).length_squared() < radius * radius

static func can_visit(answered: Dictionary) -> bool:
	var connected := 0
	for topic in TOPICS:
		if answered.get(topic, -1) == TOPICS[topic][0]:
			connected += 1
	return connected * 100 >= TOPICS.size() * VISIT_PERCENT

static func saved_replies(state: Dictionary) -> Dictionary:
	var replies: Dictionary = state.get("trail_replies", {}).duplicate()
	var legacy := {7: "museo", 27: "cielo", 32: "bajada"}
	for day in legacy:
		if replies.has(day):
			replies[legacy[day]] = replies[day]
			replies.erase(day)
	if state.get("trail_check_in", false):
		replies["cauce"] = int(state.get("asked_mara_to_stay", false))
	return replies
