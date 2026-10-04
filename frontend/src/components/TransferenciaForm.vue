<script setup>
import { computed, ref } from "vue";
import { useSessao } from "../composables/useSessao";
import { useContaApi } from "../composables/useContaApi";
import { useMensagem } from "../composables/useMensagem";
import { agenciaDaConta } from "../services/agencias";
import { formatarMoeda } from "../services/formato";

const emit = defineEmits(["concluido"]);
const { estado } = useSessao();
const { chamarAutenticado } = useContaApi();
const { mostrar } = useMensagem();
const destino = ref("");
const valor = ref("");
const carregando = ref(false);

const entreAgencias = computed(
  () => destino.value !== "" && agenciaDaConta(destino.value).url !== estado.sessao.agenciaUrl
);

async function transferir() {
  carregando.value = true;
  try {
    const montante = Number(valor.value);
    const resultado = await chamarAutenticado("/transferencias", {
      metodo: "POST",
      corpo: {
        idOrigem: estado.sessao.contaId,
        idDestino: Number(destino.value),
        valor: montante,
        idempotencyKey: crypto.randomUUID(),
      },
    });
    emit("concluido", { tipo: "transferencia", valor: montante, contraparte: Number(destino.value) });
    mostrar(`${resultado.mensagem} ${formatarMoeda(montante)} para a conta ${destino.value}.`, "sucesso");
    destino.value = "";
    valor.value = "";
  } catch (erro) {
    if (!erro.tratado) mostrar(erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <form @submit.prevent="transferir">
    <label class="field">
      <span>Conta de destino</span>
      <input v-model="destino" type="number" min="0" placeholder="Ex.: 1002" required />
    </label>
    <p v-if="destino" class="rota muted">
      {{ entreAgencias ? "Transferência entre agências" : "Mesma agência" }}
    </p>
    <label class="field">
      <span>Valor (R$)</span>
      <input v-model="valor" class="valor" type="number" min="0.01" step="0.01" placeholder="0,00" required />
    </label>
    <button type="submit" class="btn-primary btn-block" :disabled="carregando">Transferir</button>
  </form>
</template>

<style scoped>
.rota {
  margin-top: 6px;
  font-size: 12px;
}
</style>
