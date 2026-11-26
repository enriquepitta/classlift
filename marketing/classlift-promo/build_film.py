"""Build the editable HyperFrames composition, retaining real app screenshots."""
from pathlib import Path
import json

P = Path(__file__).parent
COMMON = """@font-face{font-family:Poppins;src:url('assets/fonts/Poppins-Regular.ttf');font-weight:400}
@font-face{font-family:Poppins;src:url('assets/fonts/Poppins-SemiBold.ttf');font-weight:600}
@font-face{font-family:Poppins;src:url('assets/fonts/Poppins-ExtraBold.ttf');font-weight:800}
*{box-sizing:border-box}#root{position:absolute;inset:0;overflow:hidden;font-family:Poppins;color:#333D86}
.stage{position:absolute;inset:0}.title{position:absolute;left:145px;top:326px;width:650px;margin:0;font-size:84px;line-height:1.12;font-weight:800;letter-spacing:-4px}
.note{position:absolute;left:145px;top:1195px;font-size:28px;font-weight:400;line-height:1.3;margin:0;color:#495780}
.decoration{position:absolute;pointer-events:none}.rule{left:145px;top:275px;width:80px;height:9px;background:#333D86}
.screen{position:absolute;left:145px;top:570px;width:630px;height:600px;overflow:hidden;border-radius:28px;box-shadow:0 22px 52px #28366520;background:#fff}
.screen img{position:absolute;left:0;top:0;width:630px;height:auto;transform-origin:0 0}
.tap{position:absolute;width:70px;height:70px;border:5px solid #FF6F61;border-radius:50%;opacity:0}
"""

def scene(name, duration, markup, css, js):
    text = f'''<!-- ClassLift composition. Real UI captured from Flutter; fixtures are fictional. -->
<template>
<style>{COMMON}\n{css}</style>
<div id="root" data-composition-id="{name}" data-width="1080" data-height="1920">
  <div id="{name}-stage" class="clip stage" data-start="0" data-duration="{duration}" data-track-index="0">
  {markup}
  </div>
</div>
<script>
(function(){{
  const tl = gsap.timeline({{paused:true}});
  {js}
  window.__timelines=window.__timelines||{{}};
  window.__timelines['{name}']=tl;
}})();
</script>
</template>'''
    (P/'compositions'/f'{name}.html').write_text(text)

# Adapt the installed notification-cascade registry block: retain its stacked
# banner premise and expo.out restacking, replace all content and stage geometry.
scene('notification-cascade',6, '''
<div class="decoration nc-stripe" aria-hidden="true" data-layout-allow-overflow></div>
<div class="decoration rule" aria-hidden="true"></div>
<h1 id="nc-hook" class="title"><span data-var-text="hook">¿Eso era</span><br>para <span class="nc-hot">HOY?</span></h1>
<h1 id="nc-tension" class="title">Todo en<br>distintos lados.</h1>
<div id="nc-banner1" class="nc-banner" data-layout-allow-overlap>
  <div class="nc-symbol">…</div><div class="nc-label">Grupo de clase</div>
  <div class="nc-message">¿Ya entregaste<br>el trabajo?</div>
</div>
<div id="nc-banner2" class="nc-banner"><div class="nc-symbol nc-sheet">▦</div><div class="nc-label">El archivo del horario</div><div class="nc-message">¿Qué clase toca?</div></div>
<div id="nc-banner3" class="nc-banner"><div class="nc-symbol nc-campus">!</div><div class="nc-label">El campus virtual</div><div class="nc-message">¿Cuándo se entrega?</div></div>
''', '''
#root{background:#FFE9E4}.nc-stripe{left:-90px;top:1440px;width:1280px;height:150px;background:#FF6F61;transform:rotate(-12deg)}
.nc-hot{color:#AE302C}.nc-banner{position:absolute;left:145px;top:800px;width:630px;height:200px;background:#fff;border-radius:28px;box-shadow:0 16px 30px #9F453319;padding:30px 24px 20px 108px}
.nc-symbol{position:absolute;left:25px;top:34px;width:60px;height:60px;background:#DDF8EC;color:#27745A;border-radius:18px;font-size:38px;font-weight:800;text-align:center;line-height:60px}
.nc-sheet{background:#E6EAFC;color:#333D86;font-size:38px;line-height:58px}.nc-campus{background:#FFE9E4;color:#AE302C;line-height:60px}
.nc-label{font-size:29px;line-height:1.4;font-weight:600;color:#58617A}.nc-message{margin-top:6px;font-size:36px;line-height:1.28;font-weight:600;letter-spacing:-.8px}
#nc-banner2{top:810px;height:165px}#nc-banner3{top:1000px;height:165px}
''', '''
tl.fromTo('#nc-hook',{scale:1.025},{scale:1,duration:.4,ease:'power3.out'},0);
tl.fromTo('#nc-banner1',{x:760,rotation:5},{x:0,rotation:0,duration:.6,ease:'expo.out'},.55);
tl.fromTo('#nc-tension',{x:1100,opacity:0},{x:0,opacity:1,duration:.5,ease:'power3.out'},3);
tl.to('#nc-hook',{x:-1100,opacity:0,duration:.45,ease:'power3.in'},2.8);
tl.to('#nc-banner1',{y:-210,duration:.55,ease:'expo.out'},3.05);
tl.fromTo('#nc-banner2',{x:1100,opacity:0},{x:0,opacity:1,duration:.55,ease:'expo.out'},3.2);
tl.fromTo('#nc-banner3',{x:1100,opacity:0},{x:0,opacity:1,duration:.55,ease:'expo.out'},3.6);
tl.to(['#nc-banner1','#nc-banner2','#nc-banner3'],{x:-1100,duration:.35,stagger:.04,ease:'power3.in'},5.5);
''')

scene('reveal',3, '''
<div id="reveal-sweep" class="decoration"></div>
<div class="decoration reveal-stair stair1"></div><div class="decoration reveal-stair stair2"></div><div class="decoration reveal-stair stair3"></div>
<div id="reveal-copy"><h1 class="title">Ordená<br>tu semana.</h1><p id="reveal-name">Con ClassLift.</p></div>
''', '''
#root{background:#333D86;color:#fff}#reveal-sweep{inset:0;background:#FFE9E4;transform-origin:100% 50%}
.title{top:485px;font-size:100px;line-height:1.13;letter-spacing:-5px}#reveal-name{position:absolute;left:150px;top:820px;margin:0;font-size:48px;font-weight:600;color:#BBD9FF}
.reveal-stair{background:#4F65B0;left:140px;top:1390px;width:200px;height:400px}.stair2{left:340px;top:1310px;height:480px}.stair3{left:540px;top:1230px;height:560px}
''', '''
tl.fromTo('#reveal-sweep',{scaleX:1},{scaleX:0,duration:.45,ease:'power4.inOut'},0);
tl.fromTo('#reveal-copy',{y:85,opacity:0},{y:0,opacity:1,duration:.5,ease:'power3.out'},.15);
tl.fromTo('.reveal-stair',{y:600},{y:0,duration:.65,stagger:.10,ease:'power3.out'},.55);
''')

scene('calendar',5, '''
<div class="decoration rule"></div>
<h1 id="calendar-title" class="title">Tu semana,<br>a la vista.</h1>
<div id="calendar-window" class="screen" data-layout-allow-overflow>
  <img id="calendar-home" src="assets/home.png" alt="ClassLift: horario de clases" data-layout-allow-overflow>
  <img id="calendar-month" src="assets/calendar.png" alt="ClassLift: calendario expandido" data-layout-allow-overflow>
</div>
<div id="calendar-tap" class="tap"></div>
<p class="note">Pantallas reales · Datos de ejemplo</p>
''', '''
#root{background:#ECF2FF}.screen{top:550px;height:615px;background:transparent;box-shadow:none;border-radius:25px}
#calendar-tap{left:425px;top:905px}.title{font-size:82px}
''', '''
tl.fromTo('#calendar-title',{x:50,opacity:0},{x:0,opacity:1,duration:.4,ease:'power3.out'},0);
tl.fromTo('#calendar-home',{scale:.43,x:178,y:0},{scale:.43,x:178,y:0,duration:.8},0);
tl.to('#calendar-home',{scale:1,x:0,y:-20,duration:.6,ease:'power3.inOut'},.8);
tl.fromTo('#calendar-month',{opacity:0,y:-20},{opacity:0,y:-20,duration:.01},0);
tl.fromTo('#calendar-tap',{scale:1.5,opacity:0},{scale:.75,opacity:1,duration:.2},2);
tl.to('#calendar-tap',{scale:1.4,opacity:0,duration:.35},2.2);
tl.to('#calendar-home',{opacity:0,duration:.12},2.2);
tl.to('#calendar-month',{opacity:1,duration:.12},2.2);
tl.to('#calendar-month',{y:-100,duration:.5,ease:'power2.out'},2.3);
''')

scene('tasks',6, '''
<div class="decoration rule"></div>
<h1 id="tasks-title" class="title">Tus entregas.<br>Bien a mano.</h1>
<div id="tasks-window" class="screen" data-layout-allow-overflow>
  <img id="tasks-home" src="assets/home-tasks.png" alt="Tareas de Moodle dentro de ClassLift" data-layout-allow-overflow>
  <img id="tasks-list" src="assets/tasks.png" alt="Listado real de tareas pendientes" data-layout-allow-overflow>
</div>
<div id="tasks-tap" class="tap"></div>
<p class="note">Conectá tu campus Moodle</p>
''', '''
#root{background:#E5F6F1}.screen{top:590px;height:565px;border-radius:28px;box-shadow:0 20px 50px #277C791A}
#tasks-tap{left:670px;top:602px}
''', '''
tl.fromTo('#tasks-title',{x:-60,opacity:0},{x:0,opacity:1,duration:.45,ease:'power3.out'},0);
tl.fromTo('#tasks-home',{y:-700},{y:-700,duration:.01},0);
tl.fromTo('#tasks-window',{x:100,opacity:0},{x:0,opacity:1,duration:.5,ease:'power3.out'},.1);
tl.fromTo('#tasks-list',{opacity:0,y:0},{opacity:0,y:0,duration:.01},0);
tl.fromTo('#tasks-tap',{scale:1.5,opacity:0},{scale:.75,opacity:1,duration:.2},2.45);
tl.to('#tasks-tap',{scale:1.4,opacity:0,duration:.3},2.65);
tl.to('#tasks-home',{x:-650,duration:.4,ease:'power3.inOut'},2.65);
tl.fromTo('#tasks-list',{opacity:1,x:650},{opacity:1,x:0,duration:.4,ease:'power3.inOut',immediateRender:false},2.65);
tl.to('#tasks-list',{y:-270,duration:.7,ease:'power2.inOut'},4.3);
''')

scene('payoff',2, '''
<div id="payoff-bar" class="decoration"></div>
<h1 id="payoff-copy" class="title">Menos buscar.<br><span>Más estudiar.</span></h1>
''', '''
#root{background:#BBD9FF}.title{top:600px;font-size:82px;line-height:1.45;letter-spacing:-4px}.title span{color:#23316E}
#payoff-bar{left:145px;top:880px;width:625px;height:14px;background:#333D86;transform-origin:0 50%}
''', '''
tl.fromTo('#payoff-copy',{y:50,opacity:0},{y:0,opacity:1,duration:.35,ease:'power3.out'},0);
tl.fromTo('#payoff-bar',{scaleX:0},{scaleX:1,duration:.5,ease:'power3.out'},.5);
''')

scene('endcard',3, '''
<img id="endcard-mark" src="assets/classlift.svg" alt="Logo de ClassLift">
<h1 id="endcard-name">ClassLift</h1>
<p id="endcard-tagline">Tu vida universitaria,<br>organizada.</p>
<div id="endcard-cta"><span data-var-text="cta">Conocé ClassLift</span><span aria-hidden="true">↗</span></div>
''', '''
#root{background:#333D86;color:#fff}#endcard-mark{position:absolute;left:355px;top:410px;width:200px;height:200px}
#endcard-name{position:absolute;left:145px;top:645px;width:630px;text-align:center;font-size:96px;line-height:1.2;letter-spacing:-4px;font-weight:800;margin:0}
#endcard-tagline{position:absolute;left:145px;top:810px;width:630px;text-align:center;font-size:37px;line-height:1.45;font-weight:400;margin:0;color:#D7E3FF}
#endcard-cta{position:absolute;left:225px;top:1020px;width:470px;padding:22px 26px;display:flex;justify-content:space-between;border:2px solid #A3C1E2;border-radius:12px;color:#fff;font-size:30px;font-weight:600}
''', '''
tl.fromTo('#endcard-mark',{y:100,scale:.7,rotation:-9},{y:0,scale:1,rotation:0,duration:.55,ease:'back.out(1.25)'},0);
tl.fromTo('#endcard-name',{clipPath:'inset(0 100% 0 0)'},{clipPath:'inset(0 0% 0 0)',duration:.5,ease:'power3.out'},.2);
tl.fromTo('#endcard-tagline',{opacity:0},{opacity:1,duration:.3},.3);
tl.fromTo('#endcard-cta',{opacity:0,y:20},{opacity:1,y:0,duration:.3,ease:'power2.out'},.5);
''')

shots=[('notification-cascade',0,6),('reveal',6,3),('calendar',9,5),('tasks',14,6),('payoff',20,2),('endcard',22,3)]
variables=[{'id':'hook','type':'string','label':'Pregunta inicial','default':'¿Eso era'},
           {'id':'cta','type':'string','label':'Llamada a la acción','default':'Conocé ClassLift'},
           {'id':'brand','type':'color','label':'Azul ClassLift','default':'#333D86'}]
mounts='\n'.join(f'<div id="{n}" class="clip" data-composition-id="{n}" data-composition-src="compositions/{n}.html" data-start="{s}" data-duration="{d}" data-track-index="0" data-track-kind="graphics" data-width="1080" data-height="1920"></div>' for n,s,d in shots)
(P/'index.html').write_text(f'''<!doctype html>
<html lang="es" data-resolution="portrait" data-composition-variables='{json.dumps(variables,ensure_ascii=False)}'>
<head><meta charset="utf-8"><meta name="viewport" content="width=1080,height=1920"><title>ClassLift — ¿Eso era para hoy?</title>
<script src="assets/vendor/gsap.min.js"></script>
<style>*{{box-sizing:border-box}}html,body{{margin:0;width:1080px;height:1920px;overflow:hidden;background:var(--brand,#333D86)}}#root{{position:relative;width:1080px;height:1920px}}.clip{{position:absolute;inset:0}}</style></head>
<body><div id="root" data-composition-id="main" data-start="0" data-duration="25" data-fps="30" data-width="1080" data-height="1920">
{mounts}
<!-- AUDIO_SLOT: catalog music and effects are added after account login. -->
</div><script>window.__timelines=window.__timelines||{{}};window.__timelines.main=gsap.timeline({{paused:true}});</script></body></html>''')

(P/'SPEC.md').write_text('''# ClassLift · ¿Eso era para hoy?

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
''')
(P/'STORYBOARD.md').write_text('''# Guion de 25 segundos

| Tiempo | Plano y acción | Texto |
|---|---|---|
| 0–3 | Mensaje de un compañero, pregunta visible desde el frame 0 | ¿Eso era para HOY? |
| 3–6 | Mensaje, archivo y campus se acumulan | Todo en distintos lados. |
| 6–9 | Barrido al azul de la marca, ritmo más calmado | Ordená tu semana. Con ClassLift. |
| 9–14 | Contexto de la pantalla de inicio; acercamiento y toque para expandir el calendario | Tu semana, a la vista. |
| 14–20 | Tarea en el inicio; toque de Ver todas y listado con fechas | Tus entregas. Bien a mano. |
| 20–22 | Mensaje de beneficio en azul claro | Menos buscar. Más estudiar. |
| 22–25 | Logo oficial, nombre, promesa y CTA | ClassLift. Tu vida universitaria, organizada. Conocé ClassLift. |

La narrativa aceptada se adapta a animación sin actor. Las pantallas usan datos ficticios capturados con los componentes reales. No se promete una descarga pública.
''')
(P/'ASSETS.md').write_text('''# Procedencia de los recursos

- classlift.svg: assets/icons/classlift_mark.svg del proyecto ClassLift.
- Fuentes Poppins: assets/fonts/Poppins del mismo proyecto.
- home.png, calendar.png, home-tasks.png, tasks.png: widgets Flutter reales con cuenta, materias y entregas de demostración. Captura reproducible en capture_app_test.dart; no se conecta a una cuenta real ni modifica datos del usuario. El arnés sustituye la fuente cuadrada de pruebas por Poppins para los textos sin familia explícita.
- gsap.min.js: distribución oficial GSAP 3.15.0 de jsDelivr, conservada localmente para renders sin red.
- notification-cascade: bloque del registro oficial HyperFrames, adaptado a la marca, duración y narrativa. No se utiliza su fondo ni su logo de demostración.
- Audio: pendiente de selección del catálogo tras el inicio de sesión.
''')
print('Created 6 scenes, root composition, spec, storyboard and asset ledger.')
