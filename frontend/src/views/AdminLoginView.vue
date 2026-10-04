<script setup>
import { ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { loginAdmin } from "../services/admin";
import { useSessao } from "../composables/useSessao";
import { useMensagem } from "../composables/useMensagem";
import AuthCard from "../components/ui/AuthCard.vue";

const router = useRouter();
const { iniciar } = useSessao();
const { mostrar, limpar } = useMensagem();

const usuario = ref("");
const senha = ref("");
const carregando = ref(false);

async function entrar() {
  carregando.value = true;
  try {
    const token = await loginAdmin(usuario.value, senha.value);
    iniciar({ papel: "admin", token, usuario: usuario.value });
    limpar();
    router.push("/admin");
  } catch (erro) {
    mostrar(erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <AuthCard titulo="Área do administrador" subtitulo="Acesso restrito para operar contas e testar transferências.">
    <form @submit.prevent="entrar">
      <label class="field">
        <span>Usuário</span>
        <input v-model="usuario" type="text" autocomplete="username" required autofocus />
      </label>
      <label class="field">
        <span>Senha</span>
        <input v-model="senha" type="password" autocomplete="current-password" required />
      </label>
      <button type="submit" class="btn-primary btn-block" :disabled="carregando">
        {{ carregando ? "Entrando..." : "Entrar como administrador" }}
      </button>
    </form>
    <template #rodape>
      É cliente? <RouterLink to="/entrar">Acessar minha conta</RouterLink>
    </template>
  </AuthCard>
</template>
