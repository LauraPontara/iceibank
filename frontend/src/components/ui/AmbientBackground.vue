<script setup>
import { onBeforeUnmount, onMounted, ref } from "vue";

const canvas = ref(null);
const comWebgl = ref(true);

const ESCALA = 0.5;
const VELOCIDADE = 1;

const VERTEX = `
attribute vec2 aPos;
void main() { gl_Position = vec4(aPos, 0.0, 1.0); }
`;

const FRAGMENT = `
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 uRes;
uniform float uTime;
uniform float uClaro;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float ruido(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    v += a * ruido(p);
    p = p * 2.02 + vec2(7.1, 3.7);
    a *= 0.5;
  }
  return v;
}

void main() {
  vec2 uv = gl_FragCoord.xy / uRes;
  float proporcao = uRes.x / uRes.y;
  vec2 p = vec2(uv.x * proporcao, uv.y) * 0.85;
  float t = uTime * 0.04;

  vec2 q = vec2(fbm(p + vec2(0.0, t)), fbm(p + vec2(5.2, 1.3) - t));
  vec2 r = vec2(fbm(p + 1.6 * q + vec2(1.7, 9.2) + t * 1.3), fbm(p + 1.6 * q + vec2(8.3, 2.8) - t));
  float f = fbm(p + 1.6 * r);

  float onda = sin(uv.x * 3.2 + f * 6.0 + uTime * 0.22) * 0.5 + 0.5;
  float onda2 = sin(uv.y * 4.0 - f * 5.0 - uTime * 0.17 + uv.x * 1.5) * 0.5 + 0.5;
  float brilho = pow(clamp(onda * onda2 * f * 1.8, 0.0, 1.0), 1.7);

  vec3 fundoEscuro = vec3(0.055, 0.035, 0.048);
  vec3 magenta = vec3(0.42, 0.045, 0.27);
  vec3 rosa = vec3(1.0, 0.18, 0.62);
  vec3 escuro = mix(fundoEscuro, magenta, smoothstep(0.2, 0.8, f));
  escuro += rosa * brilho * 0.3;

  vec3 fundoClaro = vec3(0.985, 0.97, 0.978);
  vec3 pastel = vec3(1.0, 0.78, 0.9);
  vec3 claro = mix(fundoClaro, pastel, smoothstep(0.3, 0.9, f) * 0.7);
  claro = mix(claro, vec3(1.0, 0.6, 0.82), brilho * 0.45);

  vec3 cor = mix(escuro, claro, uClaro);

  float vinheta = smoothstep(1.25, 0.25, length((uv - vec2(0.5, 0.45)) * vec2(1.0, 1.15)));
  cor = mix(mix(fundoEscuro, fundoClaro, uClaro), cor, 0.55 + 0.45 * vinheta);

  gl_FragColor = vec4(cor, 1.0);
}
`;

let gl = null;
let programa = null;
let uniformes = null;
let quadro = 0;
let inicio = 0;
let reduzido = false;
let observadorTema = null;
let claro = 0;

function compilar(tipo, fonte) {
  const sombreador = gl.createShader(tipo);
  gl.shaderSource(sombreador, fonte);
  gl.compileShader(sombreador);
  if (!gl.getShaderParameter(sombreador, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(sombreador) || "falha ao compilar shader");
  }
  return sombreador;
}

function iniciarWebgl(el) {
  gl = el.getContext("webgl", { antialias: false, alpha: false, powerPreference: "low-power" });
  if (!gl) throw new Error("WebGL indisponivel");

  programa = gl.createProgram();
  gl.attachShader(programa, compilar(gl.VERTEX_SHADER, VERTEX));
  gl.attachShader(programa, compilar(gl.FRAGMENT_SHADER, FRAGMENT));
  gl.linkProgram(programa);
  if (!gl.getProgramParameter(programa, gl.LINK_STATUS)) throw new Error("falha ao ligar programa");
  gl.useProgram(programa);

  const buffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 3, -1, -1, 3]), gl.STATIC_DRAW);
  const posicao = gl.getAttribLocation(programa, "aPos");
  gl.enableVertexAttribArray(posicao);
  gl.vertexAttribPointer(posicao, 2, gl.FLOAT, false, 0, 0);

  uniformes = {
    res: gl.getUniformLocation(programa, "uRes"),
    tempo: gl.getUniformLocation(programa, "uTime"),
    claro: gl.getUniformLocation(programa, "uClaro"),
  };
}

function redimensionar() {
  const el = canvas.value;
  if (!el || !gl) return;
  const largura = Math.max(2, Math.floor(el.clientWidth * ESCALA));
  const altura = Math.max(2, Math.floor(el.clientHeight * ESCALA));
  if (el.width !== largura || el.height !== altura) {
    el.width = largura;
    el.height = altura;
    gl.viewport(0, 0, largura, altura);
  }
}

function desenhar(agora) {
  redimensionar();
  const segundos = reduzido ? 18 : ((agora - inicio) / 1000) * VELOCIDADE + 18;
  gl.uniform2f(uniformes.res, canvas.value.width, canvas.value.height);
  gl.uniform1f(uniformes.tempo, segundos);
  gl.uniform1f(uniformes.claro, claro);
  gl.drawArrays(gl.TRIANGLES, 0, 3);
}

function laco(agora) {
  desenhar(agora);
  quadro = requestAnimationFrame(laco);
}

function atualizarTema() {
  claro = document.documentElement.dataset.theme === "light" ? 1 : 0;
  if (reduzido && gl) desenhar(performance.now());
}

function aoMudarVisibilidade() {
  if (reduzido) return;
  if (document.hidden) cancelAnimationFrame(quadro);
  else quadro = requestAnimationFrame(laco);
}

onMounted(() => {
  reduzido = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  try {
    iniciarWebgl(canvas.value);
  } catch {
    comWebgl.value = false;
    return;
  }
  inicio = performance.now();
  atualizarTema();
  observadorTema = new MutationObserver(atualizarTema);
  observadorTema.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
  document.addEventListener("visibilitychange", aoMudarVisibilidade);
  window.addEventListener("resize", redimensionar);

  if (reduzido) desenhar(performance.now());
  else quadro = requestAnimationFrame(laco);
});

onBeforeUnmount(() => {
  cancelAnimationFrame(quadro);
  observadorTema?.disconnect();
  document.removeEventListener("visibilitychange", aoMudarVisibilidade);
  window.removeEventListener("resize", redimensionar);
  gl?.getExtension("WEBGL_lose_context")?.loseContext();
});
</script>

<template>
  <div class="ambiente" aria-hidden="true">
    <canvas v-show="comWebgl" ref="canvas" class="onda" />
    <template v-if="!comWebgl">
      <span class="orbe a" />
      <span class="orbe b" />
      <span class="orbe c" />
    </template>
    <span class="pontos" />
  </div>
</template>

<style scoped>
.ambiente {
  position: fixed;
  inset: 0;
  z-index: -1;
  overflow: hidden;
  pointer-events: none;
}

.onda {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.orbe {
  position: absolute;
  border-radius: 50%;
  filter: blur(90px);
  opacity: 0.45;
  background: oklch(0.65 0.25 352);
  animation: deriva 26s ease-in-out infinite alternate;
}

.a {
  top: -12%;
  left: -8%;
  width: 46vw;
  height: 46vw;
}

.b {
  top: 18%;
  right: -14%;
  width: 38vw;
  height: 38vw;
  opacity: 0.25;
  animation-duration: 32s;
  animation-direction: alternate-reverse;
}

.c {
  bottom: -20%;
  left: 38%;
  width: 40vw;
  height: 40vw;
  opacity: 0.18;
  background: oklch(0.75 0.12 352);
  animation-duration: 38s;
}

.pontos {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(color-mix(in oklch, var(--foreground) 14%, transparent) 1px, transparent 1px);
  background-size: 28px 28px;
  mask-image: radial-gradient(70% 60% at 50% 30%, black, transparent 75%);
}

:root:not([data-theme="dark"]) .orbe {
  opacity: 0.18;
}

@keyframes deriva {
  to {
    transform: translate3d(6vw, 5vh, 0) scale(1.15);
  }
}

@media (prefers-reduced-motion: reduce) {
  .orbe {
    animation: none;
  }
}
</style>
