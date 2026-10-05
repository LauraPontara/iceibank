<script setup>
import { ref, watch } from "vue";
import { useMotionValueEvent, useReducedMotion, useSpring } from "motion-v";
import { formatarMoeda } from "../../services/formato";

const props = defineProps({ valor: { type: Number, required: true } });

const reduzido = useReducedMotion();
const mola = useSpring(props.valor, { stiffness: 140, damping: 22, restDelta: 0.005 });
const texto = ref(formatarMoeda(props.valor));

useMotionValueEvent(mola, "change", (atual) => {
  texto.value = formatarMoeda(atual);
});

watch(
  () => props.valor,
  (novo) => {
    if (reduzido.value) mola.jump(novo);
    else mola.set(novo);
  }
);
</script>

<template>
  <span class="numero-animado">{{ texto }}</span>
</template>

<style scoped>
.numero-animado {
  font-variant-numeric: tabular-nums;
}
</style>
