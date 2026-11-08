<script setup>
import { computed, ref } from "vue";
import { motion, useMotionTemplate, useReducedMotion, useSpring, useTransform } from "motion-v";
import AnimatedNumber from "./AnimatedNumber.vue";

const props = defineProps({
  titular: { type: String, default: "TITULAR" },
  conta: { type: [String, Number], default: "0000" },
  saldo: { type: String, default: null },
  valor: { type: Number, default: null },
});

const reduzido = useReducedMotion();
const virado = ref(false);

const MOLA = { stiffness: 220, damping: 22, mass: 0.6 };
const inclinacaoX = useSpring(0, MOLA);
const inclinacaoY = useSpring(0, MOLA);
const giro = useSpring(0, { stiffness: 120, damping: 18 });
const brilhoX = useSpring(50, MOLA);
const brilhoY = useSpring(50, MOLA);
const brilhoOpacidade = useSpring(0, { stiffness: 180, damping: 28 });
const faixaInicio = useTransform(() => brilhoX.get() - 24);
const faixaFim = useTransform(() => brilhoX.get() + 24);

const rotateY = useTransform(() => inclinacaoY.get() + giro.get());
const brilho = useMotionTemplate`radial-gradient(circle at ${brilhoX}% ${brilhoY}%, oklch(0.85 0.1 352 / 0.2), transparent 26%), linear-gradient(115deg, transparent ${faixaInicio}%, oklch(1 0 0 / 0.1) ${brilhoX}%, transparent ${faixaFim}%)`;

const finais = computed(() => String(props.conta).padStart(4, "0").slice(-4));
const mostraSaldo = computed(() => props.valor !== null || props.saldo !== null);

function aoMover(evento) {
  if (reduzido.value) return;
  const caixa = evento.currentTarget.getBoundingClientRect();
  const px = (evento.clientX - caixa.left) / caixa.width;
  const py = (evento.clientY - caixa.top) / caixa.height;
  inclinacaoX.set((0.5 - py) * 16);
  inclinacaoY.set((px - 0.5) * 20);
  brilhoX.set(px * 100);
  brilhoY.set(py * 100);
  brilhoOpacidade.set(1);
}

function aoSair() {
  inclinacaoX.set(0);
  inclinacaoY.set(0);
  brilhoX.set(50);
  brilhoY.set(50);
  brilhoOpacidade.set(0);
}

function virar() {
  virado.value = !virado.value;
  const alvo = virado.value ? 180 : 0;
  if (reduzido.value) giro.jump(alvo);
  else giro.set(alvo);
}
</script>

<template>
  <div
    class="cena"
    role="button"
    tabindex="0"
    :aria-pressed="virado"
    :aria-label="`Cartão ICEIBank Metal final ${finais}, titular ${titular}${saldo ? `, saldo ${saldo}` : ''}. Ativar para virar o cartão.`"
    @pointermove="aoMover"
    @pointerleave="aoSair"
    @click="virar"
    @keydown.enter.prevent="virar"
    @keydown.space.prevent="virar"
  >
    <motion.div class="palco" :style="{ rotateX: inclinacaoX, rotateY }" aria-hidden="true">
      <div class="face frente">
        <motion.div class="brilho" :style="{ background: brilho, opacity: brilhoOpacidade }" />
        <div class="topo">
          <span class="marca">ICEIBank</span>
          <span class="tipo">Metal</span>
        </div>
        <div class="linha-chip">
          <span class="chip-ouro" />
          <span class="numero">5301 &middot;&middot;&middot;&middot; {{ finais }}</span>
        </div>
        <div class="base">
          <div>
            <p class="rotulo">{{ mostraSaldo ? "Saldo" : "Titular" }}</p>
            <p class="valor">
              <AnimatedNumber v-if="valor !== null" :valor="valor" />
              <template v-else>{{ saldo ?? titular }}</template>
            </p>
          </div>
          <span class="bandeira">VISA</span>
        </div>
      </div>
      <div class="face verso">
        <div class="tarja" />
        <p class="rotulo">Titular</p>
        <p class="valor pequeno">{{ titular }}</p>
        <p class="rotulo">Conta</p>
        <p class="valor pequeno mono">{{ conta }}</p>
      </div>
    </motion.div>
  </div>
</template>

<style scoped>
.cena {
  container-type: inline-size;
  perspective: 1100px;
  width: 100%;
  min-width: 0;
  max-width: 440px;
  margin: 0 auto;
  cursor: pointer;
}

.palco {
  position: relative;
  aspect-ratio: 1.586 / 1;
  transform-style: preserve-3d;
}

.face {
  position: absolute;
  inset: 0;
  overflow: hidden;
  padding: clamp(16px, 6.4cqi, 28px);
  border-radius: clamp(18px, 6.4cqi, 28px);
  background:
    linear-gradient(135deg, var(--metal-brilho) 0%, oklch(1 0 0 / 2%) 42%, transparent 55%),
    linear-gradient(160deg, var(--metal-inicio) 0%, var(--metal-fim) var(--metal-fim-parada));
  box-shadow:
    0 0 0 1px var(--metal-borda),
    inset 0 1px 0 oklch(1 0 0 / 16%),
    0 40px 80px -30px var(--metal-sombra),
    0 24px 70px -34px color-mix(in oklch, var(--primary) 70%, transparent);
  backface-visibility: hidden;
  color: var(--metal-texto);
}

.verso {
  transform: rotateY(180deg);
}

.brilho {
  position: absolute;
  inset: 0;
  mix-blend-mode: screen;
  pointer-events: none;
}

.topo,
.base,
.linha-chip {
  position: relative;
}

.topo {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.marca {
  font-family: var(--font-display);
  font-size: 14px;
  font-weight: 600;
  letter-spacing: 0.02em;
  opacity: 0.9;
}

.tipo {
  font-size: 12px;
  font-weight: 500;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--metal-rotulo);
}

.linha-chip {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: clamp(14px, 8cqi, 36px);
}

.chip-ouro {
  flex: none;
  width: clamp(26px, 8cqi, 36px);
  height: clamp(26px, 8cqi, 36px);
  border-radius: 6px;
  background: var(--metal-chip);
  box-shadow: 0 0 0 1px oklch(1 0 0 / 20%), 0 0 20px -2px var(--metal-chip-brilho);
}

.numero {
  font-size: clamp(11px, 3.2cqi, 14px);
  letter-spacing: 0.28em;
  white-space: nowrap;
  color: var(--metal-texto-suave);
}

.base {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-top: clamp(12px, 6.4cqi, 28px);
}

.rotulo {
  font-size: 10px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--metal-rotulo);
}

.valor {
  font-family: var(--font-display);
  font-size: clamp(16px, 5cqi, 22px);
  font-weight: 500;
}

.valor.pequeno {
  font-size: 16px;
  margin-bottom: 14px;
}

.bandeira {
  font-size: 14px;
  font-weight: 500;
  color: var(--metal-texto-suave);
}

.tarja {
  height: clamp(28px, 9cqi, 40px);
  margin: calc(-1 * clamp(16px, 6.4cqi, 28px)) calc(-1 * clamp(16px, 6.4cqi, 28px)) 16px;
  background: var(--metal-tarja);
}
</style>
