<script setup>
import { RouterLink } from "vue-router";
import LogoIcon from "./LogoIcon.vue";
</script>

<template>
  <RouterLink to="/" class="logo" aria-label="ICEIBank, página inicial">
    <LogoIcon :tamanho="34" />
    <span class="nome">ICEIBank</span>
  </RouterLink>
</template>

<style scoped>
.logo {
  display: flex;
  align-items: center;
  gap: 10px;
}

.nome {
  font-family: var(--font-display);
  font-size: 19px;
  font-weight: 600;
  letter-spacing: -0.02em;
}
</style>
