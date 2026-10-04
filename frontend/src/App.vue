<script setup>
import { RouterView } from "vue-router";
import { useMensagem } from "./composables/useMensagem";
import AmbientBackground from "./components/ui/AmbientBackground.vue";
import SiteHeader from "./components/ui/SiteHeader.vue";

const { estado: mensagem, limpar } = useMensagem();
</script>

<template>
  <AmbientBackground />
  <SiteHeader />
  <div v-if="mensagem.texto" class="aviso container">
    <div :class="['alert', mensagem.tipo]" role="status" @click="limpar">{{ mensagem.texto }}</div>
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
}

.aviso .alert {
  cursor: pointer;
  backdrop-filter: blur(16px);
  background-color: var(--background);
}
</style>
