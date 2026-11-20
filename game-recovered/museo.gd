extends RefCounted

const DISTANCE: = 292.0
const LABELS = {
	"Bastón de Mando": "Bastón de Mando · Relato esotérico\n\nLa historia de un bastón oculto en el Uritorco circula en libros y testimonios del siglo XX. La maqueta de esta sala representa ese relato. Su procedencia arqueológica sigue sin establecerse.", 
	"Vikingos en las sierras": "Vikingos en las sierras · Hipótesis sin respaldo arqueológico\n\nAlgunos autores atribuyeron marcas serranas a viajeros nórdicos. Para fecharlas y atribuirlas harían falta piezas con contexto verificable. Una semejanza de forma también puede aparecer entre pueblos que nunca se encontraron.", 
	"Luces sobre el cerro": "Luces sobre el cerro · Archivo de testimonios\n\nLos relatos OVNI del Uritorco incluyen observaciones, fotografías y reconstrucciones. Anotar la hora, el rumbo y la posición del observador permite comparar versiones y examinar explicaciones terrestres.", 
	"Maqueta del arco": "Maqueta del arco · Reconstrucción a partir de un dibujo anónimo\n\nLa ficha lleva fecha del 12 de julio. El dibujo muestra dos pilares, un dintel torcido y un cuerpo suspendido en el hueco. El margen de la hoja está arrancado.", 

	"Nota del museo": "Fui al pueblo a buscar el vidrio de la vitrina. Quedó abierto. Si entra viento, arrimá la puerta al salir.", 
	"Sala de las sierras": "Museo de sitio · Pueblos comechingones\n\nLas comunidades comechingonas forman parte del presente de Córdoba. Esta pequeña sala reúne reproducciones didácticas de objetos de las Sierras Centrales.", 
	"Mortero y mano": "Mortero y mano de piedra · Reproducción\n\nLa piedra inferior tiene una cavidad. Una segunda piedra, la mano, sirve para machacar dentro de ella. El desgaste se concentra en el fondo y en las paredes. Por sí sola, esa huella no identifica qué se molió.", 
	"Tortero": "Tortero cerámico · Reproducción\n\nEl orificio central permite ensartar el disco en un huso de madera. Al girar, su peso ayuda a mantener la rotación mientras los dedos estiran y tuercen las fibras.", 
	"Vasija de cerámica": "Vasija de pasta cocida · Reproducción\n\nEl cuerpo se puede levantar superponiendo rollos de arcilla y alisando las uniones. La forma de la boca permite comparar recipientes. Para interpretar su uso también importan los residuos y el lugar del hallazgo."
}

static func build(v):
	var route = v.route
	var c: Vector3 = route.at(route.trail(DISTANCE) + 6, DISTANCE)

	c.y += 0.48
	v.box(c - Vector3.UP * 0.55, Vector3(6.8, 1.1, 5.8), "90806c", true)
	for side in [-1, 1]:
		v.plaster(v.box(c + Vector3(side * 3.35, 1.36, 0), Vector3(0.16, 2.72, 5.8), "cab492", true))
		v.box(c + Vector3(side * 2.28, 1.36, -2.82), Vector3(2.13, 2.72, 0.17), "bda787", true)
	v.plaster(v.box(c + Vector3(0, 1.36, 2.82), Vector3(6.8, 2.72, 0.16), "cab492", true))
	v.box(c + Vector3(0, 2.85, 0), Vector3(7.3, 0.16, 6.4), "786f60", true)
	label(v, c + Vector3(0, 2.32, -2.96), "Sala de las sierras")
	v.box(c + Vector3(1.95, 0.45, -1.9), Vector3(1.08, 0.9, 0.58), "856e54", true)
	var note = v.box(c + Vector3(1.91, 0.918, -1.9), Vector3(0.38, 0.018, 0.29), "ddd1b6", true, "Nota del museo")
	note.rotation.y = 0.18
	var lamp: = OmniLight3D.new()
	v.add_child(lamp)
	lamp.position = c + Vector3.UP * 2.2
	lamp.omni_range = 6
	lamp.light_energy = 0.68
	for i in 3:
		var pos: Vector3 = c + Vector3((i - 1) * 2.1, 0.72, 0.84)
		v.box(pos - Vector3.UP * 0.36, Vector3(1.72, 0.72, 0.9), "71614c", true)
		var name: String = ["Mortero y mano", "Tortero", "Vasija de cerámica"][i]
		label(v, pos + Vector3(0, - 0.12, - 0.48), name)
		if i == 0:
			var rim: = TorusMesh.new()
			rim.inner_radius = 0.13
			rim.outer_radius = 0.28
			v.prop(rim, pos + Vector3.UP * 0.07, "847c6d", true, name)
			v.stone(pos + Vector3(0.41, 0.07, 0), Vector3(0.16, 0.16, 0.34), "9b917e")
		elif i == 1:
			var wheel: = TorusMesh.new()
			wheel.inner_radius = 0.023
			wheel.outer_radius = 0.104
			v.prop(wheel, pos + Vector3.UP * 0.09, "ab7750", true, name)
			v.box(pos + Vector3.UP * 0.15, Vector3(0.018, 0.3, 0.018), "81654a")
		else:
			var pot: = SphereMesh.new()
			pot.is_hemisphere = true
			var body = v.prop(pot, pos + Vector3.UP * 0.3, "ab7251", true, name)
			body.scale = Vector3(0.48, 0.54, 0.48)
			body.rotation.x = PI
			var lip: = TorusMesh.new()
			lip.inner_radius = 0.167
			lip.outer_radius = 0.218
			v.prop(lip, pos + Vector3.UP * 0.31, "905e40")

static func dress_archive(v):
	var route = v.route
	var c: Vector3 = route.at(route.trail(DISTANCE) + 6, DISTANCE) + Vector3.UP * 0.48
	for i in 3:
		var pos: = c + Vector3((i - 1) * 2.03, 1.52, 2.66)
		label(v, pos, ["Bastón de Mando", "Vikingos en las sierras", "Luces sobre el cerro"][i])
	var replica = c + Vector3(-2.12, 1.13, 2.48)
	var staff = v.box(replica, Vector3(0.065, 0.81, 0.074), "57473b", true, "Bastón de Mando")
	staff.rotation.z = 0.26
	for i in 3:
		var photo = v.box(c + Vector3(1.82 + i * 0.27, 1.13 + i * 0.04, 2.58), Vector3(0.21, 0.17, 0.018), "c7b99e", true, "Luces sobre el cerro")
		photo.rotation.z = 0.09 * (i - 1)
	var base: = c + Vector3(2.7, 0.64, -1.28)
	v.box(base - Vector3.UP * 0.32, Vector3(0.92, 0.64, 0.65), "71614c", true)
	preload("res://estructuras.gd").arch(v, base, 0.25)
	label(v, base + Vector3(0, - 0.13, - 0.34), "Maqueta del arco")

static func label(v, p: Vector3, title: String):
	v.box(p, Vector3(1.72, 0.3, 0.045), "514838", true, title)
	var text: = Label3D.new()
	v.add_child(text)
	text.position = p - Vector3(0, 0, 0.026)
	text.rotation.y = PI
	text.text = title
	text.font_size = 28
	text.pixel_size = 0.0025
	text.outline_size = 0
