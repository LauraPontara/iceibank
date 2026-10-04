<template>
  <div class="ambiente" aria-hidden="true">
    <span class="orbe a" />
    <span class="orbe b" />
    <span class="orbe c" />
    <span class="pontos" />
  </div>
</template>

<style scoped>
.ambiente {
  position: fixed;
  inset: 0;
  z-index: -1;
  overflow: hidden;
  pointer-events: none;
}

.orbe {
  position: absolute;
  border-radius: 50%;
  filter: blur(90px);
  opacity: 0.45;
  background: oklch(0.65 0.25 352);
  animation: deriva 26s ease-in-out infinite alternate;
}

.a {
  top: -12%;
  left: -8%;
  width: 46vw;
  height: 46vw;
}

.b {
  top: 18%;
  right: -14%;
  width: 38vw;
  height: 38vw;
  opacity: 0.25;
  animation-duration: 32s;
  animation-direction: alternate-reverse;
}

.c {
  bottom: -20%;
  left: 38%;
  width: 40vw;
  height: 40vw;
  opacity: 0.18;
  background: oklch(0.75 0.12 352);
  animation-duration: 38s;
}

.pontos {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(color-mix(in oklch, var(--foreground) 14%, transparent) 1px, transparent 1px);
  background-size: 28px 28px;
  mask-image: radial-gradient(70% 60% at 50% 30%, black, transparent 75%);
}

:root:not([data-theme="dark"]) .orbe {
  opacity: 0.18;
}

@keyframes deriva {
  to {
    transform: translate3d(6vw, 5vh, 0) scale(1.15);
  }
}

@media (prefers-reduced-motion: reduce) {
  .orbe {
    animation: none;
  }
}
</style>
