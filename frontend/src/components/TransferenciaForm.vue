<script setup>
import { ref } from "vue";
import { useSessao } from "../composables/useSessao";
import { useContaApi } from "../composables/useContaApi";
import { useMensagem } from "../composables/useMensagem";

const { estado } = useSessao();
const { chamarAutenticado } = useContaApi();
const { mostrar } = useMensagem();
const destino = ref("");
const valor = ref("");

async function transferir() {
  try {
    const resultado = await chamarAutenticado("/transferencias", {
      metodo: "POST",
      corpo: {
        idOrigem: estado.sessao.contaId,
        idDestino: Number(destino.value),
        valor: Number(valor.value),
      },
    });
    mostrar(resultado.mensagem, "sucesso");
    destino.value = "";
    valor.value = "";
  } catch (erro) {
    mostrar(erro.message, "erro");
  }
}
</script>

<template>
  <form class="cartao" @submit.prevent="transferir">
    <h3>Transferência</h3>
    <label>Conta de destino: <input type="number" v-model="destino" required /></label>
    <label>Valor: <input type="number" step="0.01" v-model="valor" required /></label>
    <button type="submit">Transferir</button>
  </form>
</template>
