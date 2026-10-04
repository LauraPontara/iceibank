<script setup>
import { RouterLink } from "vue-router";
</script>

<template>
  <RouterLink to="/" class="logo">
    <span class="marca"><span>i</span></span>
    <span class="nome">ICEIBank</span>
  </RouterLink>
</template>

<style scoped>
.logo {
  display: flex;
  align-items: center;
  gap: 10px;
}

.marca {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background: var(--primary);
  color: var(--primary-foreground);
  box-shadow: 0 0 24px -4px var(--primary);
  font-family: var(--font-display);
  font-size: 14px;
  font-weight: 600;
  line-height: 1;
}

.nome {
  font-family: var(--font-display);
  font-size: 18px;
  font-weight: 600;
  letter-spacing: -0.02em;
}
</style>
