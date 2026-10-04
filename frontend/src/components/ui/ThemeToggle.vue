<script setup>
import { Moon, Sun } from "lucide-vue-next";
import { useTema } from "../../composables/useTema";

const { tema, alternar } = useTema();
</script>

<template>
  <button class="toggle" type="button" aria-label="Alternar tema" @click="alternar">
    <Sun v-if="tema === 'dark'" :size="16" />
    <Moon v-else :size="16" />
  </button>
</template>

<style scoped>
.toggle {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border: 1px solid var(--border);
  border-radius: 50%;
  background: transparent;
  color: var(--muted-foreground);
  cursor: pointer;
  transition: color 0.2s ease, border-color 0.2s ease;
}

.toggle:hover {
  color: var(--foreground);
  border-color: color-mix(in oklch, var(--primary) 50%, transparent);
}
</style>
