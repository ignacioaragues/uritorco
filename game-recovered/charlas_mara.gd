extends RefCounted

const Creek = preload("res://cauce.gd")
const Museum = preload("res://museo.gd")
const Trail = preload("res://travesia.gd")
const LastNight = preload("res://final_night.gd")

const VISIT_PERCENT := 60

const HERNAN_STARTS := ["piedras", "vaguada", "cable", "regreso"]
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
		0, "Mara, ahora que vuelvo por la huella veo un brillo en las piedras. Desde arriba me habían parecido todas iguales.",
		["¿Vos alguna vez te llevaste una de acá?", "Mañana quiero volver a verla a esta hora."],
		[
			["Una blanca del cauce. La uso para sostener el mantel cuando abro la ventana.", "Tengo otra en el cajón. Te la mando con las pilas. Con el viento de arriba te va a servir para el mapa."],
			["Fijate desde qué lado te dio el sol. Si volvés por la misma huella, buscá la marca que hiciste en la regla."]
		]
	],
	"museo": [
		0, "Si entrás al museo, fijate en las fichas. La letra chiquita es de Elvira. Le toca cambiar los papeles cada vez que entra agua.",
		["¿Querés que le mande saludos de tu parte?", "Decile que valió la pena dejar la puerta abierta."],
		[
			["Decile que por fin le devolví la llave. Va a entender.", "Las primeras fichas las copiamos juntas en la cocina. Yo escribía los títulos porque se veían mejor desde el pasillo."],
			["Se lo digo. Hay semanas en que sólo entra ella, a ver si la humedad levantó otra esquina."]
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
		0, "Mara, llegué a la laja. Desde acá se ve una huella por abajo.",
		["¿La conocés? Desde el sendero no se ve dónde vuelve a subir.", "Mi viejo siempre me decía que antes de bajar mirara por dónde iba a volver."],
		[
			["La aprendí llevando una batería. Había llovido y no me daban las manos para la cuerda.", "Cuando dejes de ver el agua, buscá las marcas claras del otro lado. Por ahí vuelve la huella."],
			["Buen consejo. Desde abajo vas a ver una laja casi blanca. La salida está al costado."]
		]
	],
	"sueno": [
		0, "¿Te está dando para dormir ahí arriba? Los primeros días a mí me despertaba el ruido de la chapa.",
		["Soñé con un cielo que no conocía. Dibujé las estrellas para ver si después me acordaba.", "Duermo de a ratos. Lo demás prefiero dejármelo para mí."],
		[
			["¿Te quedó algún dibujo que puedas reconocer de noche?", "Guardalo. A veces al día siguiente uno ya empieza a acordarse de otra cosa."],
			["Sí, claro. Si necesitás algo para la cama, hay otra frazada en el puesto de abajo."]
		]
	],
	"cielo": [
		0, "Hace días que te quiero preguntar algo. ¿Por qué aceptaste venir al puesto?",
		["Mi viejo murió en septiembre. Mirábamos el cielo juntos. Pensé que acá iba a poder levantar la vista de nuevo.", "Necesitaba salir un tiempo de casa. Por ahora prefiero contarte hasta ahí."],
		[
			["Ah, Hernán. No sabía.", "Si salís a mirar algún día y querés compañía, dejame el canal abierto. No hace falta que hablemos."],
			["Está bien. Gracias por decirme hasta dónde.", "Si un día te sirve quedarte en línea un rato, avisame."]
		]
	],
	"cable": [
		1, "Mara, estoy bajando junto al cable. Con el viento parece que alguien estuviera afinando una cuerda.",
		["Lo marqué junto al poste, por si tienen que volver a tensarlo.", "¿Escuchás el cable desde ahí? Quedate un segundo en silencio conmigo."],
		[
			["Gracias. Deciles a los de mantenimiento que miren el anclaje del lado del corte."],
			["Ahí. Entró un poquito al final de lo que dijiste.", "Había días que yo subía sin radio para oír cómo cambiaba eso con el viento. Después me fui acostumbrando a llevarla prendida."]
		]
	],
	"pircas": [
		0, "Desde que viniste hablamos más de cómo volver al puesto que de qué vas a hacer cuando te vayas. ¿Hay alguien a quien quieras ver?",
		["Pensé en escribirle a Paula. Hace mucho que no hablamos y todavía me encuentro guardándole cosas para contarle.", "Todavía no sé. Prefiero llegar a casa y ver qué me pasa."],
		[
			["¿Ella sabe que estás en el cerro?", "Si algún día le escribís, contale una de esas cosas que le guardaste. Lo demás puede esperar."],
			["Sí. Hay cosas que se piensan mejor cuando ya bajaste.", "Avisame cuando pases las pircas. Si querés, el otro tramo lo hacemos con el canal abierto."]
		]
	],
	"bajada": [
		1, "Cuando veas el banco ya estás fuera de la parte fea de la bajada. Tengo el equipo al lado. Si querés, me quedo.",
		["Ya veo por dónde sigo. ¿Dónde te dejo la llave el último día?", "Quedate un rato. Cada vez que suelto el botón vuelve a oírse el viento."],
		[
			["En el cajón del escritorio. Tengo una copia para el próximo relevo. Avisame al llegar al banco."],
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
		["Sí. ¿Te quedás conmigo hasta que entre al patio?", "Sí, la veo. Si vuelve a entrar la voz, te anoto la hora."],
		[
			["Sí. Yo me quedo acá. Avisame cuando estés del otro lado de la verja."],
			["Dale. Yo voy a dejar anotada la hora que escuché el primer golpe."]
		]
	],
	"regreso": [
		1, "Mara, ya salí. Me cuesta creer que sea la última vez que vengo por esta huella.",
		["Cuando llegue a casa voy a abrir la ventana y dejar todo en el bolso.", "Creo que voy a salir a mirar el cielo desde la vereda. Hace mucho que no lo hago."],
		[
			["El bolso puede esperar hasta mañana. Si te olvidaste algo, yo subo al puesto después."],
			["Ojalá esté despejado. Si llegás a ver la cruz, pensá que desde acá va a estar para el mismo lado."]
		]
	],
	"ultima_curva": [
		1, "Desde esa curva, el puesto se ve un rato más cuando arranca el ómnibus. Yo siempre lo busco entre los árboles.",
		["Voy a sentarme del lado de la sierra.", "Voy a extrañar más que la vista. Vos también me vas a hacer falta."],
		[
			["Sentate adelante si hay lugar. De atrás a veces sólo se ve el polvo."],
			["A mí también me va a faltar oírte llegar. Hoy dejé la radio prendida un rato antes de que salieras."]
		]
	]
}

static func opening(topic: String, answered: Dictionary, mica_told: bool, abra_told: bool, paula_told: bool) -> String:
	match topic:
		"piedras":
			if mica_told: return "Mara, pensé en la mica que te conté. A la vuelta cambió la luz y las piedras ya no brillaban igual."
		"antena":
			if abra_told: return "Dejé la luz y la voz en renglones separados, como me las contaste. Quedate un segundo en la antena. ¿Probamos hasta dónde llega el canal?"
		"cielo":
			if answered.get("sueno", -1) == 0: return "Me quedé pensando en lo que dibujaste del sueño. ¿Qué fue lo que te hizo aceptar este trabajo, Hernán?"
		"pircas":
			if answered.get("cielo", -1) == 0: return "La otra vez me contaste por qué viniste al puesto. Ahora que falta poco, ¿hay alguien a quien tengas ganas de ver al bajar?"
		"regreso":
			if paula_told: return "Mara, salí con ganas de escribirle a Paula. Pero eso puede esperar. Ahora me cuesta creer que sea la última vez que vengo por esta huella."
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
		return "A Elvira le conté que te habías fijado en las fichas. Me hizo prometer que iba a pasar por el museo a tomar mate."
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
		2: return 12.0
		41: return 15.0
		_: return 26.0

static func seconds_between_calls(day: int) -> float:
	return 8.0 if day in [2, 41] else 16.0

static func near(position: Vector3, center: Vector3, radius: float) -> bool:
	return Vector2(position.x - center.x, position.z - center.z).length_squared() < radius * radius

static func can_visit(answered: Dictionary) -> bool:
	var connected := 0
	for topic in TOPICS:
		var answer: int = answered.get(topic, -1)
		if answer == TOPICS[topic][0] or (answer == 1 and topic in RESERVED_ANSWERS):
			connected += 1
	return connected * 100 >= TOPICS.size() * VISIT_PERCENT

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
