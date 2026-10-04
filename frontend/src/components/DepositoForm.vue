<script setup>
import { ref } from "vue";
import { useSessao } from "../composables/useSessao";
import { useContaApi } from "../composables/useContaApi";
import { useMensagem } from "../composables/useMensagem";
import { formatarMoeda } from "../services/formato";

const emit = defineEmits(["concluido"]);
const { estado } = useSessao();
const { chamarAutenticado } = useContaApi();
const { mostrar } = useMensagem();
const valor = ref("");
const carregando = ref(false);

async function depositar() {
  carregando.value = true;
  try {
    const montante = Number(valor.value);
    await chamarAutenticado(`/contas/${estado.sessao.contaId}/depositar`, {
      metodo: "POST",
      corpo: { valor: montante },
    });
    emit("concluido", { tipo: "deposito", valor: montante });
    mostrar(`Depósito de ${formatarMoeda(montante)} realizado.`, "sucesso");
    valor.value = "";
  } catch (erro) {
    if (!erro.tratado) mostrar(erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <form @submit.prevent="depositar">
    <label class="field">
      <span>Valor (R$)</span>
      <input v-model="valor" class="valor" type="number" min="0.01" step="0.01" placeholder="0,00" required />
    </label>
    <button type="submit" class="btn-primary btn-block" :disabled="carregando">Depositar</button>
  </form>
</template>
