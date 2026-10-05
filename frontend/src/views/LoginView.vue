<script setup>
import { computed, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { chamarApi } from "../services/api";
import { AGENCIAS, agenciaDaConta } from "../services/agencias";
import { useSessao } from "../composables/useSessao";
import { useMensagem } from "../composables/useMensagem";
import AuthCard from "../components/ui/AuthCard.vue";
import PasswordField from "../components/ui/PasswordField.vue";

const router = useRouter();
const { iniciar } = useSessao();
const { mostrar, limpar } = useMensagem();

const id = ref("");
const senha = ref("");
const agenciaEscolhida = ref("auto");
const carregando = ref(false);

const agencia = computed(() =>
  agenciaEscolhida.value === "auto" ? (id.value ? agenciaDaConta(id.value) : null) : AGENCIAS[Number(agenciaEscolhida.value)]
);

async function entrar() {
  carregando.value = true;
  try {
    const resultado = await chamarApi(agencia.value.url, "/auth/login", {
      metodo: "POST",
      corpo: { id: Number(id.value), senha: senha.value },
    });
    iniciar({ token: resultado.accessToken, contaId: Number(id.value), agenciaUrl: agencia.value.url });
    limpar();
    router.push("/painel");
  } catch (erro) {
    mostrar(erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <AuthCard titulo="Acessar minha conta" subtitulo="Entre com o número da conta e a senha.">
    <form @submit.prevent="entrar">
      <label class="field">
        <span>Número da conta</span>
        <input v-model="id" type="number" min="0" step="1" placeholder="Ex.: 1001" required autofocus />
      </label>
      <PasswordField v-model="senha" label="Senha" autocomplete="current-password" />
      <label class="field">
        <span>Agência</span>
        <select v-model="agenciaEscolhida">
          <option value="auto">
            {{ agencia && agenciaEscolhida === "auto" ? `Automática (${agencia.nome})` : "Automática pelo número da conta" }}
          </option>
          <option v-for="a in AGENCIAS" :key="a.id" :value="String(a.id)">{{ a.nome }} ({{ a.url.replace("http://", "") }})</option>
        </select>
      </label>
      <button type="submit" class="btn-primary btn-block" :disabled="carregando">
        {{ carregando ? "Entrando..." : "Entrar" }}
      </button>
    </form>
    <template #rodape>
      Ainda não tem conta? <RouterLink to="/abrir-conta">Abrir conta</RouterLink>
      · <RouterLink to="/admin/entrar">Sou administrador</RouterLink>
    </template>
  </AuthCard>
</template>
