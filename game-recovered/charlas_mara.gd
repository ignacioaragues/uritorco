extends RefCounted

const Creek = preload("res://cauce.gd")
const Museum = preload("res://museo.gd")
const Trail = preload("res://travesia.gd")
const LastNight = preload("res://final_night.gd")

const VISIT_PERCENT := 60

# Respuesta que genera cercanía, pregunta, opciones de Hernán y réplicas de Mara.
const TOPICS = {
	"alero": [
		0, "Cuando me tocó mi primer turno, tardé un rato en acostumbrarme a lo lejos que quedaba todo. ¿Desde acá te llega ruido del camino?",
		["«Por ahora oigo más tu radio».", "«Me acostumbraré mañana»."],
		[
			["Si necesitás ubicarte, llamá. Yo termino de escribir el parte y sigo en el puesto un rato."],
			["Con luz se entiende mejor el terreno. La primera mañana me sorprendió lo cerca que se veía la sierra."]
		]
	],
	"primera_noche": [
		0, "Cuando me toca el turno de noche dejo prendida la luz del puesto. Así el que pasa por el camino sabe que hay alguien despierto.",
		["«Se agradece tener a alguien del otro lado».", "«¿Te toca seguido el turno de noche?»"],
		[
			["Yo la dejaba prendida cuando mi vieja volvía tarde. Después se me hizo costumbre."],
			["Esta semana me toca hasta tarde. Me traje pan de casa para aguantar. Perdí la cuenta de cuánto llevaba en el horno, pero zafó."]
		]
	],
	"cauce": [
		1, "¿Cómo te está tratando el camino?",
		["Se agradece el silencio.", "Me vendría bien un poco de charla."],
		[
			["Te entiendo. Hay días que bajo por ahí para escuchar los pasos."],
			["Te acompaño un rato. Cuando doble la huella, fijate en las piedras claras del cauce."]
		]
	],
	"piedras": [
		0, "De chica llevaba una piedra de cada caminata. Una vez volví con tantas que tuve que dejar el agua para cerrar la mochila.",
		["«¿Todavía guardás alguna?»", "«Hoy casi me traigo una de acá»."],
		[
			["Una blanca y chata. La uso para que no se me vuele el mantel.", "Tengo otra parecida. Te la mando con las pilas. A vos te vendrá bien para sujetar el mapa."],
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
		0, "¿Ya encontraste el cable? La última vez que fui se veía bien entre las piedras. Te iba a preguntar algo. ¿Mirabas el cielo antes de venir acá?",
		["«Lo miraba con mi viejo. Desde que murió me cuesta un poco».", "«Estudié astronomía. Hace rato que miro más papel que cielo»."],
		[
			["Podés contarme de él si te dan ganas. A mí me gustaba escuchar a mi vieja reconocer pájaros.", "Ahora reconozco alguno. A veces me encuentro por decirle cuál es."],
			["Entonces te voy a pedir un favor. Desde el patio de casa siempre veo una estrella y nunca sé cómo se llama.", "Algún día te la señalo. Por radio terminaría señalándote media sierra."]
		]
	],
	"cable": [
		1, "Una vez me tocó subir a revisar el cable con viento. Entre las rocas sonaba como una cuerda de guitarra tirante.",
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
			["Podés dejarla en el cajón del escritorio. Acá en el puesto tengo una copia para el próximo relevo."],
			["Sí. Estoy lavando los platos del puesto. Si escuchás que se cae algo, seguí caminando.", "Vos avisame cuando veas el banco.", "Con el próximo cajón te mando algo. Guardalo para cuando termines el turno."]
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
		0, "Probé el otro equipo. Hay una frecuencia cerca que se mete en la nuestra cuando llueve. Lo que oíste diciendo «no cruces» todavía no sé de dónde salió. ¿Ya ves la tranquera?",
		["«Sí. ¿Me dejás el canal abierto hasta que entre?»", "«Ya la veo. Te aviso desde el patio»."],
		[
			["Sí. Por acá ya paró. Me quedo hasta que me digas que llegaste."],
			["Dale. Si vuelve a entrar esa voz, decime la hora. La voy a anotar de este lado."]
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
				elif position.z >= -14.0 and position.z <= -5.5: topic = "primera_noche"
		4:
			if near(position, Creek.trail_point(0.91), 13.0): topic = "cauce"
		5:
			if bedtime and near(position, Creek.trail_point(0.53), 18.0): topic = "piedras"
		7:
			if on_ridge(position, Museum.DISTANCE, 33.0):
				topic = "museo"
			elif sighting and bedtime and on_ridge(position, 389.0, 27.0):
				topic = "antena"
		8:
			if on_ridge(position, 164.0, 49.0): topic = "vaguada"
		9:
			if bedtime and on_ridge(position, 596.0, 91.0): topic = "sueno"
		10:
			if near(position, Trail.quarry_point(Trail.WEST_JOIN), 47.0): topic = "cielo"
		12:
			if near(position, Trail.quarry_point(0.72), 45.0): topic = "cable"
		13:
			if near(position, Trail.ascent_point(0.28), 94.0): topic = "pircas"
		15:
			if near(position, Trail.ascent_point(0.60), 86.0): topic = "bajada"
		16:
			if near(position, Creek.crossing_point(0.42), 24.0): topic = "lluvia"
		18:
			if near(position, Vector3(1.0, 0.0, -10.0), 25.0): topic = "ventana"
		19:
			if near(position, Vector3(4.0, 0.0, -30.0), 13.0):
				topic = "regreso"
			elif near(position, LastNight.STOP, 13.0):
				topic = "ultima_curva"
	return topic if not answered.has(topic) else ""

static func on_ridge(position: Vector3, distance: float, radius: float) -> bool:
	return near(position, Vector3(Trail.trail(distance), 0.0, Trail.ORIGIN_Z - distance), radius)

static func distance_between_calls(day: int) -> float:
	match day:
		1: return 3.0
		2: return 12.0
		41: return 15.0
		_: return 26.0

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
