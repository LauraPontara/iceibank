<script setup>
defineProps({
  titulo: { type: String, required: true },
  subtitulo: { type: String, default: "" },
});
</script>

<template>
  <main class="auth container">
    <section class="surface cartao rise-in">
      <h1>{{ titulo }}</h1>
      <p v-if="subtitulo" class="muted subtitulo">{{ subtitulo }}</p>
      <slot />
    </section>
    <p class="rodape muted"><slot name="rodape" /></p>
  </main>
</template>

<style scoped>
.auth {
  display: flex;
  flex-direction: column;
  align-items: center;
  max-width: 480px;
  padding-top: 72px;
  padding-bottom: 72px;
}

.cartao {
  width: 100%;
  box-shadow: 0 40px 80px -30px rgb(0 0 0 / 35%);
}

h1 {
  font-size: 26px;
}

.subtitulo {
  margin-top: 4px;
  font-size: 14px;
}

.cartao :deep(form) {
  margin-top: 24px;
}

.cartao :deep(.btn-primary) {
  margin-top: 24px;
}

.rodape {
  margin-top: 16px;
  font-size: 12px;
  text-align: center;
}

.rodape :deep(a) {
  color: var(--primary);
  font-weight: 500;
}

.rodape :deep(a:hover) {
  text-decoration: underline;
}
</style>
