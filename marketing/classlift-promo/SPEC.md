# ClassLift · ¿Eso era para hoy?

GOAL: Que un estudiante reconozca el problema de buscar horarios y entregas en lugares distintos y conozca ClassLift.
OUTPUT: HyperFrames, 1080 × 1920, 30 fps, 25 s = 750 frames.
STORY: Concepto propuesto y aceptado en la conversación: mensaje urgente → información dispersa → ClassLift → calendario → tareas → alivio → marca.
LOOK: Poppins 800, títulos 82–100 px, cuerpo 30–48 px. Colores reales #333D86, #A3C1E2, #FF6F61; superficies #ECF2FF y #E5F6F1. Margen izquierdo 145 px. Contenido esencial x=145..775, y=326..1235. Sombras de tarjetas 0/20/50, opacidad 10%. Sin grano.
OBJECTS: Mensajes de ejemplo; pantallas renderizadas desde los widgets reales de Flutter; logo SVG del repositorio. Los datos son ficticios. Los clips de UI son demostraciones capturadas, no recreaciones HTML de la app.
MOTION: Entradas power3.out 12–18 frames; reordenamiento expo.out 16 frames; transición de panel power3.inOut 12 frames; marca back.out(1.25) 16 frames. Una acción por momento.
AUDIO: Pendiente del inicio de sesión que el usuario eligió para usar el catálogo. Música instrumental luminosa y ligera; tensión al comienzo, apertura en el segundo 6; efectos discretos de notificación y transición. No voz en esta primera versión.
SHOTS: 0–179 notificación y desorden; 180–269 cambio de ritmo; 270–419 app y calendario expandido; 420–599 tareas y listado; 600–659 beneficio; 660–749 marca y CTA.
BANNED: UI inventada, funciones futuras, datos personales, personas sintéticas, badges App Store sin enlace, logo en esquina, perspectiva 3D sobre UI, texto pequeño, destellos, partículas, música sintetizada por código.
QA: Revisar primer frame; calendario antes/después del toque; apertura de Ver todas; retorno al resultado; marca estable durante al menos 2 s. Verificar a 360 px y revisar cada corte ±0.2 s.
