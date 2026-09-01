<script setup>
import { ref } from "vue";
import { chamarApi } from "../services/api";
import { useSessao } from "../composables/useSessao";
import { useMensagem } from "../composables/useMensagem";

const props = defineProps({ agenciaUrl: { type: String, required: true } });

const { iniciar } = useSessao();
const { mostrar, limpar } = useMensagem();
const id = ref("");
const senha = ref("");

async function entrar() {
  try {
    const resultado = await chamarApi(props.agenciaUrl, "/auth/login", {
      metodo: "POST",
      corpo: { id: Number(id.value), senha: senha.value },
    });
    iniciar({ token: resultado.accessToken, contaId: Number(id.value), agenciaUrl: props.agenciaUrl });
    limpar();
  } catch (erro) {
    mostrar(erro.message, "erro");
  }
}
</script>

<template>
  <section class="cartao">
    <h2>Login</h2>
    <form @submit.prevent="entrar">
      <label>Id da conta: <input type="number" v-model="id" required /></label>
      <label>Senha: <input type="password" v-model="senha" required /></label>
      <button type="submit">Entrar</button>
    </form>
  </section>
</template>
