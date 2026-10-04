<script setup>
import { RouterView } from "vue-router";
import { X } from "lucide-vue-next";
import { useMensagem } from "./composables/useMensagem";
import AmbientBackground from "./components/ui/AmbientBackground.vue";
import SiteHeader from "./components/ui/SiteHeader.vue";

const { estado: mensagem, limpar } = useMensagem();
</script>

<template>
  <AmbientBackground />
  <SiteHeader />
  <div class="aviso container" aria-live="polite">
    <div v-if="mensagem.texto" :class="['alert', mensagem.tipo]" :role="mensagem.tipo === 'erro' ? 'alert' : 'status'">
      <span>{{ mensagem.texto }}</span>
      <button type="button" class="fechar" aria-label="Fechar aviso" @click="limpar"><X :size="14" /></button>
    </div>
  </div>
  <RouterView />
</template>

<style scoped>
.aviso {
  position: fixed;
  top: 76px;
  left: 50%;
  z-index: 40;
  max-width: 560px;
  transform: translateX(-50%);
  pointer-events: none;
}

.aviso .alert {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  pointer-events: auto;
  backdrop-filter: blur(16px);
  background-image: linear-gradient(var(--background), var(--background));
  box-shadow: inset 0 0 0 100vmax color-mix(in oklch, currentColor 10%, transparent);
}

.fechar {
  display: grid;
  place-items: center;
  padding: 4px;
  border: 0;
  border-radius: 50%;
  background: transparent;
  color: inherit;
  cursor: pointer;
}
</style>
