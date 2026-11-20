# Uritorco · Registro de pasadas

## Hecho en esta pasada

- Se recuperó una copia editable del paquete del 19 de noviembre en `game-recovered/`. Se verificó la importación desde cero y que arranca en Godot 4.6.3. El proyecto editable `uritorco/game/` usado en las últimas pasadas sigue ausente. [Descarga que sirvió de base](https://github.com/ignacioaragues/uritorco/blob/descarga-windows-2026-11-19/Uritorco-Windows-x64.zip)
- En la copia recuperada, las manos bajan al guardar un objeto antes de subir el siguiente. El mapa se muestra con una sola mano y al cerrarlo vuelve la brújula si estaba afuera. Pasaron las pruebas de guardar, cambiar al mapa, alternar teclas rápido y pasar del mapa a la radio.
- La rama `codigo-fuente` guarda el proyecto recuperado, sus recursos y este registro. Cada tanda de recuperación debe quedar en un commit de esa rama junto con su verificación.
- Al cierre de cada pasada, registrar los cambios incorporados y los pendientes que quedan. Preparar una exportación de Windows cuando se pida.

## Ya implementado en las pasadas anteriores

Esta lista reconstruye el estado informado del proyecto editable. La exportación anterior se comprobó por separado.

- **Prólogo.** Ocho microescenas con recuerdos e interacciones propias. La ruta empieza frente a la parada, la mochila se recoge con E o clic, y los tramos siguientes incluyen tronco, puente, brújula, mapa, cuerda, linterna y una caminata final. F1 muestra el objetivo por unos segundos. «Clic para seguir» espera unos cuatro segundos. Paula y la muerte del padre de Hernán en septiembre figuran en los recuerdos.
- **Refugio.** Mara da la bienvenida la primera noche. La mochila se deja en el suelo, y el libro y las pertenencias aparecen al día siguiente. Hay silla, escritorio al lado de la cama, calendario que tacha fechas, cerca con tranquera y puerta de baño. La postal vieja de Paula ocupa la pared. Con E se levanta o se deja y con X se da vuelta. El libro tiene tapa, guarda y lámina de la Cruz del Sur. La guarda y la cinta dependen de las decisiones del prólogo.
- **Días y rutinas.** El Día 2 se habla con Mara después de medir el cauce y se puede pasar el parte de día. El primer sueño tiene su propio despertar y una anotación. El mate abre el Día 32. Al guardarlo, la mano baja y vuelve con la radio.
- **Cumbre y mapa.** Los mojones apoyan en la malla. Se probó toda la bajada hasta el banco del acceso, donde E cierra la travesía. El Día 36 retoma en el refugio. Las láminas fijas tienen puntos cardinales, cruz para la posición y marca de objetivo. Hay ramales hacia el mirador, la cantera, la quebrada y la cumbre.
- **Sueños y padre.** Los tres sueños usan relieves alienígenas sin vegetación serrana. El primero deja probar la baja gravedad y mirar las estrellas. El segundo usa la pieza y el último se cierra al tocar el arco por cercanía. Cinco noches tienen recuerdos distintos del padre. En las noches 25 y 32 se puede practicar con la Cruz del Sur. El regreso de la última noche reconoce esa práctica, y Hernán también puede guiarse por lo que recuerda de su padre. La voz del último sueño queda sin identificar.
- **Mara y finales.** Hay cuatro charlas opcionales durante las caminatas. Las respuestas matizan la despedida. La opción de ir a su puerta requiere al menos dos charlas, con cualquier respuesta. La casa está integrada al terreno del valle. Se probaron la entrada a pie, las combinaciones que habilitan los finales y la reapertura de un guardado con el final de la puerta. Los dos epílogos aparecen sobre negro y Mara queda fuera de escena.
- **Misterio y cueva.** Los destellos del Día 7 están anclados al cielo sobre la ladera. La cumbre, la advertencia en la pasarela y el receptor de la cueva comparten dos golpes secos. La última noche permite seguir las luces, recorrer la cueva con linterna y saltos con repisa segura, leer los cuadernos de los setenta, orientarse sin brújula y decidir si ir al claro. El origen de las luces y la voz sigue abierto.
- **Museo.** Edificio transitable con puerta, vitrinas y láminas, incluida la de los vikingos. La visita es opcional. El dibujo del arco está detrás del parte del poste del 12 de julio y remite a los cuadernos de la cueva.
- **Audio, cielo y ajustes.** Música por momentos, tono breve para el diálogo y estática en eventos de la trama. Hay pájaros animados, climas por día, nubes, llovizna y luna con fases. Los ajustes se pueden abrir durante el juego. Hay un menú de depuración con hitos seleccionados.

## Todavía pendiente

- **Cambios posteriores a la descarga.** Recuperar o reincorporar en la copia editable los tres terrenos alienígenas y sus interacciones, el despertar y el mate, la ampliación del museo y la visita opcional, la casa de Mara integrada al valle, los mojones y el cierre del descenso, las charlas de caminata y la condición de la puerta, los recuerdos del padre y la señal de los dos golpes. La descarga recuperada todavía conserva las luces del primer sueño y la entrega obligatoria de la nota en el museo.
- **Cielo de los sueños.** Mostrar «????» también al apuntar a estrellas o lunas en los otros sueños.
- **Pasada narrativa.** Recorrer de corrido el prólogo y los días para ajustar pausas, caminatas, charlas, pistas y saltos entre jornadas. Escuchar la mezcla de diálogo, música, interferencia y linterna durante la última noche.
- **Prólogo y controles.** Volver a comprobar la mochila desde la cámara inicial, los extremos de la ruta, el agua a los costados del puente y el corte a la llegada. Pulir la trepada por la laja del mapa principal, con el cuerpo junto a la pared y apoyos visibles.
- **Valle y refugio.** Corregir la unión diagonal, el cambio de color del sendero y el recorte del terreno visto desde arriba. Dar al cauce un acceso cuesta abajo y comprobar su extensión visible. Revisar el despeje de la tranquera y la orientación hacia la casa de Mara desde la parada.
- **Arte y legibilidad.** Mejorar de cerca los modelos, la vegetación, los árboles y las texturas. Revisar el libro cerrado, los carteles tapados, el aspecto de la luna y las estrellas, y textos largos de radio a distintas resoluciones. Probar que los sonidos de pasos se lean como tierra.
- **Caminatas y herramientas.** Ampliar la red de ramales, comparar duración de caminatas y completar los hitos disponibles en el selector de depuración.
- **Windows.** Validar la próxima exportación cuando se solicite.
