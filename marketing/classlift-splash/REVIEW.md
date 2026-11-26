# Revisión del splash

Libro que se abre, flecha trazada hacia arriba y nombre que toma color en dos tiempos. Se conserva la identidad y el fondo original. Sin sonido por tratarse del arranque de una app; sin bucles decorativos.

Implementado en Flutter con animación nativa: 1150 ms + 350 ms de espera final, aproximadamente la duración anterior. Hyperframes es el prototipo editable; el video conserva el estado final hasta los 3 s para inspección. Las curvas de interpolación de los dos motores tienen pequeñas diferencias.

Verificado: 7 pruebas del splash, captura del widget real a 0, 150, 300, 500, 700, 1000 y 1400 ms; análisis de Dart sin problemas. Hyperframes check aprobado sin errores ni advertencias; inspeccionadas las láminas de secuencia, teléfono y trazo de flecha. Una única escena, por lo que no hay transiciones entre escenas que revisar.

Corregido: contraste del texto secundario a #617392. Separados los dos segmentos de la flecha en la maqueta para que el trazo avance en orden y no aparezca toda la flecha por fundido. La captura de Flutter habilita sombras reales, desactivadas por defecto en las pruebas.

Actualización instalada el 24 de noviembre de 2026: ClassLift 1.0.0 (2026112403), com.pitta.classlift, en iPhone de Enrique. Build Release con Xcode Beta, firma de desarrollo y perfil vigente para ese iPhone comprobados. CoreDevice confirmó conexión local, instalación, versión instalada y lanzamiento real; el proceso permaneció activo tras arrancar.

Límite: no se midió visualmente la duración del splash en el teléfono físico. La primera fase del libro es breve por el límite de 1,5 s; si se quisiera un gesto más pausado, habría que reducir otro movimiento o alargar el arranque. No se alargó.

Entrega: renders/ClassLift-splash-animado.mp4, maqueta Hyperframes de 3 s, 1170 × 2532, 60 fps. No es una grabación del iPhone.
