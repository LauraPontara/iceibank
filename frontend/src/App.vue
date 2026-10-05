<script setup>
import { RouterView } from "vue-router";
import { AnimatePresence, MotionConfig, motion } from "motion-v";
import { X } from "lucide-vue-next";
import { useMensagem } from "./composables/useMensagem";
import AmbientBackground from "./components/ui/AmbientBackground.vue";
import SiteHeader from "./components/ui/SiteHeader.vue";

const { estado: mensagem, limpar } = useMensagem();
</script>

<template>
  <MotionConfig reduced-motion="user">
    <AmbientBackground />
    <SiteHeader />
    <div class="aviso container" aria-live="polite">
      <AnimatePresence>
        <motion.div
          v-if="mensagem.texto"
          :key="mensagem.texto"
          :class="['alert', mensagem.tipo]"
          :role="mensagem.tipo === 'erro' ? 'alert' : 'status'"
          :initial="{ opacity: 0, transform: 'translateY(-12px) scale(0.98)' }"
          :animate="{ opacity: 1, transform: 'translateY(0px) scale(1)' }"
          :exit="{ opacity: 0, transform: 'translateY(-8px) scale(0.98)' }"
          :transition="{ type: 'spring', bounce: 0.2, visualDuration: 0.35 }"
        >
          <span>{{ mensagem.texto }}</span>
          <button type="button" class="fechar" aria-label="Fechar aviso" @click="limpar"><X :size="14" /></button>
        </motion.div>
      </AnimatePresence>
    </div>
    <RouterView />
  </MotionConfig>
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
