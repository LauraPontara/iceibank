<script setup>
import { RouterLink, useRouter } from "vue-router";
import { LogOut } from "lucide-vue-next";
import { useSessao } from "../../composables/useSessao";
import LogoMark from "./LogoMark.vue";
import ThemeToggle from "./ThemeToggle.vue";

const { estado, encerrar } = useSessao();
const router = useRouter();

async function sair() {
  await router.push("/");
  encerrar();
}
</script>

<template>
  <header class="cabecalho">
    <nav class="container barra">
      <LogoMark />
      <div class="links">
        <a href="/#recursos">Conta</a>
        <a href="/#recursos">Cartões</a>
        <a href="/#numeros">Arquitetura</a>
      </div>
      <div class="acoes">
        <ThemeToggle />
        <template v-if="estado.sessao">
          <RouterLink to="/painel" class="entrar">Meu painel</RouterLink>
          <button type="button" class="btn-ghost sair" @click="sair"><LogOut :size="14" /> Sair</button>
        </template>
        <template v-else>
          <RouterLink to="/entrar" class="entrar">Entrar</RouterLink>
          <RouterLink to="/abrir-conta" class="btn-primary pequeno">Abrir conta</RouterLink>
        </template>
      </div>
    </nav>
  </header>
</template>

<style scoped>
.cabecalho {
  position: sticky;
  top: 0;
  z-index: 30;
  border-bottom: 1px solid var(--border);
  background: color-mix(in oklch, var(--background) 70%, transparent);
  backdrop-filter: blur(20px);
}

.barra {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 16px;
  padding-bottom: 16px;
}

.links {
  display: flex;
  gap: 32px;
  font-size: 14px;
  color: var(--muted-foreground);
}

.links a:hover {
  color: var(--primary);
}

.acoes {
  display: flex;
  align-items: center;
  gap: 12px;
}

.entrar {
  font-size: 14px;
  font-weight: 500;
  color: var(--muted-foreground);
  transition: color 0.2s ease;
}

.entrar:hover {
  color: var(--foreground);
}

.pequeno {
  padding: 8px 16px;
}

.sair {
  padding: 8px 14px;
  font-size: 13px;
}

@media (max-width: 767px) {
  .links {
    display: none;
  }
}
</style>
