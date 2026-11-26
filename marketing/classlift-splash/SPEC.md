# ClassLift · Splash animado

GOAL: Dar vida al logo durante el arranque sin alargar la espera existente.
OUTPUT: Prototipo editable Hyperframes, 1170 × 2532, 60 fps, 3 segundos. Flutter: 1150 ms de animación + 350 ms de marca estable; la maqueta prolonga la imagen final para revisión.
LOOK: Logo SVG real, Poppins 400/700 del repositorio. Fondo azul hielo y ondas del splash existente. Sin audio, destellos ni partículas.
MOTION: Tile visible desde el primer frame; libro abre 92–656 ms; flecha asciende 345–897 ms; Class/Lift toman color 460–989 ms. Halo se expande una sola vez. Marca inmóvil al terminar.
IMPLEMENTATION: Canvas y AnimationController nativos; sin reproducción de video ni nuevas dependencias. Otros usos del logo conservan su imagen estática por defecto. Reducir movimiento muestra el estado final desde el primer frame.
SOURCES: assets/icons/classlift_mark.svg, lib/screens/splash_screen.dart, lib/widgets/classlift_logo.dart. Trazado basado en registry svg-stroke-trace, sin su deriva continua.
QA: Frame inicial, apertura, flecha a mitad y estado final. Navegación a login/home, disposición vertical/horizontal, cancelación al desmontar y accesibilidad.
