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

async function depositar() {
  try {
    const conta = await chamarAutenticado(`/contas/${estado.sessao.contaId}/depositar`, {
      metodo: "POST",
      corpo: { valor: Number(valor.value) },
    });
    emit("saldoAtualizado", conta.saldo);
    mostrar(`Depósito de ${valor.value} realizado.`, "sucesso");
    valor.value = "";
  } catch (erro) {
    mostrar(erro.message, "erro");
  }
}
</script>

<template>
  <form class="cartao" @submit.prevent="depositar">
    <h3>Depósito</h3>
    <label>Valor: <input type="number" step="0.01" v-model="valor" required /></label>
    <button type="submit">Depositar</button>
  </form>
</template>
