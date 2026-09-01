<script setup>
import { ref } from "vue";
import { useSessao } from "../composables/useSessao";
import { useContaApi } from "../composables/useContaApi";
import { useMensagem } from "../composables/useMensagem";

const emit = defineEmits(["saldoAtualizado"]);
const { estado } = useSessao();
const { chamarAutenticado } = useContaApi();
const { mostrar } = useMensagem();
const valor = ref("");

async function sacar() {
  try {
    const conta = await chamarAutenticado(`/contas/${estado.sessao.contaId}/sacar`, {
      metodo: "POST",
      corpo: { valor: Number(valor.value) },
    });
    emit("saldoAtualizado", conta.saldo);
    mostrar(`Saque de ${valor.value} realizado.`, "sucesso");
    valor.value = "";
  } catch (erro) {
    mostrar(erro.message, "erro");
  }
}
</script>

<template>
  <form class="cartao" @submit.prevent="sacar">
    <h3>Saque</h3>
    <label>Valor: <input type="number" step="0.01" v-model="valor" required /></label>
    <button type="submit">Sacar</button>
  </form>
</template>
