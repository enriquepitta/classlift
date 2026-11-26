"""Build the editable splash study from ClassLift's real logo and fonts.

Only rerun before editing index.html in Studio: this replaces that composition.
"""
from pathlib import Path
import shutil
import xml.etree.ElementTree as ET

project = Path(__file__).resolve().parent
repo = project.parent.parent
assets = project / 'assets'
assets.mkdir(exist_ok=True)
for weight in ('Regular', 'Bold'):
    shutil.copy(repo / f'assets/fonts/Poppins/Poppins-{weight}.ttf', assets)
shutil.copy(project.parent / 'classlift-promo/assets/vendor/gsap.min.js', assets)
ET.register_namespace('', 'http://www.w3.org/2000/svg')
svg = ET.parse(repo / 'assets/icons/classlift_mark.svg').getroot()
paths = svg.findall('{http://www.w3.org/2000/svg}path')
paths[1].set('id', 'left-page')
paths[2].set('id', 'right-page')
paths[3].set('id', 'arrow')
paths[4].set('id', 'book-line')
logo = ET.tostring(svg, encoding='unicode')
html = '''<!doctype html>
<html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=1170,height=2532">
<title>ClassLift · Splash animado</title>
<script src="assets/gsap.min.js"></script>
<style>
@font-face{font-family:Poppins;src:url('assets/Poppins-Regular.ttf');font-weight:400}
@font-face{font-family:Poppins;src:url('assets/Poppins-Bold.ttf');font-weight:700}
*{box-sizing:border-box;margin:0}html,body{width:1170px;height:2532px;overflow:hidden}
#root,.clip{position:absolute;inset:0;width:1170px;height:2532px}
.app{position:absolute;width:390px;height:844px;transform:scale(3);transform-origin:0 0;font-family:Poppins,sans-serif;background:linear-gradient(135deg,#CBDEFB 0%,#F4F8FF 36%,#F6F9FF 62%,#D2E4FF 100%)}
.background{position:absolute;inset:0;width:390px;height:844px}
.content{position:absolute;left:28px;right:28px;top:47px;bottom:87px;display:flex;align-items:center;justify-content:center;flex-direction:column}
.mark{width:237.6px;height:237.6px;position:relative;display:grid;place-items:center;margin-bottom:24px}
.halo{position:absolute;inset:0;border:1px solid #ffffff77;border-radius:50%;background:radial-gradient(circle,#ffffffbb,#ffffff22)}
.inner-halo{position:absolute;width:194.4px;height:194.4px;border:1px solid #ffffff99;border-radius:50%}
.logo{width:144px;height:144px;position:relative;border-radius:39px;box-shadow:0 20px 40px #5486d033,0 4px 10px #5d93e412}
.logo svg{width:100%;height:100%;display:block}
.wordmark{font-size:50px;line-height:1.15;font-weight:700;letter-spacing:-2.5px;text-align:center;white-space:nowrap}
.class{color:#0A173E}.lift{color:#3479F6}
.tagline{margin-top:14px;text-align:center;color:#617392;font-size:15px;line-height:1.5;letter-spacing:.2px}
.dots{position:absolute;bottom:70px;left:0;right:0;display:flex;justify-content:center;gap:8px}
.dot{width:5px;height:5px;border-radius:50%;background:#5F8FD9;opacity:.55}
</style></head><body>
<div id="root" data-composition-id="main" data-start="0" data-duration="3" data-width="1170" data-height="2532">
<div id="splash" class="clip" data-start="0" data-duration="3" data-track-index="0">
<div class="app">
<svg class="background" viewBox="0 0 400 870" preserveAspectRatio="none" aria-hidden="true" data-layout-ignore>
<defs><linearGradient id="upper" x1="1" y1="0" x2="0" y2="1"><stop stop-color="#5E94E7" stop-opacity=".6"/><stop offset="1" stop-color="#5E94E7" stop-opacity=".067"/></linearGradient><linearGradient id="lower"><stop stop-color="#9EC3F7" stop-opacity=".53"/><stop offset="1" stop-color="#87B0EE" stop-opacity=".67"/></linearGradient></defs>
<path d="M232 0C232 142 315 138 400 242V0Z" fill="url(#upper)"/>
<path d="M0 665C99 695 68 759 163 789C216 808 252 837 265 870H0Z" fill="url(#lower)"/>
<g fill="none" stroke="#fff" opacity=".6"><path d="M-20 162C83 116 159 172 185 222"/><path d="M215 886C260 775 330 748 419 746"/><path d="M239 886C284 775 354 748 419 770"/></g></svg>
<div class="content"><div class="mark"><div class="halo"></div><div class="inner-halo"></div><div class="logo">LOGO_SVG</div></div>
<div class="copy"><h1 class="wordmark"><span class="class">Class</span><span class="lift">Lift</span></h1><p class="tagline">Tu vida universitaria,<br>en orden.</p></div></div>
<div class="dots" aria-label="Cargando ClassLift"><i class="dot"></i><i class="dot"></i><i class="dot"></i></div>
</div></div></div>
<script>
// Timing mirrors Flutter: 1150 ms entrance + 350 ms hold. The preview
// keeps the final frame longer so the design can be inspected.
const tl=gsap.timeline({paused:true});
tl.fromTo('.mark',{y:16,scale:.88},{y:0,scale:1,duration:.552,ease:'power2.out'},0);
tl.fromTo('.halo',{scale:.8},{scale:1,duration:.897,ease:'power2.out'},0);
tl.fromTo('#left-page,#right-page',{scaleX:.22,svgOrigin:'64 0'},{scaleX:1,duration:.5635,ease:'power2.out'},.092);
tl.fromTo('#book-line',{opacity:0},{opacity:.55,duration:.5635,ease:'power2.out'},.092);
// Adapted from registry svg-stroke-trace: measured path, seekable dash offset.
const arrow=document.querySelector('#arrow'),head=arrow.cloneNode();
arrow.setAttribute('d','M64 66V28');head.id='arrow-head';head.setAttribute('d','M51 41L64 28L77 41');arrow.after(head);
const parts=[arrow,head],lengths=parts.map(p=>p.getTotalLength());
const total=lengths.reduce((a,b)=>a+b,0),trace={progress:0};
parts.forEach((p,i)=>{p.style.strokeDasharray=lengths[i]+' '+lengths[i];p.style.strokeDashoffset=lengths[i];p.style.opacity=0;});
function drawArrow(){let remaining=total*trace.progress;parts.forEach((p,i)=>{const shown=Math.max(0,Math.min(lengths[i],remaining));p.style.strokeDashoffset=lengths[i]-shown;p.style.opacity=shown>0?1:0;remaining-=lengths[i];});}
tl.fromTo(trace,{progress:0},{progress:1,duration:.552,ease:'power2.out',onUpdate:drawArrow},.345);
tl.fromTo('.copy',{y:10},{y:0,duration:.437,ease:'power2.out'},.46);
tl.fromTo('.class',{color:'#7185A9'},{color:'#0A173E',duration:.437,ease:'power2.out'},.46);
tl.fromTo('.lift',{color:'#7185A9'},{color:'#3479F6',duration:.437,ease:'power2.out'},.552);
document.querySelectorAll('.dot').forEach((dot,i)=>tl.fromTo(dot,{opacity:.35},{opacity:1,duration:.22,repeat:1,yoyo:true,ease:'sine.inOut'},i*.12));
window.__timelines=window.__timelines||{};window.__timelines.main=tl;tl.seek(0);
</script></body></html>'''
html = html.replace('LOGO_SVG', logo)
# One editable scene, mounted by the root timeline.
style = html[html.index('<style>'):html.index('</style>') + 8]
body = html[html.index('<div id="splash"'):html.index('<script>')]
body = body.rsplit('</div>', 1)[0]
script = html[html.index('<script>'):html.index('</script></body>') + 9]
script = script.replace('window.__timelines.main=tl', "window.__timelines['splash-scene']=tl")
scene = '<!doctype html><html lang="es"><body><template><div id="root" data-composition-id="splash-scene" data-duration="3">' + style + body + '<script src="assets/gsap.min.js"></script>' + script + '</div></template></body></html>'
(project / 'compositions/splash-scene.html').write_text(scene)
(project / 'index.html').write_text('''<!doctype html><html lang="es"><head><meta charset="utf-8"><title>ClassLift · Splash</title><script src="assets/gsap.min.js"></script><style>html,body{margin:0;width:1170px;height:2532px;overflow:hidden}#root,.clip{position:absolute;inset:0;width:1170px;height:2532px}</style></head><body><div id="root" data-composition-id="main" data-start="0" data-duration="3" data-width="1170" data-height="2532"><div id="splash-scene" class="clip" data-composition-id="splash-scene" data-composition-src="compositions/splash-scene.html" data-start="0" data-duration="3" data-track-index="0"></div></div><script>window.__timelines=window.__timelines||{};window.__timelines.main=gsap.timeline({paused:true});</script></body></html>''')
