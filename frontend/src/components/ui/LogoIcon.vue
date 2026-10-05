<script setup>
import { useId } from "vue";

defineProps({ tamanho: { type: Number, default: 34 } });

const id = useId();
</script>

<template>
  <svg class="logo-icone" :width="tamanho" :height="tamanho" viewBox="0 0 64 64" role="img" aria-label="ICEIBank">
    <defs>
      <linearGradient :id="`${id}-fundo`" x1="8" y1="4" x2="56" y2="60" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#ff5cb8" />
        <stop offset="0.55" stop-color="#f0289f" />
        <stop offset="1" stop-color="#a30d5f" />
      </linearGradient>
      <linearGradient :id="`${id}-brilho`" x1="0" y1="0" x2="0" y2="64" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#ffffff" stop-opacity="0.28" />
        <stop offset="0.5" stop-color="#ffffff" stop-opacity="0" />
      </linearGradient>
      <linearGradient :id="`${id}-gelo`" x1="25" y1="9" x2="39" y2="25" gradientUnits="userSpaceOnUse">
        <stop offset="0" stop-color="#ffffff" />
        <stop offset="1" stop-color="#ffd3ec" />
      </linearGradient>
    </defs>
    <rect width="64" height="64" rx="16" :fill="`url(#${id}-fundo)`" />
    <rect width="64" height="64" rx="16" :fill="`url(#${id}-brilho)`" />
    <rect x="0.75" y="0.75" width="62.5" height="62.5" rx="15.25" fill="none" stroke="#ffffff" stroke-opacity="0.28" stroke-width="1.5" />
    <g transform="translate(0 1.75)">
      <path d="M32 9.5 39 17 32 24.5 25 17Z" :fill="`url(#${id}-gelo)`" />
      <path d="M32 9.5 39 17 32 17Z" fill="#ffffff" fill-opacity="0.55" />
      <rect x="24" y="29" width="16" height="4" rx="2" fill="#ffffff" />
      <rect x="28" y="33" width="8" height="14" fill="#ffffff" />
      <rect x="24" y="47" width="16" height="4" rx="2" fill="#ffffff" />
    </g>
  </svg>
</template>

<style scoped>
.logo-icone {
  flex: none;
  filter: drop-shadow(0 0 12px color-mix(in oklch, var(--primary) 55%, transparent));
}
</style>
