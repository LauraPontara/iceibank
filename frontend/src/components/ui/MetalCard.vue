<script setup>
import { computed, ref } from "vue";

const props = defineProps({
  titular: { type: String, default: "TITULAR" },
  conta: { type: [String, Number], default: "0000" },
  saldo: { type: String, default: null },
});

const virado = ref(false);
const inclinacao = ref({ x: 0, y: 0, brilhoX: 50, brilhoY: 50 });

const finais = computed(() => String(props.conta).padStart(4, "0").slice(-4));

function aoMover(evento) {
  const caixa = evento.currentTarget.getBoundingClientRect();
  const px = (evento.clientX - caixa.left) / caixa.width;
  const py = (evento.clientY - caixa.top) / caixa.height;
  inclinacao.value = { x: (0.5 - py) * 16, y: (px - 0.5) * 20, brilhoX: px * 100, brilhoY: py * 100 };
}

function aoSair() {
  inclinacao.value = { x: 0, y: 0, brilhoX: 50, brilhoY: 50 };
}

const estiloPalco = computed(() => ({
  "--rx": `${inclinacao.value.x}deg`,
  "--ry": `${inclinacao.value.y + (virado.value ? 180 : 0)}deg`,
  "--gx": `${inclinacao.value.brilhoX}%`,
  "--gy": `${inclinacao.value.brilhoY}%`,
}));
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
    @click="virado = !virado"
    @keydown.enter.prevent="virado = !virado"
    @keydown.space.prevent="virado = !virado"
  >
    <div class="palco" :style="estiloPalco" aria-hidden="true">
      <div class="face frente card-sheen">
        <div class="brilho" />
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
            <p class="rotulo">{{ saldo ? "Saldo" : "Titular" }}</p>
            <p class="valor">{{ saldo ?? titular }}</p>
          </div>
          <span class="bandeira">VISA</span>
        </div>
      </div>
      <div class="face verso card-sheen">
        <div class="tarja" />
        <p class="rotulo">Titular</p>
        <p class="valor pequeno">{{ titular }}</p>
        <p class="rotulo">Conta</p>
        <p class="valor pequeno mono">{{ conta }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.cena {
  perspective: 1100px;
  width: 100%;
  max-width: 440px;
  margin: 0 auto;
  cursor: pointer;
}

.palco {
  position: relative;
  aspect-ratio: 1.586 / 1;
  transform-style: preserve-3d;
  transform: rotateX(var(--rx)) rotateY(var(--ry));
  transition: transform 0.18s ease-out;
}

.cena:not(:hover) .palco {
  transition-duration: 0.7s;
}

.face {
  position: absolute;
  inset: 0;
  overflow: hidden;
  padding: 28px;
  border-radius: 28px;
  box-shadow: 0 0 0 1px oklch(1 0 0 / 10%), 0 40px 80px -30px rgba(0, 0, 0, 0.6);
  backface-visibility: hidden;
  color: white;
}

.verso {
  transform: rotateY(180deg);
}

.brilho {
  position: absolute;
  inset: 0;
  background: radial-gradient(circle at var(--gx) var(--gy), oklch(0.8 0.18 352 / 0.35), transparent 45%);
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
  opacity: 0.4;
}

.linha-chip {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 36px;
}

.chip-ouro {
  width: 36px;
  height: 36px;
  border-radius: 6px;
  background: color-mix(in oklch, var(--primary) 80%, transparent);
  box-shadow: 0 0 0 1px oklch(1 0 0 / 20%), 0 0 20px -2px var(--primary);
}

.numero {
  font-size: 14px;
  letter-spacing: 0.35em;
  opacity: 0.7;
}

.base {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-top: 28px;
}

.rotulo {
  font-size: 10px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  opacity: 0.4;
}

.valor {
  font-family: var(--font-display);
  font-size: 22px;
  font-weight: 500;
}

.valor.pequeno {
  font-size: 16px;
  margin-bottom: 14px;
}

.bandeira {
  font-size: 14px;
  font-weight: 500;
  opacity: 0.6;
}

.tarja {
  height: 40px;
  margin: -28px -28px 24px;
  background: oklch(0.05 0 0);
}

@media (prefers-reduced-motion: reduce) {
  .palco {
    transition: none;
    transform: rotateY(var(--ry));
  }
}
</style>
